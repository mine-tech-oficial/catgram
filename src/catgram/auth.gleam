import argus
import birl
import birl/duration
import catgram/sql
import gleam/io
import gleam/list
import gleam/pgo
import gleam/result
import lustre/effect

pub type User {
  User(id: Int, username: String, email: String, password: String)
}

pub type Session {
  Session(
    id: Int,
    created_at: #(#(Int, Int, Int), #(Int, Int, Int)),
    expires_at: #(#(Int, Int, Int), #(Int, Int, Int)),
    user_id: Int,
  )
}

pub type RegistrationError {
  RegistrationQueryError(pgo.QueryError)
  RegistrationHashError(argus.HashError)
  RegistrationWhat
  RegistrationLoginError(LoginError)
}

pub type LoginError {
  LoginQueryError(pgo.QueryError)
  LoginHashError(argus.HashError)
  LoginWhat
  UserNotFound
  InvalidPassword
}

pub fn register_user(
  db: pgo.Connection,
  username: String,
  email: String,
  password: String,
) {
  let hashed_password =
    argus.hasher()
    |> argus.hash(password, argus.gen_salt())

  case hashed_password {
    Ok(hashed_password) ->
      sql.insert_user(db, username, email, hashed_password.encoded_hash)
      |> result.map(fn(returned) {
        case list.first(returned.rows) {
          Ok(user) -> Ok(User(user.id, username, email, password))
          Error(_) -> Error(RegistrationWhat)
        }
      })
      |> result.map_error(fn(err) { RegistrationQueryError(err) })
      |> result.flatten()
    Error(err) -> Error(RegistrationHashError(err))
  }
  |> result.map(fn(user) {
    login_user(db, username, password)
    |> result.map_error(fn(err) { RegistrationLoginError(err) })
  })
  |> result.flatten()
}

pub fn register_user_effect(
  db: pgo.Connection,
  username: String,
  email: String,
  password: String,
  to_msg: fn(Result(#(User, Session), RegistrationError)) -> msg,
) -> effect.Effect(msg) {
  use dispatch <- effect.from()

  register_user(db, username, email, password)
  |> to_msg
  |> dispatch
}

pub fn login_user(
  db: pgo.Connection,
  username: String,
  password: String,
) -> Result(#(User, Session), LoginError) {
  let expires_at =
    birl.utc_now()
    |> birl.add(duration.hours(1))
    |> birl.to_erlang_datetime

  let result =
    sql.get_user_by_username(db, username)
    |> result.map_error(fn(err) { LoginQueryError(err) })
    |> result.map(fn(user) {
      list.first(user.rows)
      |> result.map_error(fn(_) { UserNotFound })
    })
    |> result.flatten()

  case result {
    Ok(user) ->
      case argus.verify(user.password, password) {
        Ok(True) ->
          create_session(
            db,
            expires_at,
            User(user.id, user.username, user.email, password),
          )
        Ok(False) -> Error(InvalidPassword)
        Error(err) -> Error(LoginHashError(err))
      }
    Error(err) -> Error(err)
  }
}

pub fn login_user_effect(
  db: pgo.Connection,
  username: String,
  password: String,
  to_msg: fn(Result(#(User, Session), LoginError)) -> msg,
) -> effect.Effect(msg) {
  use dispatch <- effect.from()

  login_user(db, username, password)
  |> to_msg
  |> dispatch
}

fn create_session(
  db: pgo.Connection,
  expires_at: #(#(Int, Int, Int), #(Int, Int, Int)),
  user: User,
) -> Result(#(User, Session), LoginError) {
  sql.insert_session(db, expires_at, user.id)
  |> result.map(fn(result) {
    case list.first(result.rows) {
      Ok(session) ->
        Ok(#(user, Session(session.id, session.created_at, expires_at, user.id)))
      Error(_) -> Error(LoginWhat)
    }
  })
  |> result.map_error(fn(err) { LoginQueryError(err) })
  |> result.flatten()
}
