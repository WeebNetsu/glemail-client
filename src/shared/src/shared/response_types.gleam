import gleam/dynamic/decode
import gleam/json
import gleam/option

// MARK: Types
pub type Mailbox {
  Mailbox(
    id: String,
    name: String,
    total: option.Option(Int),
    unseen: option.Option(Int),
  )
}

pub type GetMailboxesResponse {
  GetMailboxesResponse(mailboxes: List(Mailbox))
}

pub type CreateUserBody {
  CreateUserBody(username: String, password: String)
}

// MARK: Encode/Decode
pub fn encode_mailbox_to_json(mailbox: Mailbox) -> json.Json {
  json.object([
    #("id", json.string(mailbox.id)),
    #("name", json.string(mailbox.name)),
    ..case mailbox.total, mailbox.unseen {
      option.Some(total), option.Some(unseen) -> {
        [#("total", json.int(total)), #("unseen", json.int(unseen))]
      }
      option.None, option.Some(unseen) -> {
        [#("unseen", json.int(unseen))]
      }
      option.Some(total), option.None -> {
        [
          #("total", json.int(total)),
        ]
      }
      option.None, option.None -> []
    }
  ])
}

pub fn decode_mailbox() -> decode.Decoder(Mailbox) {
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

  decode.success(Mailbox(id:, name:, total:, unseen:))
}

pub fn encode_get_mailboxes_response_to_json(
  mailboxes_response: GetMailboxesResponse,
) -> json.Json {
  json.object([
    #(
      "mailboxes",
      json.array(mailboxes_response.mailboxes, encode_mailbox_to_json),
    ),
  ])
}

pub fn decode_get_mailboxes_response() -> decode.Decoder(GetMailboxesResponse) {
  use mailboxes <- decode.field("mailboxes", decode.list(decode_mailbox()))

  decode.success(GetMailboxesResponse(mailboxes:))
}

pub fn encode_create_user_body_to_json(body: CreateUserBody) -> json.Json {
  json.object([
    #("username", json.string(body.username)),
    #("password", json.string(body.password)),
  ])
}

pub fn decode_create_user_body() -> decode.Decoder(CreateUserBody) {
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)

  decode.success(CreateUserBody(username:, password:))
}
