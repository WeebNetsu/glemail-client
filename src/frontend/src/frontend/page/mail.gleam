import frontend/component
import frontend/utils
import gleam/dynamic/decode
import gleam/http
import gleam/list
import gleam/option
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import rsvp
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

pub type GetUserMailboxesResponseModel {
  GetUserMailboxesResponseModel(mailboxes: List(response_type.Mailbox))
}

pub type Message {
  InitialDataLoad
  ApiInitialDataLoad(Result(GetUserMailboxesResponseModel, rsvp.Error(String)))
}

fn decode_mailbox_model() -> decode.Decoder(response_type.Mailbox) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use total <- decode.optional_field(
    "total",
    option.None,
    decode.optional(decode.int),
  )
  use unseen <- decode.optional_field(
    "unseen",
    option.None,
    decode.optional(decode.int),
  )

  decode.success(response_type.Mailbox(id:, name:, total:, unseen:))
}

fn decode_get_user_mailboxes_response_model() -> decode.Decoder(
  GetUserMailboxesResponseModel,
) {
  use mailboxes <- decode.field(
    "mailboxes",
    decode.list(decode_mailbox_model()),
  )

  decode.success(GetUserMailboxesResponseModel(mailboxes:))
}

fn initial_data_fetch() {
  let req =
    utils.build_request(
      method: http.Get,
      path: "/mailboxes",
      body: "",
      include_auth: True,
    )

  case req {
    Ok(built_request) -> {
      let handler =
        rsvp.expect_json(
          decode_get_user_mailboxes_response_model(),
          ApiInitialDataLoad,
        )
      rsvp.send(built_request, handler)
    }
    Error(_) -> {
      effect.none()
    }
  }
}

pub fn update(
  model: Model,
  message: Message,
) -> #(Model, effect.Effect(Message)) {
  case message {
    ApiInitialDataLoad(data) -> {
      case data {
        Ok(mailboxes) -> {
          #(Model(..model, mailboxes: mailboxes.mailboxes), effect.none())
        }
        Error(error) -> {
          //   case error {
          //     rsvp.HttpError(resp) -> {
          //       case resp.status {
          //         401 -> todo
          //         _ -> todo
          //       }
          //       Nil
          //     }
          //     _ -> {
          //       Nil
          //     }
          //   }

          #(Model(..model, error: option.Some(LoadingError)), effect.none())
        }
      }
    }

    InitialDataLoad -> {
      #(Model(..model, error: option.None, loading: True), initial_data_fetch())
    }
  }
}

pub fn init() -> #(Model, effect.Effect(Message)) {
  #(
    Model(error: option.None, loading: False, mailboxes: []),
    initial_data_fetch(),
    //   effect.map(mail_page_effect, fn(a) {InitialDataLoad}),
  )
}

fn render_mail(
  model model: Model,
  error_message error_message: element.Element(Message),
) {
  [
    component.div(
      attributes: [
        attribute.class("h-full! max-h-screen w-full flex flex-col gap-2"),
      ],
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
          ],
        ),

        component.card(
          attributes: [],
          elements: [
            component.div(attributes: [], elements: [
              component.div(
                attributes: [
                  attribute.class("flex gap-2 flex-row items-center"),
                ],
                elements: [
                  html.label([attribute.for("sent-to-email-input")], [
                    html.text("To:"),
                  ]),
                  component.input(attributes: [
                    attribute.id("sent-to-email-input"),
                    attribute.placeholder("jack@gmail.com"),
                    attribute.value(model.send_email_to),
                    event.on_input(RegisterUpdatedSendEmailTo),
                  ]),
                ],
              ),

              html.label([attribute.for("send-to-email-message")], [
                html.text("Message:"),
              ]),
              component.textarea([
                attribute.id("send-to-email-message"),
                attribute.placeholder(
                  "Hi,\n\nI would like to ask assistance on...",
                ),
                attribute.value(model.send_email_message),
                event.on_input(RegisterUpdatedSendEmailMessage),
              ]),

              component.div(
                attributes: [
                  attribute.class("flex w-full items-end"),
          ],
                elements: [
                  component.button(
                    attributes: [
                      attribute.class("w-3xs"),
                      event.on_click(SendEmail),
      ],
                    elements: [
                      html.text("Send Email"),
                    ],
                    variant: component.DefaultVariant,
                  ),
                ],
              ),
            ]),
          ],
          actions: [],
          title: option.Some("Send Email"),
        ),
      ],
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
