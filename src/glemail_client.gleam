import dot_env
import dot_env/env
import gleam/int
import gleam/io
import gleam/list
import lustre
import lustre/attribute
import lustre/element/html
import lustre/event

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

fn init(_flags) {
  0
}

type Message {
  Incr
  Decr
}

fn update(model, message) {
  case message {
    Incr -> model + 1
    Decr -> model - 1
  }
}

fn view(model) {
  let count = int.to_string(model)

  html.div([], [
    html.button([event.on_click(Incr)], [html.text(" + ")]),
    html.p([], [html.text(count)]),
    html.button([event.on_click(Decr)], [html.text(" - ")]),
  ])
}

pub fn main() {
  let app =
    lustre.element(
      html.div([], [
        html.h1([], [html.text("Hello, world!")]),
        html.figure([], [
          html.img([attribute.src("https://cdn2.thecatapi.com/images/b7k.jpg")]),
          html.figcaption([], [html.text("A cat!")]),
        ]),
      ]),
    )
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
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
  //           promise.resolve(Ok(Nil))
  //         }
  //       }
  //     }
  //     False -> {
  //       io.println_error("Could not load some ENV variables")
  //       promise.resolve(Ok(Nil))
  //     }
  //   }
}
