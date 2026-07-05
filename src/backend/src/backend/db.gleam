import gleam/bit_array
import gleam/crypto
import gleam/io
import sqlight

const database_file = "file:glemail_db.sqlite3"

type DatabaseTables {
  UsersTable
}

fn get_table_name(table: DatabaseTables) -> String {
  case table {
    UsersTable -> "users"
  }
}

pub fn create_db() -> Result(Nil, sqlight.Error) {
  use conn <- sqlight.with_connection(database_file)
  let sql =
    "CREATE TABLE IF NOT EXISTS "
    <> get_table_name(UsersTable)
    <> " (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT, email_id TEXT);"
  sqlight.exec(sql, conn)
}

pub fn create_user(
  username username: String,
  password password: String,
  email_id email_id: String,
) {
  use conn <- sqlight.with_connection(database_file)

  // since this is just a personal project, basic encryption will do
  let hashed_password =
    crypto.hash(crypto.Sha256, bit_array.from_string(password))
    |> bit_array.base16_encode()

  let sql =
    "INSERT INTO "
    <> get_table_name(UsersTable)
    <> " (username, password, email_id) VALUES ('"
    <> username
    <> "', '"
    <> hashed_password
    <> "', '"
    <> email_id
    <> "');"

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
