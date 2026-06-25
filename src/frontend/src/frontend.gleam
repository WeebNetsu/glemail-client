import frontend/components
import gleam/int
import lustre
import lustre/attribute
import lustre/element/html
import lustre/event
import shared

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

  components.div(
    [
      attribute.class(
        "dark bg-gray-700 min-w-screen w-full min-h-screen h-full p-1 text-slate-100",
      ),
    ],
    [
      components.div([], [
        html.p([attribute.class("text-xl font-bold")], [
          html.text(shared.site_name),
        ]),
        components.div([attribute.class("flex-row")], [
          components.button(
            attributes: [
              event.on_click(Incr),
            ],
            elements: [
              html.p(
                [
                  attribute.class("text-red-200"),
                ],
                [
                  html.text(" + "),
                ],
              ),
            ],
            variant: "destructive",
          ),
          html.text(count),
          components.button(
            elements: [html.text(" - ")],
            variant: "default",
            attributes: [
              event.on_click(Decr),
            ],
          ),
        ]),
      ]),
    ],
  )
}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
