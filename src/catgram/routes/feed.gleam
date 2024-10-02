import catgram/artifacts/pubsub
import catgram/auth
import catgram/database
import catgram/sql.{type GetPostsRow, GetPostsRow}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pgo
import lustre
import lustre/attribute.{attribute}
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui/layout/stack
import phosphor

// MAIN ------------------------------------------------------------------------

pub fn app() {
  lustre.application(init, update, view)
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(
    db: pgo.Connection,
    pubsub: pubsub.PubSub(
      lustre.Action(Msg, lustre.ServerComponent),
      pubsub.Channel,
    ),
    posts: List(GetPostsRow),
    user: Option(auth.User),
  )
}

fn init(
  params: #(
    pgo.Connection,
    Option(auth.User),
    pubsub.PubSub(lustre.Action(Msg, lustre.ServerComponent), pubsub.Channel),
  ),
) -> #(Model, effect.Effect(Msg)) {
  case params.1 {
    Some(user) -> #(
      Model(params.0, params.2, [], params.1),
      database.get_posts(params.0, user.id, ApiReturnedPosts),
    )
    None -> #(Model(params.0, params.2, [], params.1), effect.none())
  }
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  UserLikedPost(Int)
  ApiReturnedPosts(Result(List(GetPostsRow), pgo.QueryError))
  ApiLikedPost(Result(List(GetPostsRow), pgo.TransactionError))
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case model.user {
    Some(user) ->
      case msg {
        UserLikedPost(post_id) -> #(
          model,
          database.like_post(
            user_id: user.id,
            post_id:,
            db: model.db,
            pubsub: model.pubsub,
            to_msg: ApiLikedPost,
          ),
        )
        ApiReturnedPosts(Ok(posts)) -> #(
          Model(..model, posts: list.append(model.posts, posts)),
          effect.none(),
        )
        ApiReturnedPosts(Error(_err)) -> #(model, effect.none())
        ApiLikedPost(Ok(posts)) -> #(Model(..model, posts:), effect.none())
        ApiLikedPost(Error(_err)) -> #(model, effect.none())
      }
    None -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  // let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]
  html.main([attribute.class("container")], case model.user {
    Some(_) ->
      list.map(model.posts, fn(post) {
        html.article([], [
          html.img([attribute.src("https://cataas.com/cat/" <> post.image_id)]),
          html.footer([], [
            element.text(post.author),
            html.button([event.on_click(UserLikedPost(post.id))], [
              case post.liked {
                True ->
                  phosphor.thumbs_up_fill([
                    attribute.style([#("width", "32px"), #("height", "32px")]),
                  ])
                False ->
                  phosphor.thumbs_up_regular([
                    attribute.style([#("width", "32px"), #("height", "32px")]),
                  ])
              },
            ]),
            element.text(int.to_string(post.likes)),
          ]),
        ])
      })

    None -> [
      html.h2([], [element.text("Please login")]),
      html.a([attribute("href", "/register")], [element.text("Register")]),
      html.br([]),
      html.a([attribute("href", "/login")], [element.text("Login")]),
    ]
  })
}
