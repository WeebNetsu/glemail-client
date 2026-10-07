import frontend/component
import frontend/utils
import gleam/dynamic/decode
import gleam/http
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import shared/response_type

pub type MailErrors {
  UnknownError
  AuthError
  LoadingError
  FetchMessagesError
}

pub type Model {
  Model(
    error: option.Option(MailErrors),
    loading: Bool,
    mailboxes: List(response_type.Mailbox),
    mailbox_messages: response_type.GetMessagesInMailboxResponseModel,
    send_email_to: String,
    send_email_subject: String,
    send_email_message: String,
    user: option.Option(response_type.UserModel),
  )
}

pub type GetUserMailboxesResponseModel {
  GetUserMailboxesResponseModel(mailboxes: List(response_type.Mailbox))
}

pub type Message {
  LoadUserMailboxes(Result(GetUserMailboxesResponseModel, rsvp.Error(String)))
  LoadUser(Result(response_type.UserModel, rsvp.Error(String)))
  LoadUserMailboxMessages(
    Result(response_type.GetMessagesInMailboxResponseModel, rsvp.Error(String)),
  )
  RegisterUpdatedSendEmailTo(String)
  RegisterUpdatedSendEmailMessage(String)
  RegisterUpdatedSendEmailSubject(String)
  SendEmail
  SendEmailResponse(Result(response.Response(String), rsvp.Error(String)))
  UpdateSelectedMailbox(mailbox_id: String)
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

fn decode_get_user_response_model() -> decode.Decoder(response_type.UserModel) {
  use id <- decode.field("id", decode.string)
  use address <- decode.field("address", decode.string)

  decode.success(response_type.UserModel(id:, address:))
}

fn fetch_user_mailboxes() {
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
          LoadUserMailboxes,
        )
      rsvp.send(built_request, handler)
    }
    Error(_) -> {
      echo "Could not build request"
      effect.none()
    }
  }
}

fn fetch_user() {
  let req =
    utils.build_request(
      method: http.Get,
      path: "/users",
      body: "",
      include_auth: True,
    )

  case req {
    Ok(built_request) -> {
      let handler = rsvp.expect_json(decode_get_user_response_model(), LoadUser)
      rsvp.send(built_request, handler)
    }
    Error(_) -> {
      echo "Could not build request"
      effect.none()
    }
  }
}

fn fetch_user_mailbox_messages(mailbox_id: String) {
  let req =
    utils.build_request(
      method: http.Get,
      path: "/mailboxes/" <> mailbox_id <> "/messages",
      body: "",
      include_auth: True,
    )

  case req {
    Ok(built_request) -> {
      let handler =
        rsvp.expect_json(
          response_type.decode_get_messages_in_mailbox_response_model(),
          LoadUserMailboxMessages,
        )
      rsvp.send(built_request, handler)
    }
    Error(_) -> {
      echo "Could not build request"
      effect.none()
    }
  }
}

pub fn update(
  model: Model,
  message: Message,
) -> #(Model, effect.Effect(Message)) {
  case message {
    LoadUser(user) -> {
      case user {
        Ok(user) -> {
          #(
            Model(..model, user: option.Some(user), loading: False),
            effect.none(),
          )
        }
        Error(_) -> {
          #(
            Model(..model, error: option.Some(LoadingError), loading: False),
            effect.none(),
          )
        }
      }
    }
    UpdateSelectedMailbox(mailbox_id) -> {
      #(model, fetch_user_mailbox_messages(mailbox_id))
    }
    LoadUserMailboxes(data) -> {
      case data {
        Ok(mailboxes) -> {
          case mailboxes.mailboxes {
            // for testing, we're just getting sent mail, but actually this should be
            // based on the selected mailbox
            [mailbox, _, _, _, ..] -> #(
              Model(..model, mailboxes: mailboxes.mailboxes),
              fetch_user_mailbox_messages(mailbox.id),
            )
            _ -> #(
              Model(..model, mailboxes: mailboxes.mailboxes, loading: False),
              effect.none(),
            )
          }
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

          #(
            Model(..model, error: option.Some(LoadingError), loading: False),
            effect.none(),
          )
        }
      }
    }

    LoadUserMailboxMessages(data) -> {
      case data {
        Ok(mailbox_messages) -> {
          #(Model(..model, error: option.None, mailbox_messages:), fetch_user())
        }
        Error(reason) -> {
          echo reason

          #(
            Model(
              ..model,
              error: option.Some(FetchMessagesError),
              loading: False,
            ),
            effect.none(),
          )
        }
      }
    }

    RegisterUpdatedSendEmailTo(send_email_to) -> {
      #(Model(..model, error: option.None, send_email_to:), effect.none())
    }

    RegisterUpdatedSendEmailMessage(send_email_message) -> {
      #(Model(..model, error: option.None, send_email_message:), effect.none())
    }

    RegisterUpdatedSendEmailSubject(send_email_subject) -> {
      #(Model(..model, error: option.None, send_email_subject:), effect.none())
    }

    SendEmail -> {
      let req =
        utils.build_request(
          method: http.Post,
          path: "/send",
          body: json.to_string(
            json.object([
              #("to", json.string(model.send_email_to)),
              #("subject", json.string(model.send_email_subject)),
              #("text", json.string(model.send_email_message)),
            ]),
          ),
          include_auth: True,
        )

      echo "next"

      case req {
        Ok(built_request) -> {
          let handler = rsvp.expect_any_response(SendEmailResponse)

          #(model, rsvp.send(built_request, handler))
        }
        Error(_) -> {
          echo "Could not build request"
          #(model, effect.none())
        }
      }
    }

    SendEmailResponse(val) -> {
      echo val

      #(model, effect.none())
    }
  }
}

pub fn init() -> #(Model, effect.Effect(Message)) {
  #(
    Model(
      error: option.None,
      loading: False,
      mailboxes: [],
      send_email_message: "",
      send_email_to: "",
      send_email_subject: "",
      mailbox_messages: response_type.GetMessagesInMailboxResponseModel(
        success: True,
        total: 0,
        page: 0,
        previous_cursor: option.None,
        next_cursor: option.None,
        results: [],
      ),
      user: option.None,
    ),
    fetch_user_mailboxes(),
    //   effect.map(mail_page_effect, fn(a) {LoadUserMailboxes}),
  )
}

fn render_mail(
  model model: Model,
  error_message error_message: element.Element(Message),
) {
  [
    component.div(
      attributes: [
        attribute.class(
          "h-full! max-h-screen w-full flex flex-col gap-2 h-screen",
        ),
      ],
      elements: [
        component.div(
          attributes: [
            attribute.class("flex flex-row gap-2 h-full"),
          ],
          elements: [
            component.card(
              attributes: [attribute.class("w-xs")],
              elements: [
                component.div(
                  attributes: [attribute.class("flex flex-col gap-2")],
                  elements: list.map(model.mailboxes, fn(mailbox) {
                    component.button(
                      attributes: [
                        event.on_click(UpdateSelectedMailbox(mailbox.id)),
                      ],
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
              attributes: [attribute.class("w-full overflow-y-scroll")],
              elements: [
                component.div(
                  attributes: [
                    attribute.class("w-full flex flex-col gap-2"),
                  ],
                  elements: list.map(model.mailbox_messages.results, fn(msg) {
                    component.div(
                      attributes: [
                        attribute.class(
                          "w-full flex flex-col gap-1 border rounded p-2 bg-zinc-800",
                        ),
                      ],
                      elements: [
                        html.p(
                          [
                            attribute.class("font-bold"),
                          ],
                          [html.text(msg.subject)],
                        ),
                        html.p(
                          [
                            attribute.class("text-xs italic text-foreground/50"),
                          ],
                          [
                            html.text(case msg.intro {
                              option.Some(val) -> val
                              _ -> ""
                            }),
                          ],
                        ),
                      ],
                    )
                  }),
                ),
              ],
              actions: [],
              title: option.None,
            ),
          ],
        ),

        component.card(
          attributes: [],
          elements: [
            component.div(attributes: [], elements: [
              html.p([], [
                html.text(
                  "From: "
                  <> case model.user {
                    option.Some(user) -> user.address
                    option.None -> "Error Fetching User Information"
                  },
                ),
              ]),

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

              html.label([attribute.for("send-to-email-subject")], [
                html.text("Subject:"),
              ]),
              component.input([
                attribute.id("send-to-email-subject"),
                attribute.placeholder("Has my order been placed yet?"),
                attribute.value(model.send_email_subject),
                event.on_input(RegisterUpdatedSendEmailSubject),
              ]),

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
        FetchMessagesError -> {
          component.error_p(attributes: [], elements: [
            html.text("Unable to fetch mailbox messages"),
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
