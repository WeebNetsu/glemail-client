import frontend/component
import frontend/config
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import shared/validation

pub type RegisterErrors {
  InvalidPassword
  InvalidUsername
  UnknownError
  CreateAccountError(String)
}

pub type Model {
  Model(
    username: String,
    password: String,
    error: option.Option(RegisterErrors),
  )
}

pub type Message {
  RegisterUpdatedUsername(String)
  RegisterUpdatedPassword(String)
  ApiCreatedNewAccount(Result(Int, rsvp.Error(String)))
  CreateNewAccount
}

fn check_input_error(
  input input: String,
  expected_error expected_error: RegisterErrors,
  validator validator: fn(String) -> Result(Nil, validation.ValidationError),
) -> option.Option(RegisterErrors) {
  case validator(input) {
    Error(err) -> {
      case err {
        validation.RegexError -> option.Some(UnknownError)
        validation.FailedRegexValidationError -> {
          option.Some(expected_error)
        }
      }
    }
    Ok(_) -> option.None
  }
}

fn handle_create_user(
  on_response handle_response: fn(Result(Int, rsvp.Error(String))) -> message,
) -> effect.Effect(message) {
  let handler = rsvp.expect_json(decode.success(1), handle_response)
  echo "started"

  let url = config.api_url <> "/users"

  rsvp.post(url, json.object([]), handler)
  //   case request.to(url) {
  //     Ok(request) -> {
  //       echo "OK HIT"

  //       //   let r =
  //       //     request
  //       //     |> request.set_method(http.Post)
  //       //     //   |> request.set_body(json.to_string(body))
  //       //     |> rsvp.send(handler)

  //     }

  //     Error(_) -> panic as { "Failed to create request to " <> url }
  //   }
}

// pub fn handle_create_user() {
//   let env = util.get_env_values()

//   case request.to(env.api_url <> "/users") {
//     Ok(req) -> {
//       // promise.try_await(fetch.send(req))
//       let req = request.set_method(req, http.Post)

//       use resp <- promise.tap(fetch.send(req))

//       case resp {
//         Ok(respp) -> {
//           let _ = case respp.status == 200 {
//             True -> echo "Request made"
//             False -> echo "Request failed"
//           }
//         }
//         Error(_) -> todo
//       }
//       // promise.tap(fetch.read_text_body(resp), fn(body) {
//       //   case body {
//       //     Ok(val) -> {
//       //       result.try(json.parse(from: val.body, using: todo))
//       //     }
//       //     Error(_) -> todo
//       //   }
//       // })
//       //   Model(..model, error: option.Some(CreateAccountError("Not implemented")))
//     }
//     Error(_) -> {
//       todo
//       //   Model(..model, error: option.Some(CreateAccountError("Not implemented")))
//     }
//   }
//   //   let _ = {
//   //     use resp <- promise.try_await(fetch.send(req))
//   //     use body <- promise.tap(fetch.read_text_body(resp))
//   //     let parsed_body = case body {
//   //       Ok(val) -> {
//   //         use res <- result.try(
//   //           json.parse(
//   //             from: val.body,
//   //             using: response_types.decode_get_mailboxes_response(),
//   //           )
//   //           |> result.map_error(fn(err) {
//   //             echo err
//   //             Ok(model)
//   //           }),
//   //         )

//   //         Ok(res)
//   //       }
//   //       _ -> Ok(model)
//   //     }

//   //     case parsed_body {
//   //       Ok(parsed) -> {
//   //         dispatch(UserFetchedMailboxes(Ok(parsed)))
//   //       }
//   //       _ -> todo
//   //     }

//   //     promise.resolve(model)
//   //   }

//   //   Model(..model, error: option.Some(CreateAccountError("Not implemented")))
// }

pub fn update(
  model: Model,
  message: Message,
) -> #(Model, effect.Effect(Message)) {
  case message {
    RegisterUpdatedUsername(username) -> {
      let cleaned_username = string.trim(string.lowercase(username))

      case model.error, string.length(cleaned_username) < 1 {
        option.Some(InvalidUsername), False -> {
          #(
            Model(
              ..model,
              username: cleaned_username,
              error: check_input_error(
                input: cleaned_username,
                expected_error: InvalidUsername,
                validator: validation.validate_username,
              ),
            ),
            effect.none(),
          )
        }
        option.None, False -> {
          #(
            Model(
              ..model,
              username: cleaned_username,
              error: check_input_error(
                input: cleaned_username,
                expected_error: InvalidUsername,
                validator: validation.validate_username,
              ),
            ),
            effect.none(),
          )
        }
        option.Some(InvalidUsername), True -> {
          #(
            Model(..model, username: cleaned_username, error: option.None),
            effect.none(),
          )
        }
        _, _ -> {
          #(Model(..model, username: cleaned_username), effect.none())
        }
      }
    }
    RegisterUpdatedPassword(password) -> {
      case model.error, string.length(password) < 1 {
        option.Some(InvalidPassword), False -> {
          #(
            Model(
              ..model,
              password:,
              error: check_input_error(
                input: password,
                expected_error: InvalidPassword,
                validator: validation.validate_password,
              ),
            ),
            effect.none(),
          )
        }
        option.None, False -> {
          #(
            Model(
              ..model,
              password:,
              error: check_input_error(
                input: password,
                expected_error: InvalidPassword,
                validator: validation.validate_password,
              ),
            ),
            effect.none(),
          )
        }
        option.Some(InvalidPassword), True -> {
          #(Model(..model, password:, error: option.None), effect.none())
        }
        _, _ -> {
          #(Model(..model, password:), effect.none())
        }
      }
    }
    ApiCreatedNewAccount(val) -> {
      echo "I WAS FINISHED"
      echo val
      #(model, effect.none())
    }
    CreateNewAccount -> {
      //   let effect =
      //     effect.from_anonymous_promise(fn(dispatch) {
      //       promise.try_await(handle_create_user(), fn(res) {
      //         // 3. Instead of returning a model here, DISPATCH the result message
      //         dispatch(UserAccountResponse(res))
      //       })
      //     })

      //   promise.try_await(handle_create_user(), fn(res) {
      #(model, handle_create_user(ApiCreatedNewAccount))
      //   })
    }
  }
}

pub fn init() -> #(Model, effect.Effect(Message)) {
  #(Model(username: "", password: "", error: option.None), effect.none())
}

pub fn view(model: Model) -> List(element.Element(Message)) {
  let error_html = case model.error {
    option.Some(error) -> {
      case error {
        InvalidPassword -> {
          component.error_p(attributes: [], elements: [
            html.text(
              "Invalid Password. Passwords should be more than 5 and less than 121 characters and contain no spaces.",
            ),
          ])
        }
        InvalidUsername -> {
          component.error_p(attributes: [], elements: [
            html.text(
              "Invalid Username. Usernames can only contain numbers and letters and must be between 7 and 24 characters.",
            ),
          ])
        }
        CreateAccountError(reason) -> {
          component.error_p(attributes: [], elements: [
            html.text("Could not create account: " <> reason),
          ])
        }
        UnknownError -> {
          component.error_p(attributes: [], elements: [
            html.text(
              "Unknown Error. An unknown error has occurred, please contact support.",
            ),
          ])
        }
      }
    }
    option.None -> element.none()
  }

  [
    component.div(
      attributes: [
        attribute.class("items-center"),
      ],
      elements: [
        component.card(
          attributes: [attribute.class("max-w-100 w-full")],
          elements: [
            component.div(attributes: [], elements: [
              component.div(
                attributes: [attribute.class("flex-row items-center")],
                elements: [
                  html.label([attribute.for("register-username-input")], [
                    html.text("Username:"),
                  ]),
                  component.input(attributes: [
                    attribute.id("register-username-input"),
                    attribute.placeholder("Username"),
                    attribute.value(model.username),
                    event.on_input(RegisterUpdatedUsername),
                  ]),
                ],
              ),

              component.div(
                attributes: [attribute.class("flex-row items-center")],
                elements: [
                  html.label([attribute.for("register-password-input")], [
                    html.text("Password:"),
                  ]),
                  component.input(attributes: [
                    attribute.id("register-password-input"),
                    attribute.type_("password"),
                    attribute.placeholder("Password"),
                    attribute.value(model.password),
                    event.on_input(RegisterUpdatedPassword),
                  ]),
                ],
              ),

              // display errors
              error_html,
            ]),
          ],
          actions: [
            component.button(
              attributes: [
                event.on_click(CreateNewAccount),
                attribute.disabled(
                  model.error != option.None
                  || string.length(model.username) < 1
                  || string.length(model.password) < 1,
                ),
              ],
              elements: [html.text("Create Account")],
              variant: component.DefaultVariant,
            ),
          ],
          title: option.Some("Create Account"),
        ),
      ],
    ),
  ]
}
