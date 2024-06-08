import gleam/dynamic
import gleam/io
import gleam/list
import gleam/pgo
import lustre/effect

pub type Post {
  Post(id: Int, image_id: String, author: String, likes: Int)
}

pub fn get_posts(
  db: pgo.Connection,
  to_msg: fn(Result(List(Post), pgo.QueryError)) -> msg,
) -> effect.Effect(msg) {
  effect.from(fn(dispatch) {
    io.debug("Fetching posts")
    io.debug(db)
    let query =
      pgo.execute(
        "SELECT id, author, likes FROM post ORDER BY likes DESC",
        db,
        [],
        dynamic.decode4(
          Post,
          dynamic.int,
          dynamic.string,
          dynamic.string,
          dynamic.int,
        ),
      )
    io.debug(query)
    let query_rows = case query {
      Ok(posts) -> Ok(posts.rows)
      Error(err) -> Error(err)
    }
    io.debug(query_rows)
    query_rows
    |> to_msg
    |> dispatch
  })
}

pub fn like_post(
  id: Int,
  posts: List(Post),
  to_msg: fn(List(Post)) -> msg,
) -> effect.Effect(msg) {
  effect.from(fn(dispatch) {
    let new_posts =
      list.map(posts, fn(post) {
        case post.id == id {
          True -> Post(post.id, post.image_id, post.author, post.likes + 1)
          False -> post
        }
      })
    to_msg(new_posts)
    |> dispatch
  })
}
