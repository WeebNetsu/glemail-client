import backend/routes
import backend/utils
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/io
import gleam/list
import mist
import wisp
import wisp/wisp_mist

/// Load initial important env files, false if failed
pub fn load_env() -> Bool {
  dot_env.new()
  |> dot_env.set_path("./.env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  list.map(["API_URL", "ACCESS_TOKEN", "USER_ID", "SECRET_KEY"], fn(var) {
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

// pub fn main_orig() {
//   case load_env() {
//     True -> {
//       case argv.load().arguments {
//         [mailbox_name, "list", count, "on", "page", page]
//         | [mailbox_name, count, page] -> {
//           display.messages_in_mailbox(
//             mailbox_name,
//             result.unwrap(int.parse(count), 0),
//             result.unwrap(int.parse(page), 0),
//           )
//         }
//         ["mailboxes", "list"] -> {
//           display.list_mailboxes()
//         }
//         _ -> {
//           io.println("Invalid arguments")
//           Ok(Nil)
//         }
//       }
//     }
//     False -> {
//       io.println_error("Could not load some ENV variables")
//       Ok(Nil)
//     }
//   }
// }

pub fn main() {
  // can't continue without important env!
  assert load_env() == True
  let env_values = utils.get_env_values()

  // This sets the logger to print INFO level logs, and other sensible defaults
  // for a web application.
  wisp.configure_logger()

  // Start the Mist web server.
  let assert Ok(_) =
    wisp_mist.handler(routes.handle_request, env_values.secret_key)
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  process.sleep_forever()
}
