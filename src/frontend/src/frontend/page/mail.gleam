import frontend/component
import gleam/list
import gleam/option
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import shared/response_type

pub type MailErrors {
  UnknownError
  AuthError
  LoadingError
}

pub type Model {
  Model(
    error: option.Option(MailErrors),
    loading: Bool,
    mailboxes: List(response_type.Mailbox),
  )
}

pub type Message

pub fn update(
  model: Model,
  message: Message,
) -> #(Model, effect.Effect(Message)) {
  #(
    Model(error: option.None, loading: False, mailboxes: [
      response_type.Mailbox(
        id: "waba",
        name: "Inbox",
        total: option.Some(55),
        unseen: option.Some(2),
      ),
      response_type.Mailbox(
        id: "waba2",
        name: "Drafts",
        total: option.Some(2),
        unseen: option.None,
      ),
    ]),
    effect.none(),
  )
}

pub fn init() -> #(Model, effect.Effect(Message)) {
  #(
    Model(error: option.None, loading: False, mailboxes: [
      response_type.Mailbox(
        id: "waba",
        name: "Inbox",
        total: option.Some(55),
        unseen: option.Some(2),
      ),
      response_type.Mailbox(
        id: "waba2",
        name: "Drafts",
        total: option.Some(2),
        unseen: option.None,
      ),
    ]),
    effect.none(),
  )
}

fn render_mail(
  model model: Model,
  error_message error_message: element.Element(Message),
) {
  [
    component.card(
      attributes: [attribute.class("h-full! max-h-screen w-full")],
      elements: [
        component.div(
          attributes: [attribute.class("flex flex-row gap-2")],
          elements: [
            component.card(
              attributes: [attribute.class("w-xs")],
              elements: [
                component.div(
                  attributes: [attribute.class("flex flex-col gap-2")],
                  elements: list.map(model.mailboxes, fn(mailbox) {
                    component.button(
                      attributes: [],
                      elements: [html.text(mailbox.name)],
                      variant: component.DefaultVariant,
                    )
                  }),
                ),
              ],
              actions: [],
              title: option.None,
            ),

            component.card(
              attributes: [attribute.class("w-full")],
              elements: [html.text("Main email stuff")],
              actions: [],
              title: option.None,
            ),
            //   html.text("Some text should come here and stuff"),
          ],
        ),
      ],
      actions: [],
      title: option.None,
    ),
  ]
}

pub fn view(model: Model) -> List(element.Element(Message)) {
  let error_message = case model.error {
    option.Some(error) -> {
      case error {
        LoadingError -> {
          component.error_p(attributes: [], elements: [
            html.text("Could not load mail data."),
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

  [
    component.div(
      attributes: [
        attribute.class("items-center h-full!"),
      ],
      elements: case model.loading {
        True -> [component.loader()]
        False -> render_mail(model: model, error_message:)
      },
    ),
  ]
}
