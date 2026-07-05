import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/io
import sqlight

const database_file = "file:glemail_db.sqlite3"

pub type DatabaseErrors {
  NotFoundError
  SqliteError(reason: String)
}

pub type User {
  User(id: Int, username: String, password: String, email_id: String)
}

type DatabaseTables {
  UsersTable
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  use email_id <- decode.field(3, decode.string)

  decode.success(User(id:, username:, password:, email_id:))
}

fn get_table_name(table: DatabaseTables) -> String {
  case table {
    UsersTable -> "users"
  }
}

fn add_quotes(text: String) -> String {
  "'" <> text <> "'"
}

pub fn create_db() -> Result(Nil, sqlight.Error) {
  use conn <- sqlight.with_connection(database_file)
  let sql =
    "CREATE TABLE IF NOT EXISTS "
    <> get_table_name(UsersTable)
    <> " (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT, email_id TEXT);"
  sqlight.exec(sql, conn)
}

// since this is just a personal project, basic encryption will do
pub fn hash_value(value: String) -> String {
  crypto.hash(crypto.Sha256, bit_array.from_string(value))
  |> bit_array.base16_encode()
}

pub fn create_user(
  username username: String,
  password password: String,
  email_id email_id: String,
) {
  use conn <- sqlight.with_connection(database_file)

  let sql =
    "INSERT INTO "
    <> get_table_name(UsersTable)
    <> " (username, password, email_id) VALUES ("
    <> add_quotes(username)
    <> ", "
    <> add_quotes(hash_value(password))
    <> ", "
    <> add_quotes(email_id)
    <> ");"

  case sqlight.exec(sql, conn) {
    Ok(_) -> {
      Ok(Nil)
    }
    Error(err) -> {
      io.print_error("Could not create user: " <> err.message)
      Error(err)
    }
  }
}

pub fn get_user(username: String) {
  use conn <- sqlight.with_connection(database_file)
  let sql =
    "SELECT * FROM "
    <> get_table_name(UsersTable)
    <> " WHERE username = "
    <> add_quotes(username)
    <> " LIMIT 1;"

  let users_list =
    sqlight.query(sql, on: conn, with: [], expecting: user_decoder())

  case users_list {
    Ok(users) -> {
      case users {
        [user] -> {
          Ok(user)
        }
        _ -> Error(NotFoundError)
      }
    }
    Error(err) -> Error(SqliteError(err.message))
  }
}
