import frontend/component
import frontend/cookies
import frontend/ffi
import frontend/utils
import gleam/http
import gleam/json
import gleam/option
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import shared/response_type
import shared/validation

pub type LoginErrors {
  InvalidPassword
  InvalidUsername
  UnknownError
  LoginError(String)
  AuthError
}

pub type Model {
  Model(
    username: String,
    password: String,
    error: option.Option(LoginErrors),
    success: Bool,
    loading: Bool,
  )
}

pub type Message {
  LoginUpdatedUsername(String)
  LoginUpdatedPassword(String)
  ApiLoginAccount(
    Result(response_type.UserLoginResponseBody, rsvp.Error(String)),
  )
  LoginAccount
}

fn check_input_error(
  input input: String,
  expected_error expected_error: LoginErrors,
  validator validator: fn(String) -> Result(Nil, validation.ValidationError),
) -> option.Option(LoginErrors) {
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

pub fn update(
  model: Model,
  message: Message,
) -> #(Model, effect.Effect(Message)) {
  case message {
    LoginUpdatedUsername(username) -> {
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
    LoginUpdatedPassword(password) -> {
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
    ApiLoginAccount(val) -> {
      case val {
        Ok(res) -> {
          ffi.set_cookie(
            key: cookies.get_cookie_name(cookies.JwtAccessToken),
            value: res.jwt,
            expiry_date: "",
          )

          #(
            Model(..model, error: option.None, success: True, loading: False),
            effect.none(),
          )
        }
        Error(rsvp.HttpError(err)) -> {
          case json.parse(err.body, response_type.decode_error_body()) {
            Ok(err) -> {
              #(
                Model(
                  ..model,
                  error: option.Some(LoginError(err.reason)),
                  loading: False,
                ),
                effect.none(),
              )
            }
            Error(_) -> {
              #(
                Model(
                  ..model,
                  error: option.Some(LoginError("Invalid response received")),
                  loading: False,
                ),
                effect.none(),
              )
            }
          }
        }
        _ -> {
          #(
            Model(
              ..model,
              error: option.Some(LoginError("Unknown response received")),
              loading: False,
            ),
            effect.none(),
          )
        }
      }
    }
    LoginAccount -> {
      let req =
        utils.build_request(
          method: http.Post,
          path: "/users/login",
          body: json.to_string(
            json.object([
              #("username", json.string(model.username)),
              #("password", json.string(model.password)),
            ]),
          ),
          include_auth: False,
        )

      case req {
        Ok(built_request) -> {
          let handler =
            rsvp.expect_json(
              response_type.decode_login_success_response_body(),
              ApiLoginAccount,
            )

          #(
            Model(..model, error: option.None, success: False, loading: True),
            rsvp.send(built_request, handler),
            // rsvp.post(
          //   config.api_url <> "/users/login",
          // json.object([
          //   #("username", json.string(model.username)),
          //   #("password", json.string(model.password)),
          // ]),
          //   rsvp.expect_json(
          //     response_type.decode_login_success_response_body(),
          //     ApiLoginAccount,
          //   ),
          // ),
          )
        }
        Error(_) -> {
          // this should never happen really, since include_auth is false, but just in case
          #(
            Model(
              ..model,
              error: option.Some(AuthError),
              success: False,
              loading: False,
            ),
            effect.none(),
          )
        }
      }
    }
  }
}

pub fn init() -> #(Model, effect.Effect(Message)) {
  #(
    Model(
      username: "",
      password: "",
      error: option.None,
      success: False,
      loading: False,
    ),
    effect.none(),
  )
}

fn render_login(
  model model: Model,
  success_message success_message: element.Element(Message),
  error_message error_message: element.Element(Message),
) {
  [
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
                event.on_input(LoginUpdatedUsername),
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
                event.on_input(LoginUpdatedPassword),
              ]),
            ],
          ),

          success_message,
          error_message,
        ]),
      ],
      actions: [
        component.button(
          attributes: [
            event.on_click(LoginAccount),
            attribute.disabled(
              string.length(model.username) < 1
              || string.length(model.password) < 1,
            ),
          ],
          elements: [html.text("Login")],
          variant: component.DefaultVariant,
        ),
      ],
      title: option.Some("Login"),
    ),
  ]
}

pub fn view(model: Model) -> List(element.Element(Message)) {
  let error_message = case model.error {
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
        LoginError(reason) -> {
          component.error_p(attributes: [], elements: [
            html.text("Could not login to account: " <> reason),
          ])
        }
        UnknownError -> {
          component.error_p(attributes: [], elements: [
            html.text(
              "Unknown Error. An unknown error has occurred, please contact support.",
            ),
          ])
        }
        AuthError -> {
          component.error_p(attributes: [], elements: [
            html.text("Unable to authenticate requests"),
          ])
        }
      }
    }
    option.None -> element.none()
  }

  // later we'll probably just redirect instead of showing a message
  let success_message = case model.success {
    True ->
      component.success_p(attributes: [], elements: [
        html.text("Login Success!"),
      ])
    False -> element.none()
  }

  [
    component.div(
      attributes: [
        attribute.class("items-center"),
      ],
      elements: case model.loading {
        True -> [component.loader()]
        False -> render_login(model: model, success_message:, error_message:)
      },
    ),
  ]
}
