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
      include_auth: False,
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
        Error(_) -> {
          #(Model(..model, error: option.Some(LoadingError)), effect.none())
        }
      }
    }

    InitialDataLoad -> {
      let req =
        utils.build_request(
          method: http.Get,
          path: "/mailboxes",
          body: "",
          include_auth: False,
        )

      case req {
        Ok(built_request) -> {
          let handler =
            rsvp.expect_json(
              decode_get_user_mailboxes_response_model(),
              ApiInitialDataLoad,
            )

          #(
            Model(..model, error: option.None, loading: True),
            rsvp.send(built_request, handler),
          )
        }
        Error(_) -> {
          #(
            Model(..model, error: option.Some(AuthError), loading: False),
            effect.none(),
          )
        }
      }
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
