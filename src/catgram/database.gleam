import catgram/artifacts/pubsub
import catgram/sql.{type GetPostsRow, GetPostsRow}
import gleam/io
import gleam/list
import gleam/pgo
import gleam/result
import lustre
import lustre/effect

// pub type Post {
//   Post(id: Int, image_id: String, author: String, likes: Int)
// }

pub fn get_posts(
  db: pgo.Connection,
  user_id: Int,
  to_msg: fn(Result(List(GetPostsRow), pgo.QueryError)) -> msg,
) -> effect.Effect(msg) {
  use dispatch <- effect.from()

  io.debug("Fetching posts")

  sql.get_posts(db, user_id)
  |> result.map(fn(rows) { rows.rows })
  |> to_msg
  |> dispatch
}

pub fn like_post(
  user_id user_id: Int,
  post_id post_id: Int,
  db db: pgo.Connection,
  pubsub pubsub: pubsub.PubSub(
    lustre.Action(msg, lustre.ServerComponent),
    pubsub.Channel,
  ),
  to_msg to_msg: fn(Result(List(GetPostsRow), pgo.TransactionError)) -> msg,
) -> effect.Effect(msg) {
  use _ <- effect.from()

  let liked = case sql.get_like(db, user_id, post_id) {
    Ok(returned) -> !list.is_empty(returned.rows)
    Error(_) -> False
  }

  let operation = case liked {
    True -> sql.dislike_post
    False -> sql.like_post
  }

  let tran =
    pgo.transaction(db, fn(_) {
      operation(db, post_id)
      |> result.map(fn(_) {
        let result = case liked {
          True -> sql.dislike(db, user_id, post_id)
          False -> sql.like(db, user_id, post_id)
        }

        result
        |> result.map(fn(_) {
          sql.get_posts(db, user_id)
          |> result.map(fn(rows) { rows.rows })
          |> result.map_error(pgo.TransactionQueryError(_))
          |> to_msg
          |> lustre.dispatch
          |> pubsub.publish(pubsub, pubsub.Updates, _)
        })
        |> result.map_error(fn(e) {
          Error(pgo.TransactionQueryError(e))
          |> to_msg
          |> lustre.dispatch
          |> pubsub.publish(pubsub, pubsub.Updates, _)
        })
      })
      |> result.map_error(fn(e) {
        Error(pgo.TransactionQueryError(e))
        |> to_msg
        |> lustre.dispatch
        |> pubsub.publish(pubsub, pubsub.Updates, _)

        ""
      })
    })

  case tran {
    Ok(_) -> Nil
    Error(e) ->
      Error(e)
      |> to_msg
      |> lustre.dispatch
      |> pubsub.publish(pubsub, pubsub.Updates, _)
  }
}
