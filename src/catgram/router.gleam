import catgram/auth
import catgram/routes/index
import catgram/routes/login
import catgram/routes/register
import catgram/sql
import catgram/web
import gleam/erlang
import gleam/int
import gleam/option
import gleam/result
import wisp.{type Request}

pub fn handle_request(req: Request, ctx: web.Context) {
  use req <- web.middleware(req)
  // TODO: Actually retrieve the session from the database
  let session =
    wisp.get_cookie(req, "id", wisp.Signed)
    |> result.map(fn(cookie) {
      auth.Session(
        result.unwrap(int.parse(cookie), 0),
        #(#(0, 0, 0), #(0, 0, 0)),
        #(#(0, 0, 0), #(0, 0, 0)),
        0,
      )
    })
    |> option.from_result
  let ctx = web.Context(..ctx, session:)
  case wisp.path_segments(req) {
    // Serve the index page, creating a connedtion to the server component
    [] -> index.handle_request(req, ctx)

    ["register"] -> register.handle_request(req, ctx)

    ["login"] -> login.handle_request(req, ctx)

    // ["lustre-server-component.mjs"] -> {
    //   let assert Ok(priv) = erlang.priv_directory("lustre")
    //   let path = priv <> "/static/lustre-server-component.mjs"
    //   wisp.ok()
    //   |> wisp.file_download("lustre-server-component.mjs", path)
    // }
    // For all other requests we'll just serve nothing.
    _ -> wisp.not_found()
  }
}
