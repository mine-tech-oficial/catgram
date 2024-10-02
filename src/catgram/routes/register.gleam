import catgram/auth
import catgram/web
import formal/form
import gleam/dict
import gleam/http
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html.{html}
import lustre/ui
import lustre/ui/layout/stack
import wisp.{type Request}

pub type Register {
  Register(username: String, email: String, password: String)
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
      html.header([], [html.h1([], [element.text("Register")])]),
      html.main([], [
        html.form([attribute.action("/register"), attribute.method("post")], [
          html.fieldset([], [
            html.label([attribute.for("username")], [element.text("Username")]),
            html.input([
              attribute.name("username"),
              attribute.placeholder("Username"),
              attribute.type_("text"),
            ]),
            //
            html.label([attribute.for("email")], [element.text("Email")]),
            html.input([
              attribute.name("email"),
              attribute.placeholder("Email"),
              attribute.type_("email"),
            ]),
            //
            html.label([attribute.for("password")], [element.text("Password")]),
            html.input([
              attribute.name("password"),
              attribute.placeholder("Password"),
              attribute.type_("password"),
            ]),
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

fn post(req: Request, ctx: web.Context) {
  use form_data <- wisp.require_form(req)

  let form = handle_form_submission(form_data.values)

  case form {
    Ok(form) -> {
      case
        auth.register_user(ctx.db, form.username, form.email, form.password)
      {
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
          html.header([], [html.h1([], [element.text("Register")])]),
          html.main([], [
            html.form(
              [attribute.action("/register"), attribute.method("post")],
              [
                html.fieldset([], [
                  html.label([attribute.for("username")], [
                    element.text("Username"),
                  ]),
                  form_state_input("username", "Username", "text", err),
                  //
                  html.label([attribute.for("email")], [element.text("Email")]),
                  form_state_input("email", "Email", "email", err),
                  //
                  html.label([attribute.for("password")], [
                    element.text("Password"),
                  ]),
                  form_state_input("password", "Password", "password", err),
                ]),
                //
                html.button([attribute.type_("submit")], [element.text("Login")]),
              ],
            ),
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
    use email <- form.parameter
    use password <- form.parameter
    Register(username:, email:, password:)
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
