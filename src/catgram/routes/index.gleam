import catgram/web
import gleam/http
import lustre/attribute
import lustre/element
import lustre/element/html.{html}
import lustre/server_component
import wisp.{type Request}

pub fn handle_request(req: Request, _ctx: web.Context) {
  use <- wisp.require_method(req, http.Get)

  html([], [
    html.head([], [
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(
          "https://cdn.jsdelivr.net/gh/lustre-labs/ui/priv/styles.css",
        ),
      ]),
      html.script(
        [
          attribute.type_("module"),
          attribute.src("/lustre-server-component.mjs"),
        ],
        "",
      ),
      // styles.elements(),
    ]),
    html.body([], [
      server_component.component([server_component.route("/feed")]),
    ]),
  ])
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}
