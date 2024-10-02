import catgram/auth
import catgram/web
import formal/form
import gleam/dict
import gleam/http
import gleam/int
import gleam/list
import gleam/result
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html.{html}
import wisp.{type Request}

pub type Login {
  Login(username: String, password: String)
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
    html.head([], [
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/css/pico.min.css"),
      ]),
    ]),
    html.body([attribute.class("container")], [
      html.header([], [html.h1([], [element.text("Login")])]),
      html.main([], [
        html.form([attribute.action("/login"), attribute.method("post")], [
          html.fieldset([], [
            html.label([attribute.for("username")], [element.text("Username")]),
            html.input([
              attribute.name("username"),
              attribute.placeholder("Username"),
              attribute.type_("username"),
            ]),
            //
            html.label([attribute.for("password")], [element.text("Password")]),
            html.input([
              attribute.name("password"),
              attribute.placeholder("Password"),
              attribute.type_("password"),
            ]),
          ]),
          html.button([attribute.type_("submit")], [element.text("Login")]),
        ]),
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
      case auth.login_user(ctx.db, form.username, form.password) {
        Ok(#(_, session)) -> {
          wisp.redirect("/")
          |> wisp.set_cookie(
            req,
            "id",
            int.to_string(session.id),
            wisp.Signed,
            60 * 60 * 24,
          )
        }
        Error(_) -> wisp.internal_server_error()
      }
    }
    Error(err) ->
      html([], [
        html.head([], [
          html.link([
            attribute.rel("stylesheet"),
            attribute.href("/css/pico.min.css"),
          ]),
        ]),
        html.body([attribute.class("container")], [
          html.header([], [html.h1([], [element.text("Login")])]),
          html.main([], [
            html.form([attribute.action("/login"), attribute.method("post")], [
              html.fieldset([], [
                html.label([attribute.for("username")], [
                  element.text("Username"),
                ]),
                form_state_input("username", "Username", "text", err),
                //
                html.label([attribute.for("password")], [
                  element.text("Password"),
                ]),
                form_state_input("password", "Password", "password", err),
              ]),
              //
              html.button([attribute.type_("submit")], [element.text("Login")]),
            ]),
          ]),
        ]),
      ])
      |> element.to_document_string_builder
      |> wisp.html_response(200)
  }
}

fn handle_form_submission(values: List(#(String, String))) {
  form.decoding({
    use username <- form.parameter
    use password <- form.parameter
    Login(username:, password:)
  })
  |> form.with_values(values)
  |> form.field(
    "username",
    form.string
      |> form.and(form.must_not_be_empty),
  )
  |> form.field(
    "password",
    form.string
      |> form.and(form.must_not_be_empty)
      |> form.and(form.must_be_string_longer_than(7)),
  )
  |> form.finish
}

fn form_state_input(
  name: String,
  placeholder: String,
  type_: String,
  form_state: form.Form,
) {
  case dict.get(form_state.errors, name) {
    Ok(err) ->
      element.fragment([
        html.input([
          attribute.name(name),
          attribute.placeholder(placeholder),
          attribute.type_(type_),
          attribute("aria-invalid", "true"),
          attribute("aria-describedby", "invalid-" <> name <> "-helper"),
        ]),
        html.small([attribute.id("invalid-" <> name <> "-helper")], [
          element.text(err),
        ]),
      ])
    Error(_) ->
      html.input(case
        result.try(dict.get(form_state.values, name), list.first)
      {
        Ok(value) -> [
          attribute.name(name),
          attribute.placeholder(placeholder),
          attribute.type_(type_),
          attribute.value(value),
        ]
        Error(_) -> [
          attribute.name(name),
          attribute.placeholder(placeholder),
          attribute.type_(type_),
        ]
      })
  }
}
