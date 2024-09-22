import catgram/artifacts/pubsub
import catgram/sql.{type GetPostsRow, GetPostsRow}
import gleam/io
import gleam/pgo
import gleam/result
import lustre
import lustre/effect

// pub type Post {
//   Post(id: Int, image_id: String, author: String, likes: Int)
// }

pub fn get_posts(
  db: pgo.Connection,
  to_msg: fn(Result(List(GetPostsRow), pgo.QueryError)) -> msg,
) -> effect.Effect(msg) {
  use dispatch <- effect.from()

  io.debug("Fetching posts")

  sql.get_posts(db)
  |> result.map(fn(rows) { rows.rows })
  |> to_msg
  |> dispatch
}

pub fn like_post(
  id: Int,
  db: pgo.Connection,
  pubsub: pubsub.PubSub(
    lustre.Action(msg, lustre.ServerComponent),
    pubsub.Channel,
  ),
  to_msg: fn(Result(List(GetPostsRow), pgo.QueryError)) -> msg,
) -> effect.Effect(msg) {
  use dispatch <- effect.from()

  case sql.like_post(db, id) {
    Ok(_) ->
      sql.get_posts(db)
      |> result.map(fn(rows) { rows.rows })
      |> to_msg
      |> lustre.dispatch
      |> pubsub.publish(pubsub, pubsub.Updates, _)
    Error(err) ->
      Error(err)
      |> to_msg
      |> lustre.dispatch
      |> pubsub.publish(pubsub, pubsub.Updates, _)
  }
}
