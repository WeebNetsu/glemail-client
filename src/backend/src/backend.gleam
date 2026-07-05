import backend/db
import backend/route
import backend/util
import dot_env
import gleam/erlang/process
import gleam/io
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  dot_env.new()
  |> dot_env.set_path("./.env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  // will panic if not all important env values are provided 
  let env_values = util.get_env_values()

  case db.create_db() {
    Ok(_) -> {
      // This sets the logger to print INFO level logs, and other sensible defaults
      // for a web application.
      wisp.configure_logger()

      // Start the Mist web server.
      let assert Ok(_) =
        wisp_mist.handler(route.handle_request, env_values.secret_key)
        |> mist.new
        |> mist.port(8080)
        |> mist.start

      // The web server runs in new Erlang process, so put this one to sleep while
      // it works concurrently.
      process.sleep_forever()
    }
    Error(err) -> {
      io.print_error("Could not initialize database: " <> err.message)
      panic
    }
  }
}
