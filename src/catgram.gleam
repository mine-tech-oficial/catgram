import birl
import catgram/artifacts/pubsub
import catgram/auth
import catgram/router
import catgram/routes/feed
import catgram/sql
import catgram/web
import envoy
import gleam/bool
import gleam/bytes_tree
import gleam/crypto
import gleam/dict
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/otp/actor
import gleam/pgo
import gleam/result
import gleam/string
import lustre
import lustre/server_component
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}
import wisp/wisp_mist
import youid/uuid

pub fn main() {
  let assert Ok(secret_key_base) = envoy.get("SECRET_KEY_BASE")
  let assert Ok(url) = envoy.get("DATABASE_URL")
  let assert Ok(config) = pgo.url_config(url)
  let db = pgo.connect(config)

  let assert Ok(pubsub) = pubsub.start()

  let ctx = web.Context(db, None)

  let server =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      let user =
        auth_user(db, req, secret_key_base)
        |> option.from_result

      let ctx = web.Context(..ctx, user:)

      let handle = router.handle_request(_, ctx)

      // io.debug(request.path_segments(req))
      // io.debug(req.method)
      case request.path_segments(req), req.method {
        // Set up the websocket connection to the client. This is how we send
        // DOM updates to the browser and receive events from the client.
        ["feed"], _ ->
          mist.websocket(
            request: req,
            on_init: socket_init(_, ctx, pubsub),
            on_close: socket_close,
            handler: socket_update,
          )

        // ["feed"], _ -> Response(405, [], mist.Bytes(bytes_builder.new()))
        _, _ -> wisp_mist.handler(handle, secret_key_base)(req)
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  case server {
    Ok(_) -> process.sleep_forever()
    Error(err) -> {
      io.debug(err)
      Nil
    }
  }
}

pub type SessionAuthError {
  InvalidCookieSessionId
  ExpiredSession
  NoExistingSession(session_id: uuid.Uuid)
  NoUserForSession(session: auth.Session)
  CannotFetchSession(reason: pgo.QueryError)
  CannotFetchUser(reason: pgo.QueryError)
}

pub fn auth_user(
  db,
  request,
  secret_key_base,
) -> Result(auth.User, SessionAuthError) {
  use session_id <- result.try(get_cookie_session_id(request, secret_key_base))
  use session <- result.try(fetch_session(db, session_id))

  case session_status(session) {
    Expired -> Error(ExpiredSession)
    NotExpired -> {
      use auth.User(id:, username:, email:, password:) <- result.map(
        fetch_session_user(db, session),
      )
      auth.User(id:, username:, email:, password:)
    }
  }
}

fn get_cookie_session_id(
  req,
  secret_key_base,
) -> Result(uuid.Uuid, SessionAuthError) {
  request.get_cookies(req)
  |> list.key_find("id")
  |> result.then(crypto.verify_signed_message(_, <<secret_key_base:utf8>>))
  |> result.then(fn(id) { uuid.from_bit_array(id) })
  |> result.replace_error(InvalidCookieSessionId)
}

fn fetch_session(db, session_id) -> Result(auth.Session, SessionAuthError) {
  case sql.get_session_by_id(db, session_id) {
    Error(reason) -> Error(CannotFetchSession(reason:))
    Ok(pgo.Returned(_, [])) -> Error(NoExistingSession(session_id:))
    Ok(pgo.Returned(
      _,
      [sql.GetSessionByIdRow(id:, created_at:, expires_at:, user_id:), ..],
    )) -> Ok(auth.Session(id:, created_at:, expires_at:, user_id:))
  }
}

fn fetch_session_user(db, session: auth.Session) {
  case sql.get_user_by_id(db, session.user_id) {
    Error(reason) -> Error(CannotFetchUser(reason:))
    Ok(pgo.Returned(_, [])) -> Error(NoUserForSession(session:))
    Ok(pgo.Returned(
      _,
      [sql.GetUserByIdRow(id:, username:, email:, password:), ..],
    )) -> Ok(auth.User(id:, username:, email:, password:))
  }
}

type SessionStatus {
  Expired
  NotExpired
}

fn session_status(session_row: auth.Session) -> SessionStatus {
  let session_expiration =
    birl.from_erlang_universal_datetime(session_row.expires_at)

  case birl.compare(session_expiration, birl.now()) {
    Lt | Eq -> Expired
    Gt -> NotExpired
  }
}

//

type Feed =
  Subject(lustre.Action(feed.Msg, lustre.ServerComponent))

fn socket_init(
  _conn: WebsocketConnection,
  ctx: web.Context,
  pubsub: pubsub.PubSub(
    lustre.Action(feed.Msg, lustre.ServerComponent),
    pubsub.Channel,
  ),
) -> #(Feed, Option(Selector(lustre.Patch(feed.Msg)))) {
  let self = process.new_subject()
  let app = feed.app()
  let assert Ok(feed) = lustre.start_actor(app, #(ctx.db, ctx.user, pubsub))

  pubsub.subscribe(pubsub, pubsub.Updates, feed)

  process.send(
    feed,
    server_component.subscribe(
      // server components can have many connected clients, so we need a way to
      // identify this client.
      "ws",
      // this callback is called whenever the server component has a new patch
      // to send to the client. here we json encode that patch and send it to
      // via the websocket connection.
      //
      // a more involved version would have us sending the patch to this socket's
      // subject, and then it could be handled (perhaps with some other work) in
      // the `mist.Custom` branch of `socket_update` below.
      process.send(self, _),
    ),
  )

  #(
    // we store the server component's `Subject` as this socket's state so we
    // can shut it down when the socket is closed.
    feed,
    Some(process.selecting(process.new_selector(), self, fn(a) { a })),
  )
}

fn socket_update(
  counter: Feed,
  conn: WebsocketConnection,
  msg: WebsocketMessage(lustre.Patch(feed.Msg)),
) {
  case msg {
    mist.Text(json) -> {
      // we attempt to decode the incoming text as an action to send to our
      // server component runtime.
      let action = json.decode(json, server_component.decode_action)

      case action {
        Ok(action) -> process.send(counter, action)
        Error(_) -> Nil
      }

      actor.continue(counter)
    }

    mist.Binary(_) -> actor.continue(counter)
    mist.Custom(patch) -> {
      let assert Ok(_) =
        patch
        |> server_component.encode_patch
        |> json.to_string
        |> mist.send_text_frame(conn, _)

      actor.continue(counter)
    }
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
  }
}

fn socket_close(counter: Feed) {
  process.send(counter, lustre.shutdown())
}
