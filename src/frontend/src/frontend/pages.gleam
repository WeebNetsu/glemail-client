import frontend/components
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event

// MARK: Models
pub type RegisterModel {
  RegisterModel(username: String, password: String)
}

// MARK: Updates

pub type RegisterMessage {
  RegisterUpdatedUsername(String)
  RegisterUpdatedPassword(String)
}

pub fn register_update(
  model: RegisterModel,
  message: RegisterMessage,
) -> RegisterModel {
  case message {
    RegisterUpdatedUsername(username) -> {
      RegisterModel(username:, password: model.password)
    }
    RegisterUpdatedPassword(password) -> {
      RegisterModel(username: model.username, password:)
    }
  }
}

pub fn init_register() {
  RegisterModel(username: "", password: "")
}

// MARK: Views
pub fn view_register(
  model: RegisterModel,
) -> List(element.Element(RegisterMessage)) {
  [
    components.div(
      attributes: [
        attribute.class("items-center"),
      ],
      elements: [
        html.p([attribute.class("text-xl font-bold")], [
          html.text("Create Account"),
        ]),

        components.card(
          attributes: [attribute.class("max-w-100")],
          elements: [
            components.div(attributes: [], elements: [
              components.div(
                attributes: [attribute.class("flex-row items-center")],
                elements: [
                  html.label([attribute.for("register-username-input")], [
                    html.text("Username:"),
                  ]),
                  components.input(attributes: [
                    attribute.id("register-username-input"),
                    attribute.placeholder("Username"),
                    attribute.value(model.username),
                    event.on_input(RegisterUpdatedUsername),
                  ]),
                ],
              ),

              components.div(
                attributes: [attribute.class("flex-row items-center")],
                elements: [
                  html.label([attribute.for("register-password-input")], [
                    html.text("Password:"),
                  ]),
                  components.input(attributes: [
                    attribute.id("register-password-input"),
                    attribute.type_("password"),
                    attribute.placeholder("Password"),
                    attribute.value(model.password),
                    event.on_input(RegisterUpdatedPassword),
                  ]),
                ],
              ),
            ]),
          ],
          actions: [
            components.button(
              attributes: [],
              elements: [html.text("Create Account")],
              variant: components.DefaultVariant,
            ),
          ],
          title: option.None,
        ),
      ],
    ),
  ]
}

pub fn view_not_found() -> List(element.Element(a)) {
  [components.div(attributes: [], elements: [html.text("Not Found")])]
}
// fn href(route: Route) -> attribute.Attribute(message) {
//   let url = case route {
//     Index -> "/"
//     // PostById(post_id) -> "/post/" <> int.to_string(post_id)
//     NotFound(_) -> "/404"
//   }

//   attribute.href(url)
// }

// fn init(_flags) -> #(response_types.GetMailboxesResponse, effect.Effect(Msg)) {
//   let route = case modem.initial_uri() {
//     Ok(uri) -> parse_route(uri)
//     Error(_) -> Index
//   }

//   let model = response_types.GetMailboxesResponse(mailboxes: [])

//   let assert Ok(req) = request.to("http://localhost:8080/mailboxes")

//   let fetch_effect =
//     effect.from(fn(dispatch) {
//       let _ = {
//         use resp <- promise.try_await(fetch.send(req))
//         use body <- promise.tap(fetch.read_text_body(resp))
//         let parsed_body = case body {
//           Ok(val) -> {
//             use res <- result.try(
//               json.parse(
//                 from: val.body,
//                 using: response_types.decode_get_mailboxes_response(),
//               )
//               |> result.map_error(fn(err) {
//                 echo err
//                 Ok(model)
//               }),
//             )

//             Ok(res)
//           }
//           _ -> Ok(model)
//         }

//         case parsed_body {
//           Ok(parsed) -> {
//             dispatch(UserFetchedMailboxes(Ok(parsed)))
//           }
//           _ -> todo
//         }

//         promise.resolve(model)
//       }

//       Nil
//     })

//   #(model, fetch_effect)
// }

// fn update(
//   model: response_types.GetMailboxesResponse,
//   msg: Msg,
// ) -> #(response_types.GetMailboxesResponse, effect.Effect(Msg)) {
//   case msg {
//     UserFetchedMailboxes(Ok(json_string)) -> {
//       // Do something with your JSON here!
//       #(json_string, effect.none())
//     }
//     UserFetchedMailboxes(Error(_err)) -> {
//       // Handle your error state here
//       #(model, effect.none())
//     }
//   }
// }

// fn view(model: Model) {
//   components.div(
//     [
//   attribute.class(
//     "dark bg-gray-700 min-w-screen w-full min-h-screen h-full p-1 text-slate-100",
//   ),
//     ],
//     [
//       components.input(attributes: []),
//       //   components.input([]),
//     //   ..list.map(model.mailboxes, fn(mailbox) {
//     //     components.div([], [html.p([], [html.text(mailbox.name)])])
//     //   })
//     ],
//     // [

//   //   components.div([], [
//   //     html.p([attribute.class("text-xl font-bold")], [
//   //       html.text(shared.site_name),
//   //     ]),
//   //     components.div([attribute.class("flex-row")], [
//   //       components.button(
//   //         attributes: [
//   //           //   event.on_click(Incr),
//   //         ],
//   //         elements: [
//   //           html.p(
//   //             [
//   //               attribute.class("text-red-200"),
//   //             ],
//   //             [
//   //               html.text(" + "),
//   //             ],
//   //           ),
//   //         ],
//   //         variant: "destructive",
//   //       ),
//   //       //   html.text(count),
//   //       components.button(
//   //         elements: [html.text(" - ")],
//   //         variant: "default",
//   //         attributes: [
//   //           //   event.on_click(Decr),
//   //         ],
//   //       ),
//   //     ]),
//   //   ]),
//   // ],
//   )
// }
