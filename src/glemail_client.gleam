import argv
import dot_env
import dot_env/env
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import glemail_client/display

/// Load initial important env files, false if failed
pub fn load_env() -> Bool {
  dot_env.new()
  |> dot_env.set_path("./.env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  list.map(["API_URL", "ACCESS_TOKEN", "USER_ID"], fn(var) {
    case env.get_string(var) {
      Ok(_) -> True
      Error(err) -> {
        io.println_error("something went wrong: " <> err)
        False
      }
    }
  })
  |> list.all(fn(val) { val == True })
}

pub fn main() {
  case load_env() {
    True -> {
      case argv.load().arguments {
        [mailbox_name, "list", count, "on", "page", page]
        | [mailbox_name, count, page] -> {
          display.messages_in_mailbox(
            mailbox_name,
            result.unwrap(int.parse(count), 0),
            result.unwrap(int.parse(page), 0),
          )
        }
        ["mailboxes", "list"] -> {
          display.list_mailboxes()
        }
        _ -> {
          io.println("Invalid arguments")
          Ok(Nil)
        }
      }
    }
    False -> {
      io.println_error("Could not load some ENV variables")
      Ok(Nil)
    }
  }
}
