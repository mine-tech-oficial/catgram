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
import lustre/element/svg
import lustre/event

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
                  thumbs_up_fill([
                    attribute.style([#("width", "32px"), #("height", "32px")]),
                  ])
                False ->
                  thumbs_up_regular([
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

fn thumbs_up_fill(attrs: List(attribute.Attribute(msg))) -> Element(msg) {
  let base_attributes = [
    attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    attribute.attribute("fill", "currentColor"),
    attribute.attribute("stroke", "currentColor"),
    attribute.attribute("stroke-linecap", "round"),
    attribute.attribute("viewBox", "0 0 256 256"),
    attribute.attribute("width", "1em"),
    attribute.attribute("height", "1em"),
    ..attrs
  ]

  let combined_attributes = list.flatten([base_attributes, attrs])

  svg.svg(combined_attributes, [
    svg.path([
      attribute.attribute(
        "d",
        "M234,80.12A24,24,0,0,0,216,72H160V56a40,40,0,0,0-40-40,8,8,0,0,0-7.16,4.42L75.06,96H32a16,16,0,0,0-16,16v88a16,16,0,0,0,16,16H204a24,24,0,0,0,23.82-21l12-96A24,24,0,0,0,234,80.12ZM32,112H72v88H32Z",
      ),
    ]),
  ])
}

fn thumbs_up_regular(attrs: List(attribute.Attribute(msg))) -> Element(msg) {
  let base_attributes = [
    attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    attribute.attribute("fill", "currentColor"),
    attribute.attribute("stroke", "currentColor"),
    attribute.attribute("stroke-linecap", "round"),
    attribute.attribute("viewBox", "0 0 256 256"),
    attribute.attribute("width", "1em"),
    attribute.attribute("height", "1em"),
    ..attrs
  ]

  let combined_attributes = list.flatten([base_attributes, attrs])

  svg.svg(combined_attributes, [
    svg.path([
      attribute.attribute(
        "d",
        "M234,80.12A24,24,0,0,0,216,72H160V56a40,40,0,0,0-40-40,8,8,0,0,0-7.16,4.42L75.06,96H32a16,16,0,0,0-16,16v88a16,16,0,0,0,16,16H204a24,24,0,0,0,23.82-21l12-96A24,24,0,0,0,234,80.12ZM32,112H72v88H32ZM223.94,97l-12,96a8,8,0,0,1-7.94,7H88V105.89l36.71-73.43A24,24,0,0,1,144,56V80a8,8,0,0,0,8,8h64a8,8,0,0,1,7.94,9Z",
      ),
    ]),
  ])
}
