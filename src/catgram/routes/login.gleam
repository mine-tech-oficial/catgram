import catgram/auth
import catgram/web
import formal/form
import gleam/http
import lustre/attribute
import lustre/element
import lustre/element/html.{html}
import wisp.{type Request}

pub type Login {
  Login(username: String, email: String, password: String)
}

pub fn handle_request(req: Request, ctx: web.Context) {
  case req.method {
    http.Get -> get(req, ctx)
    http.Post -> post(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn get(_, _) {
  html([], [
    html.body([], [
      html.h1([], [element.text("Login")]),
      html.form([attribute.action("/login"), attribute.method("post")], [
        html.input([attribute.name("username"), attribute.type_("text")]),
        html.input([attribute.name("email"), attribute.type_("email")]),
        html.input([attribute.name("password"), attribute.type_("password")]),
        html.button([attribute.type_("submit")], [element.text("Login")]),
      ]),
    ]),
  ])
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}

fn post(req: Request, ctx: web.Context) {
  use form_data <- wisp.require_form(req)

  let form = handle_form_submission(form_data.values)

  case form {
    Ok(form) -> {
      auth.register_user(ctx.db, form.username, form.email, form.password)
      wisp.redirect("/")
    }
    Error(form_state) -> {
      wisp.bad_request()
    }
  }
}

fn handle_form_submission(values: List(#(String, String))) {
  form.decoding({
    use username <- form.parameter
    use email <- form.parameter
    use password <- form.parameter
    Login(username:, email:, password:)
  })
  |> form.with_values(values)
  |> form.field(
    "username",
    form.string
      |> form.and(form.must_not_be_empty),
  )
  |> form.field(
    "email",
    form.string
      |> form.and(form.must_not_be_empty)
      |> form.and(form.must_be_an_email),
  )
  |> form.field(
    "password",
    form.string
      |> form.and(form.must_not_be_empty)
      |> form.and(form.must_be_string_longer_than(7)),
  )
  |> form.finish
}
