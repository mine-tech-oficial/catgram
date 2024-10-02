import catgram/auth
import gleam/erlang
import gleam/option.{type Option}
import gleam/pgo
import wisp.{type Request, type Response}

pub type Context {
  Context(db: pgo.Connection, user: Option(auth.User))
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let assert Ok(priv) = erlang.priv_directory("catgram")
  let assert Ok(lustre_priv) = erlang.priv_directory("lustre")
  use <- wisp.serve_static(req, under: "", from: priv)
  use <- wisp.serve_static(req, under: "", from: lustre_priv <> "/static")

  handle_request(req)
}
