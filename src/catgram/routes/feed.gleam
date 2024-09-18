import catgram/auth
import catgram/database
import catgram/sql.{type GetPostsRow, GetPostsRow}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui
import lustre/ui/layout/stack

// MAIN ------------------------------------------------------------------------

pub fn app() {
  lustre.application(init, update, view)
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(db: pgo.Connection, posts: List(GetPostsRow), user: Option(auth.User))
}

fn init(db: pgo.Connection) -> #(Model, effect.Effect(Msg)) {
  #(Model(db, [], None), database.get_posts(db, ApiReturnedPosts))
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  UserLikedPost(Int)
  UserRegistered(String, String, String)
  UserLoggedIn(String, String)
  ApiReturnedPosts(Result(List(GetPostsRow), pgo.QueryError))
  ApiLikedPost(Result(List(GetPostsRow), pgo.QueryError))
  ApiRegisteredUser(Result(#(auth.User, auth.Session), auth.RegistrationError))
  ApiLoggedInUser(Result(#(auth.User, auth.Session), auth.LoginError))
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  io.debug(msg)
  case msg {
    UserLikedPost(post_id) -> #(
      model,
      database.like_post(post_id, model.db, ApiLikedPost),
    )
    UserRegistered(username, email, password) -> #(
      model,
      auth.register_user_effect(
        model.db,
        username,
        email,
        password,
        ApiRegisteredUser,
      ),
    )
    UserLoggedIn(username, password) -> #(
      model,
      auth.login_user_effect(model.db, username, password, ApiLoggedInUser),
    )
    ApiReturnedPosts(Ok(posts)) -> #(
      Model(..model, posts: list.append(model.posts, posts)),
      effect.none(),
    )
    ApiReturnedPosts(Error(_err)) -> #(model, effect.none())
    ApiLikedPost(Ok(posts)) -> #(Model(..model, posts:), effect.none())
    ApiLikedPost(Error(_err)) -> #(model, effect.none())
    ApiRegisteredUser(Ok(_)) -> #(model, effect.none())
    ApiRegisteredUser(Error(_err)) -> #(model, effect.none())
    ApiLoggedInUser(Ok(#(user, _))) -> #(
      Model(..model, user: Some(user)),
      effect.none(),
    )
    ApiLoggedInUser(Error(_err)) -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  // let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]

  ui.centre(
    [],
    ui.stack([stack.loose()], [
      ui.button(
        [event.on_click(UserRegistered("pedro", "pedro@gmail.com", "123456"))],
        [element.text("Register")],
      ),
      ui.button([event.on_click(UserLoggedIn("pedro", "123456"))], [
        element.text("Login"),
      ]),
      ..list.map(model.posts, fn(post) {
        ui.stack([stack.packed()], [
          html.img([attribute.src("https://cataas.com/cat/" <> post.image_id)]),
          ui.cluster([], [
            element.text(post.author),
            ui.button([event.on_click(UserLikedPost(post.id))], [
              element.text(int.to_string(post.likes)),
            ]),
          ]),
        ])
      })
    ]),
  )
}
