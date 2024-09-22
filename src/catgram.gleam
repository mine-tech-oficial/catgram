import catgram/artifacts/pubsub
import catgram/router
import catgram/routes/feed
import catgram/web
import chip
import gleam/bytes_builder
import gleam/erlang/os
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/pgo
import lustre
import lustre/server_component
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}
import wisp/wisp_mist

pub fn main() {
  let assert Ok(url) = os.get_env("DATABASE_URL")
  let assert Ok(config) = pgo.url_config(url)
  let db = pgo.connect(config)

  let assert Ok(pubsub) = pubsub.start()

  let ctx = web.Context(db, None)

  let handle = router.handle_request(_, ctx)

  let server =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      io.debug(request.path_segments(req))
      io.debug(req.method)
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
        _, _ -> wisp_mist.handler(handle, "")(req)
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
  let assert Ok(feed) = lustre.start_actor(app, #(ctx.db, pubsub))

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
