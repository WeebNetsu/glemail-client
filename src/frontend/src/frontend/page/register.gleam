import frontend/component
import gleam/option
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import shared/validation

pub type RegisterErrors {
  InvalidPassword
  InvalidUsername
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
  CreateNewAccount
}

pub fn update(model: Model, message: Message) -> Model {
  case message {
    RegisterUpdatedUsername(username) -> {
      let cleaned_username = string.trim(string.lowercase(username))

      // don't display an error if the input is empty
      let error = case string.length(cleaned_username) < 1 {
        True -> option.None
        False -> {
          case validation.validate_username(cleaned_username) {
            Error(_) -> {
              option.Some(InvalidUsername)
            }
            Ok(_) -> option.None
          }
        }
      }

      Model(..model, username: cleaned_username, error: error)
    }
    RegisterUpdatedPassword(password) -> {
      Model(..model, password:, error: option.None)
    }
    CreateNewAccount -> {
      todo
    }
  }
}

pub fn init() {
  Model(username: "", password: "", error: option.None)
}

pub fn view(model: Model) -> List(element.Element(Message)) {
  let error_html = case model.error {
    option.Some(error) -> {
      case error {
        InvalidPassword -> {
          component.error_p(attributes: [], elements: [
            html.text("Invalid Password."),
          ])
        }
        InvalidUsername -> {
          component.error_p(attributes: [], elements: [
            html.text(
              "Invalid Username. Usernames can only contain numbers and letters and must be between 7 and 24 characters.",
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
        html.p([attribute.class("text-xl font-bold")], [
          html.text("Create Account"),
        ]),

        component.card(
          attributes: [attribute.class("max-w-100")],
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
              attributes: [event.on_click(CreateNewAccount)],
              elements: [html.text("Create Account")],
              variant: component.DefaultVariant,
            ),
          ],
          title: option.None,
        ),
      ],
    ),
  ]
}
