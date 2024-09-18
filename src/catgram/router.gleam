import catgram/routes/index
import catgram/routes/login
import catgram/web
import wisp.{type Request}

pub fn handle_request(req: Request, ctx: web.Context) {
  use req <- web.middleware(req)
  case wisp.path_segments(req) {
    // Serve the index page, creating a connedtion to the server component
    [] -> index.handle_request(req, ctx)

    ["login"] -> login.handle_request(req, ctx)

    // For all other requests we'll just serve nothing.
    _ -> wisp.not_found()
  }
}
