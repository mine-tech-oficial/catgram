import gleam/io
import gleam/list
import gleam/pgo
import gleam/result
import lustre/effect
import sql.{type GetPostsRow, GetPostsRow}

// pub type Post {
//   Post(id: Int, image_id: String, author: String, likes: Int)
// }

pub fn get_posts(
  db: pgo.Connection,
  to_msg: fn(Result(List(GetPostsRow), pgo.QueryError)) -> msg,
) -> effect.Effect(msg) {
  use dispatch <- effect.from()

  io.debug("Fetching posts")

  let query = sql.get_posts(db)

  query
  |> result.map(fn(rows) { rows.rows })
  |> to_msg
  |> dispatch
}

pub fn like_post(
  id: Int,
  posts: List(GetPostsRow),
  to_msg: fn(List(GetPostsRow)) -> msg,
) -> effect.Effect(msg) {
  use dispatch <- effect.from()

  let new_posts =
    list.map(posts, fn(post) {
      case post.id == id {
        True -> GetPostsRow(post.id, post.image_id, post.author, post.likes + 1)
        False -> post
      }
    })

  new_posts
  |> to_msg
  |> dispatch
}
