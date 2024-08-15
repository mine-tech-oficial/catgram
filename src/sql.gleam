import decode
import gleam/pgo

/// A row you get from running the `get_posts` query
/// defined in `./src/sql/get_posts.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.3.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetPostsRow {
  GetPostsRow(id: Int, image_id: String, author: String, likes: Int)
}

/// Runs the `get_posts` query
/// defined in `./src/sql/get_posts.sql`.
///
/// > 🐿️ This function was generated automatically using v1.3.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_posts(db) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      use image_id <- decode.parameter
      use author <- decode.parameter
      use likes <- decode.parameter
      GetPostsRow(id: id, image_id: image_id, author: author, likes: likes)
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.string)
    |> decode.field(2, decode.string)
    |> decode.field(3, decode.int)

  "select
  id,
  image_id,
  author,
  likes
from
  post
order BY
  likes
desc"
  |> pgo.execute(db, [], decode.from(decoder, _))
}
