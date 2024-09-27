import catgram/routes/index
import catgram/routes/login
import catgram/routes/register
import catgram/web
import wisp.{type Request}

pub fn handle_request(req: Request, ctx: web.Context) {
  use req <- web.middleware(req)
  // let user =
  //   wisp.get_cookie(req, "id", wisp.Signed)
  //   |> result.try(int.parse)
  //   |> result.try(fn(id) {
  //     sql.get_session_by_id(ctx.db, id)
  //     |> result.map_error(fn(_) { Nil })
  //   })
  //   |> result.try(fn(returned) { list.first(returned.rows) })
  //   |> result.map(fn(session_row) {
  //     auth.Session(
  //       session_row.id,
  //       session_row.created_at,
  //       session_row.expires_at,
  //       session_row.user_id,
  //     )
  //   })
  //   |> option.from_result

  // let ctx = web.Context(..ctx, user:)

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
