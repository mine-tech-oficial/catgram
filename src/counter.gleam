import database
import gleam/erlang/os
import gleam/int
import gleam/io
import gleam/list
import gleam/pgo
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui
import lustre/ui/layout/stack
import sql.{type GetPostsRow, GetPostsRow}

// MAIN ------------------------------------------------------------------------

pub fn app() {
  lustre.application(init, update, view)
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(db: pgo.Connection, posts: List(GetPostsRow))
}

fn init(_) -> #(Model, effect.Effect(Msg)) {
  let assert Ok(url) = os.get_env("DATABASE_URL")
  let assert Ok(config) = pgo.url_config(url)
  let db = pgo.connect(config)
  #(Model(db, []), database.get_posts(db, ApiReturnedPosts))
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  UserLikedPost(Int)
  ApiReturnedPosts(Result(List(GetPostsRow), pgo.QueryError))
  ApiLikedPost(List(GetPostsRow))
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  io.debug(msg)
  case msg {
    UserLikedPost(post_id) -> #(
      model,
      database.like_post(post_id, model.posts, ApiLikedPost),
    )
    ApiReturnedPosts(Ok(posts)) -> #(
      Model(model.db, list.append(model.posts, posts)),
      effect.none(),
    )
    ApiReturnedPosts(Error(_err)) -> #(model, effect.none())
    ApiLikedPost(posts) -> #(Model(model.db, posts), effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  // let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]

  ui.centre(
    [],
    ui.stack(
      [stack.loose()],
      list.map(model.posts, fn(post) {
        ui.stack([stack.packed()], [
          html.img([attribute.src("https://cataas.com/cat/" <> post.image_id)]),
          ui.cluster([], [
            element.text(post.author),
            ui.button([event.on_click(UserLikedPost(post.id))], [
              element.text(int.to_string(post.likes)),
            ]),
          ]),
        ])
      }),
    ),
  )
}
