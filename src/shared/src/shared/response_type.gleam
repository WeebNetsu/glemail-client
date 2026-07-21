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

pub type UserLoginBody {
  UserLoginBody(username: String, password: String)
}

pub type UserLoginResponseBody {
  UserLoginResponseBody(jwt: String)
}

pub type ErrorBody {
  ErrorBody(reason: String)
}

pub type GetMessagesInMailboxResponseModel {
  GetMessagesInMailboxResponseModel(
    success: Bool,
    total: Int,
    page: Int,
    previous_cursor: option.Option(String),
    next_cursor: option.Option(String),
    results: List(MessageInMailboxModel),
  )
}

pub type MessageInMailboxModel {
  MessageInMailboxModel(
    id: Int,
    mailbox: String,
    thread: String,
    thread_message_count: option.Option(Int),
    from: FromToModel,
    to: List(FromToModel),
    cc: List(FromToModel),
    bcc: List(FromToModel),
    subject: String,
    date: String,
    idate: option.Option(String),
    size: Int,
    draft: option.Option(Bool),
    intro: option.Option(String),
    attachments: Bool,
    seen: Bool,
    deleted: Bool,
    flagged: Bool,
    answered: Bool,
    forwarded: Bool,
    // content_type: ContentTypeModel,
    // meta_data: option.Option(decode.Dynamic),
    message_id: String,
    references: List(String),
  )
}

// pub type ContentTypeModel {
//   ContentTypeModel(value: String, params: .Dynamic)
// }

pub type FromToModel {
  FromToModel(name: option.Option(String), address: String)
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

pub fn encode_from_to_model(data: FromToModel) -> json.Json {
  json.object([
    #("address", json.string(data.address)),
    #("name", json.nullable(data.name, of: json.string)),
  ])
}

pub fn decode_get_mailboxes_message_response() -> decode.Decoder(
  GetMailboxesResponse,
) {
  use mailboxes <- decode.field("mailboxes", decode.list(decode_mailbox()))

  decode.success(GetMailboxesResponse(mailboxes:))
}

pub fn encode_get_mailboxes_message_response_to_json(
  message: MessageInMailboxModel,
) -> json.Json {
  json.object([
    #("id", json.int(message.id)),
    #("bcc", json.array(message.bcc, encode_from_to_model)),
    #("cc", json.array(message.cc, encode_from_to_model)),
    #("date", json.string(message.date)),
    #("draft", json.nullable(message.draft, json.bool)),
    #("from", encode_from_to_model(message.from)),
    #("intro", json.nullable(message.intro, json.string)),
    #("mailbox", json.string(message.mailbox)),
    #("messageId", json.string(message.message_id)),
    #("subject", json.string(message.subject)),
    #("to", json.array(message.to, encode_from_to_model)),
    #("thread", json.string(message.thread)),
    #("attachments", json.bool(message.attachments)),
    #("seen", json.bool(message.seen)),
    #("deleted", json.bool(message.deleted)),
    #("flagged", json.bool(message.flagged)),
    #("answered", json.bool(message.answered)),
    #("forwarded", json.bool(message.forwarded)),
    #(
      "threadMessageCount",
      json.nullable(message.thread_message_count, json.int),
    ),
    #("idate", json.nullable(message.idate, json.string)),
    #("size", json.int(message.size)),
    #("references", json.array(message.references, json.string)),
  ])
}

pub fn encode_get_mailboxes_messages_response_to_json(
  mailboxes_response: GetMessagesInMailboxResponseModel,
) -> json.Json {
  json.object([
    #("success", json.bool(mailboxes_response.success)),
    #("page", json.int(mailboxes_response.page)),
    #("total", json.int(mailboxes_response.total)),
    #("next_cursor", json.nullable(mailboxes_response.next_cursor, json.string)),
    #(
      "previous_cursor",
      json.nullable(mailboxes_response.previous_cursor, json.string),
    ),
    #(
      "results",
      json.array(
        mailboxes_response.results,
        encode_get_mailboxes_message_response_to_json,
      ),
    ),
  ])
}

pub fn decode_from_to_model() -> decode.Decoder(FromToModel) {
  use name <- decode.optional_field(
    "name",
    option.None,
    decode.optional(decode.string),
  )
  use address <- decode.field("address", decode.string)

  decode.success(FromToModel(name:, address:))
}

// fn decode_content_type_model() -> decode.Decoder(ContentTypeModel) {
//   use value <- decode.field("value", decode.string)
//   use params <- decode.field("params", decode.dynamic)

//   decode.success(ContentTypeModel(value:, params:))
// }

pub fn decode_message_in_mailbox_model() -> decode.Decoder(
  MessageInMailboxModel,
) {
  use id <- decode.field("id", decode.int)
  use mailbox <- decode.field("mailbox", decode.string)
  use thread <- decode.field("thread", decode.string)
  use from <- decode.field("from", decode_from_to_model())
  use to <- decode.field("to", decode.list(decode_from_to_model()))
  use cc <- decode.field("cc", decode.list(decode_from_to_model()))
  use bcc <- decode.field("bcc", decode.list(decode_from_to_model()))
  use subject <- decode.field("subject", decode.string)
  use date <- decode.field("date", decode.string)
  use intro <- decode.optional_field(
    "intro",
    option.None,
    decode.optional(decode.string),
  )
  use attachments <- decode.field("attachments", decode.bool)
  use seen <- decode.field("seen", decode.bool)
  use deleted <- decode.field("deleted", decode.bool)
  use flagged <- decode.field("flagged", decode.bool)
  use answered <- decode.field("answered", decode.bool)
  use forwarded <- decode.field("forwarded", decode.bool)
  use size <- decode.field("size", decode.int)
  //   use content_type <- decode.field("contentType", decode_content_type_model())
  use message_id <- decode.field("messageId", decode.string)
  use references <- decode.field("references", decode.list(decode.string))
  use thread_message_count <- decode.optional_field(
    "threadMessageCount",
    option.None,
    decode.optional(decode.int),
  )
  use idate <- decode.optional_field(
    "idate",
    option.None,
    decode.optional(decode.string),
  )
  use draft <- decode.optional_field(
    "draft",
    option.None,
    decode.optional(decode.bool),
  )
  //   use meta_data <- decode.optional_field(
  //     "metaData",
  //     option.None,
  //     decode.optional(decode.dynamic),
  //   )

  decode.success(MessageInMailboxModel(
    id:,
    mailbox:,
    thread:,
    thread_message_count:,
    from:,
    to:,
    cc:,
    bcc:,
    subject:,
    date:,
    idate:,
    size:,
    draft:,
    intro:,
    attachments:,
    seen:,
    deleted:,
    flagged:,
    answered:,
    forwarded:,
    // content_type:,
    // meta_data:,
    message_id:,
    references:,
  ))
}

pub fn decode_get_messages_in_mailbox_response_model() -> decode.Decoder(
  GetMessagesInMailboxResponseModel,
) {
  use success <- decode.field("success", decode.bool)
  use total <- decode.field("total", decode.int)
  use page <- decode.field("page", decode.int)

  // not really optional but brain tired
  use previous_cursor <- decode.optional_field(
    "previousCursor",
    option.None,
    decode_cursor(),
  )
  use next_cursor <- decode.optional_field(
    "nextCursor",
    option.None,
    decode_cursor(),
  )
  use results <- decode.field(
    "results",
    decode.list(decode_message_in_mailbox_model()),
  )

  decode.success(GetMessagesInMailboxResponseModel(
    success:,
    total:,
    page:,
    previous_cursor:,
    next_cursor:,
    results:,
  ))
}

pub fn decode_cursor() -> decode.Decoder(option.Option(String)) {
  decode.one_of(decode.string |> decode.map(option.Some), or: [
    decode.bool
    |> decode.then(fn(value) {
      case value {
        False -> decode.success(option.None)
        True -> decode.failure(option.Some("Expected false"), "")
      }
    }),
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

pub fn encode_user_login_body_to_json(body: UserLoginBody) -> json.Json {
  json.object([
    #("username", json.string(body.username)),
    #("password", json.string(body.password)),
  ])
}

pub fn decode_user_login_body() -> decode.Decoder(UserLoginBody) {
  use username <- decode.field("username", decode.string)
  use password <- decode.field("password", decode.string)

  decode.success(UserLoginBody(username:, password:))
}

pub fn encode_error_to_json(error: ErrorBody) -> json.Json {
  json.object([#("error", json.string(error.reason))])
}

pub fn decode_error_body() -> decode.Decoder(ErrorBody) {
  use error <- decode.field("error", decode.string)

  decode.success(ErrorBody(reason: error))
}

pub fn encode_login_success_response_to_json(
  response: UserLoginResponseBody,
) -> json.Json {
  json.object([#("jwt", json.string(response.jwt))])
}

pub fn decode_login_success_response_body() -> decode.Decoder(
  UserLoginResponseBody,
) {
  use jwt <- decode.field("jwt", decode.string)

  decode.success(UserLoginResponseBody(jwt:))
}
