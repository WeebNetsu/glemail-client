import frontend/component
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event

pub type Model {
  Model(username: String, password: String)
}

pub type Message {
  RegisterUpdatedUsername(String)
  RegisterUpdatedPassword(String)
}

pub fn update(model: Model, message: Message) -> Model {
  case message {
    RegisterUpdatedUsername(username) -> {
      Model(username:, password: model.password)
    }
    RegisterUpdatedPassword(password) -> {
      Model(username: model.username, password:)
    }
  }
}

pub fn init() {
  Model(username: "", password: "")
}

pub fn view(model: Model) -> List(element.Element(Message)) {
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
            ]),
          ],
          actions: [
            component.button(
              attributes: [],
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
