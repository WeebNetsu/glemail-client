import frontend/page/not_found
import frontend/page/register
import gleam/fetch
import gleam/uri
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import shared/response_types

// Modem is a package providing effects and functionality for routing in SPAs.
// This means instead of links taking you to a new page and reloading everything,
// they are intercepted and your `update` function gets told about the new URL.
import modem

type Route {
  Index
  NotFound(link: uri.Uri)
}

type Model {
  Model(route: Route, register_page: register.Model)
}

type Message {
  UserNavigatedTo(route: Route)
  RegisterMsg(register.Message)
}

fn parse_route(link: uri.Uri) -> Route {
  case uri.path_segments(link.path) {
    [] | [""] -> Index

    // ["post", post_id] ->
    //   case int.parse(post_id) {
    //     Ok(post_id) -> PostById(id: post_id)
    //     Error(_) -> NotFound(link:)
    //   }
    _ -> NotFound(link:)
  }
}

pub type Msg {
  UserFetchedMailboxes(
    Result(response_types.GetMailboxesResponse, fetch.FetchError),
  )
}

fn init(_flags) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Index
  }

  let model = Model(route:, register_page: register.init())

  let effect =
    modem.init(fn(uri) {
      uri
      |> parse_route
      |> UserNavigatedTo
    })

  #(model, effect)
}

fn update(model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    UserNavigatedTo(route:) -> #(Model(..model, route:), effect.none())
    RegisterMsg(register_message) -> {
      let updated_register =
        register.update(model.register_page, register_message)

      #(Model(..model, register_page: updated_register), effect.none())
    }
  }
}

fn view(model: Model) -> element.Element(Message) {
  html.main(
    [
      attribute.class(
        "dark bg-gray-700 min-w-screen w-full min-h-screen h-full p-1 text-slate-100",
      ),
    ],
    [
      case model.route {
        Index -> {
          html.div([], register.view(model.register_page))
          |> element.map(RegisterMsg)
        }
        // Posts -> view_posts(model)
        // PostById(post_id) -> view_post(model, post_id)
        // About -> view_about()
        NotFound(_) -> html.div([], not_found.view())
      },
    ],
  )
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
