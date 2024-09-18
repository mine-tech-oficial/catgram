import gleam/erlang
import gleam/pgo
import wisp.{type Request, type Response}

pub type Context {
  Context(db: pgo.Connection)
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let assert Ok(priv) = erlang.priv_directory("lustre")
  use <- wisp.serve_static(req, "/static", priv)

  handle_request(req)
}
