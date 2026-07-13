import frontend/component
import frontend/config
import frontend/utils
import gleam/json
import gleam/option
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import modem
import rsvp
import shared/response_type
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
    success: Bool,
    loading: Bool,
  )
}

pub type Message {
  RegisterUpdatedUsername(String)
  RegisterUpdatedPassword(String)
  ApiCreatedNewAccount(Result(String, rsvp.Error(String)))
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
      case val {
        Ok(_) -> {
          #(
            Model(..model, error: option.None, success: True, loading: False),
            modem.push(
              utils.get_route_path(utils.MailRoute),
              option.None,
              option.None,
            ),
          )
        }
        Error(rsvp.HttpError(err)) -> {
          case json.parse(err.body, response_type.decode_error_body()) {
            Ok(err) -> {
              #(
                Model(
                  ..model,
                  error: option.Some(CreateAccountError(err.reason)),
                  loading: False,
                ),
                effect.none(),
              )
            }
            Error(_) -> {
              #(
                Model(
                  ..model,
                  error: option.Some(CreateAccountError(
                    "Invalid response received",
                  )),
                  loading: False,
                ),
                effect.none(),
              )
            }
          }
        }
        _ -> {
          echo val

          #(
            Model(
              ..model,
              error: option.Some(CreateAccountError("Unknown response received")),
              loading: False,
            ),
            effect.none(),
          )
        }
      }
    }
    CreateNewAccount -> {
      #(
        Model(..model, error: option.None, success: False, loading: True),
        rsvp.post(
          config.api.url <> "/users",
          json.object([
            #("username", json.string(model.username)),
            #("password", json.string(model.password)),
          ]),
          rsvp.expect_text(ApiCreatedNewAccount),
        ),
      )
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

fn render_register(
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

          success_message,
          error_message,
        ]),
      ],
      actions: [
        component.button(
          attributes: [
            event.on_click(CreateNewAccount),
            attribute.disabled(
              string.length(model.username) < 1
              || string.length(model.password) < 1,
            ),
          ],
          elements: [html.text("Create Account")],
          variant: component.DefaultVariant,
        ),
      ],
      title: option.Some("Create Account"),
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

  // later we'll probably just redirect instead of showing a message
  let success_message = case model.success {
    True ->
      component.success_p(attributes: [], elements: [
        html.text("Account Created!"),
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
        False -> render_register(model: model, success_message:, error_message:)
      },
    ),
  ]
}
