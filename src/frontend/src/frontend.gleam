import frontend/components
import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/result
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import shared/response_types

pub type Msg {
  UserFetchedMailboxes(
    Result(response_types.GetMailboxesResponse, fetch.FetchError),
  )
}

fn init(_flags) -> #(response_types.GetMailboxesResponse, effect.Effect(Msg)) {
  let model = response_types.GetMailboxesResponse(mailboxes: [])

  let assert Ok(req) = request.to("http://localhost:8080/mailboxes")

  let fetch_effect =
    effect.from(fn(dispatch) {
      let _ = {
        use resp <- promise.try_await(fetch.send(req))
        use body <- promise.tap(fetch.read_text_body(resp))
        let parsed_body = case body {
          Ok(val) -> {
            use res <- result.try(
              json.parse(
                from: val.body,
                using: response_types.decode_get_mailboxes_response(),
              )
              |> result.map_error(fn(err) {
                echo err
                Ok(model)
              }),
            )

            Ok(res)
          }
          _ -> Ok(model)
        }

        case parsed_body {
          Ok(parsed) -> {
            dispatch(UserFetchedMailboxes(Ok(parsed)))
          }
          _ -> todo
        }

        promise.resolve(model)
      }

      Nil
    })

  #(model, fetch_effect)
}

fn update(
  model: response_types.GetMailboxesResponse,
  msg: Msg,
) -> #(response_types.GetMailboxesResponse, effect.Effect(Msg)) {
  case msg {
    UserFetchedMailboxes(Ok(json_string)) -> {
      // Do something with your JSON here!
      #(json_string, effect.none())
    }
    UserFetchedMailboxes(Error(_err)) -> {
      // Handle your error state here
      #(model, effect.none())
    }
  }
}

fn view(model: response_types.GetMailboxesResponse) -> element.Element(Msg) {
  components.div(
    [
      attribute.class(
        "dark bg-gray-700 min-w-screen w-full min-h-screen h-full p-1 text-slate-100",
      ),
    ],
    list.map(model.mailboxes, fn(mailbox) {
      components.div([], [html.p([], [html.text(mailbox.name)])])
    }),
    // [

  //   components.div([], [
  //     html.p([attribute.class("text-xl font-bold")], [
  //       html.text(shared.site_name),
  //     ]),
  //     components.div([attribute.class("flex-row")], [
  //       components.button(
  //         attributes: [
  //           //   event.on_click(Incr),
  //         ],
  //         elements: [
  //           html.p(
  //             [
  //               attribute.class("text-red-200"),
  //             ],
  //             [
  //               html.text(" + "),
  //             ],
  //           ),
  //         ],
  //         variant: "destructive",
  //       ),
  //       //   html.text(count),
  //       components.button(
  //         elements: [html.text(" - ")],
  //         variant: "default",
  //         attributes: [
  //           //   event.on_click(Decr),
  //         ],
  //       ),
  //     ]),
  //   ]),
  // ],
  )
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
