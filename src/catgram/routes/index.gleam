import catgram/web
import gleam/http
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html.{html}
import lustre/server_component
import lustre/ui
import lustre/ui/layout/group
import wisp.{type Request}

pub fn handle_request(req: Request, _ctx: web.Context) {
  use <- wisp.require_method(req, http.Get)

  html([], [
    html.head([], [
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/css/pico.min.css"),
      ]),
      html.script(
        [
          attribute.type_("module"),
          attribute.src("/lustre-server-component.mjs"),
        ],
        "",
      ),
    ]),
    html.body([], [
      // group.of(fn(attributes, elements) { html.div(attributes, elements) }, [], [
      //   html.a([attribute("href", "/register")], [element.text("Register")]),
      //   html.a([attribute("href", "/login")], [element.text("Login")]),
      // ]),
      html.header([attribute.class("container")], [
        html.h1([], [element.text("Catgram")]),
      ]),
      server_component.component([server_component.route("/feed")]),
    ]),
  ])
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}
