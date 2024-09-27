import decode
import gleam/pgo

/// Runs the `like` query
/// defined in `./src/catgram/sql/like.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn like(db, arg_1, arg_2) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "insert into
  \"like\"
values
  ($1, $2)"
  |> pgo.execute(db, [pgo.int(arg_1), pgo.int(arg_2)], decode.from(decoder, _))
}

/// A row you get from running the `get_like` query
/// defined in `./src/catgram/sql/get_like.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLikeRow {
  GetLikeRow(user_id: Int, post_id: Int)
}

/// Runs the `get_like` query
/// defined in `./src/catgram/sql/get_like.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_like(db, arg_1, arg_2) {
  let decoder =
    decode.into({
      use user_id <- decode.parameter
      use post_id <- decode.parameter
      GetLikeRow(user_id: user_id, post_id: post_id)
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.int)

  "select
  user_id,
  post_id
from
  \"like\"
where
  user_id = $1
  and post_id = $2"
  |> pgo.execute(db, [pgo.int(arg_1), pgo.int(arg_2)], decode.from(decoder, _))
}

/// A row you get from running the `get_session_by_id` query
/// defined in `./src/catgram/sql/get_session_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetSessionByIdRow {
  GetSessionByIdRow(
    id: Int,
    created_at: #(#(Int, Int, Int), #(Int, Int, Int)),
    expires_at: #(#(Int, Int, Int), #(Int, Int, Int)),
    user_id: Int,
  )
}

/// Runs the `get_session_by_id` query
/// defined in `./src/catgram/sql/get_session_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_session_by_id(db, arg_1) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      use created_at <- decode.parameter
      use expires_at <- decode.parameter
      use user_id <- decode.parameter
      GetSessionByIdRow(
        id: id,
        created_at: created_at,
        expires_at: expires_at,
        user_id: user_id,
      )
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, timestamp_decoder())
    |> decode.field(2, timestamp_decoder())
    |> decode.field(3, decode.int)

  "select
  id,
  date_trunc('second', created_at) as created_at,
  expires_at,
  user_id
from
  \"session\"
where
  id = $1"
  |> pgo.execute(db, [pgo.int(arg_1)], decode.from(decoder, _))
}

/// A row you get from running the `get_user_by_id` query
/// defined in `./src/catgram/sql/get_user_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserByIdRow {
  GetUserByIdRow(id: Int, username: String, email: String, password: String)
}

/// Runs the `get_user_by_id` query
/// defined in `./src/catgram/sql/get_user_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_by_id(db, arg_1) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      use username <- decode.parameter
      use email <- decode.parameter
      use password <- decode.parameter
      GetUserByIdRow(
        id: id,
        username: username,
        email: email,
        password: password,
      )
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.string)
    |> decode.field(2, decode.string)
    |> decode.field(3, decode.string)

  "select
  id,
  username,
  email,
  password
from
  \"user\"
where
  id = $1"
  |> pgo.execute(db, [pgo.int(arg_1)], decode.from(decoder, _))
}

/// A row you get from running the `get_users` query
/// defined in `./src/catgram/sql/get_users.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUsersRow {
  GetUsersRow(id: Int, username: String, email: String, password: String)
}

/// Runs the `get_users` query
/// defined in `./src/catgram/sql/get_users.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_users(db) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      use username <- decode.parameter
      use email <- decode.parameter
      use password <- decode.parameter
      GetUsersRow(id: id, username: username, email: email, password: password)
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.string)
    |> decode.field(2, decode.string)
    |> decode.field(3, decode.string)

  "select
  id,
  username,
  email,
  password
from
  \"user\""
  |> pgo.execute(db, [], decode.from(decoder, _))
}

/// Runs the `dislike` query
/// defined in `./src/catgram/sql/dislike.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn dislike(db, arg_1, arg_2) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "delete from
  \"like\"
where
  user_id = $1
  and post_id = $2"
  |> pgo.execute(db, [pgo.int(arg_1), pgo.int(arg_2)], decode.from(decoder, _))
}

/// A row you get from running the `get_posts` query
/// defined in `./src/catgram/sql/get_posts.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetPostsRow {
  GetPostsRow(id: Int, image_id: String, author: String, likes: Int, liked: Bool,
  )
}

/// Runs the `get_posts` query
/// defined in `./src/catgram/sql/get_posts.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_posts(db, arg_1) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      use image_id <- decode.parameter
      use author <- decode.parameter
      use likes <- decode.parameter
      use liked <- decode.parameter
      GetPostsRow(
        id: id,
        image_id: image_id,
        author: author,
        likes: likes,
        liked: liked,
      )
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.string)
    |> decode.field(2, decode.string)
    |> decode.field(3, decode.int)
    |> decode.field(4, decode.bool)

  "select
  id,
  image_id,
  author,
  likes,
  exists(select 1 from \"like\" where post_id = id and user_id = $1) as liked
from
  post
order by
  likes
desc"
  |> pgo.execute(db, [pgo.int(arg_1)], decode.from(decoder, _))
}

/// Runs the `dislike_post` query
/// defined in `./src/catgram/sql/dislike_post.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn dislike_post(db, arg_1) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "update
  post
set
  likes = likes - 1
where
  id = $1"
  |> pgo.execute(db, [pgo.int(arg_1)], decode.from(decoder, _))
}

/// A row you get from running the `get_user_by_username` query
/// defined in `./src/catgram/sql/get_user_by_username.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserByUsernameRow {
  GetUserByUsernameRow(
    id: Int,
    username: String,
    email: String,
    password: String,
  )
}

/// Runs the `get_user_by_username` query
/// defined in `./src/catgram/sql/get_user_by_username.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_by_username(db, arg_1) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      use username <- decode.parameter
      use email <- decode.parameter
      use password <- decode.parameter
      GetUserByUsernameRow(
        id: id,
        username: username,
        email: email,
        password: password,
      )
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, decode.string)
    |> decode.field(2, decode.string)
    |> decode.field(3, decode.string)

  "select
  id,
  username,
  email,
  password
from
  \"user\"
where
  username = $1"
  |> pgo.execute(db, [pgo.text(arg_1)], decode.from(decoder, _))
}

/// A row you get from running the `insert_session` query
/// defined in `./src/catgram/sql/insert_session.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertSessionRow {
  InsertSessionRow(id: Int, created_at: #(#(Int, Int, Int), #(Int, Int, Int)))
}

/// Runs the `insert_session` query
/// defined in `./src/catgram/sql/insert_session.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_session(db, arg_1, arg_2) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      use created_at <- decode.parameter
      InsertSessionRow(id: id, created_at: created_at)
    })
    |> decode.field(0, decode.int)
    |> decode.field(1, timestamp_decoder())

  "insert into
  \"session\" (expires_at, user_id)
values
  ($1, $2)
returning
  id, date_trunc('second', created_at) as created_at"
  |> pgo.execute(
    db,
    [pgo.timestamp(arg_1), pgo.int(arg_2)],
    decode.from(decoder, _),
  )
}

/// Runs the `like_post` query
/// defined in `./src/catgram/sql/like_post.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn like_post(db, arg_1) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "update
  post
set
  likes = likes + 1
where
  id = $1"
  |> pgo.execute(db, [pgo.int(arg_1)], decode.from(decoder, _))
}

/// A row you get from running the `insert_user` query
/// defined in `./src/catgram/sql/insert_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v1.7.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertUserRow {
  InsertUserRow(id: Int)
}

/// Runs the `insert_user` query
/// defined in `./src/catgram/sql/insert_user.sql`.
///
/// > 🐿️ This function was generated automatically using v1.7.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_user(db, arg_1, arg_2, arg_3) {
  let decoder =
    decode.into({
      use id <- decode.parameter
      InsertUserRow(id: id)
    })
    |> decode.field(0, decode.int)

  "insert into
  \"user\"
values
  (default, $1, $2, $3)
returning
  id"
  |> pgo.execute(
    db,
    [pgo.text(arg_1), pgo.text(arg_2), pgo.text(arg_3)],
    decode.from(decoder, _),
  )
}


// --- UTILS -------------------------------------------------------------------

/// A decoder to decode `timestamp`s coming from a Postgres query.
///
fn timestamp_decoder() {
  use dynamic <- decode.then(decode.dynamic)
  case pgo.decode_timestamp(dynamic) {
    Ok(timestamp) -> decode.into(timestamp)
    Error(_) -> decode.fail("timestamp")
  }
}
