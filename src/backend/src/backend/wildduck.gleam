import backend/util
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleam/result

// ------------ MARK: TYPES
pub type WildDuckErrors {
  RequestError
  JsonParseError
  WildduckError(error: String, code: String)
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
    content_type: ContentTypeModel,
    meta_data: option.Option(dynamic.Dynamic),
    message_id: String,
    references: List(String),
  )
}

pub type ContentTypeModel {
  ContentTypeModel(value: String, params: dynamic.Dynamic)
}

pub type FromToModel {
  FromToModel(name: option.Option(String), address: String)
}

pub type MailboxModel {
  MailboxModel(
    id: String,
    name: String,
    path: String,
    special_use: option.Option(String),
    modify_index: option.Option(Int),
    subscribed: Bool,
    retention: option.Option(Int),
    hidden: Bool,
    total: option.Option(Int),
    unseen: option.Option(Int),
  )
}

pub type GetUserMailboxesResponseModel {
  GetUserMailboxesResponseModel(success: Bool, results: List(MailboxModel))
}

pub type CreateUserResponseModel {
  CreateUserResponseModel(success: Bool, id: String)
}

// --------------- MARK: DECODERS
fn decode_create_user_response_model() {
  use success <- decode.field("success", decode.bool)
  use id <- decode.field("id", decode.string)

  decode.success(CreateUserResponseModel(success:, id:))
}

fn decode_wildduck_error_response_model() {
  use error <- decode.field("error", decode.string)
  use code <- decode.field("code", decode.string)

  decode.success(WildduckError(error:, code:))
}

fn decode_mailbox_model() -> decode.Decoder(MailboxModel) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use path <- decode.field("path", decode.string)
  use special_use <- decode.optional_field(
    "special_use",
    option.None,
    decode.optional(decode.string),
  )

  use modify_index <- decode.optional_field(
    "modify_index",
    option.None,
    decode.optional(decode.int),
  )
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
  use subscribed <- decode.field("subscribed", decode.bool)
  use hidden <- decode.field("hidden", decode.bool)
  use retention <- decode.optional_field(
    "retention",
    option.None,
    decode.optional(decode.int),
  )

  decode.success(MailboxModel(
    id:,
    name:,
    path:,
    special_use:,
    modify_index:,
    total:,
    unseen:,
    subscribed:,
    hidden:,
    retention:,
  ))
}

fn decode_get_user_mailboxes_response_model() -> decode.Decoder(
  GetUserMailboxesResponseModel,
) {
  use success <- decode.field("success", decode.bool)
  use results <- decode.field("results", decode.list(decode_mailbox_model()))

  decode.success(GetUserMailboxesResponseModel(success:, results:))
}

fn decode_from_to_model() -> decode.Decoder(FromToModel) {
  use name <- decode.optional_field(
    "name",
    option.None,
    decode.optional(decode.string),
  )
  use address <- decode.field("address", decode.string)

  decode.success(FromToModel(name:, address:))
}

fn decode_content_type_model() -> decode.Decoder(ContentTypeModel) {
  use value <- decode.field("value", decode.string)
  use params <- decode.field("params", decode.dynamic)

  decode.success(ContentTypeModel(value:, params:))
}

fn decode_message_in_mailbox_model() -> decode.Decoder(MessageInMailboxModel) {
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
  use content_type <- decode.field("contentType", decode_content_type_model())
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
  use meta_data <- decode.optional_field(
    "metaData",
    option.None,
    decode.optional(decode.dynamic),
  )

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
    content_type:,
    meta_data:,
    message_id:,
    references:,
  ))
}

fn decode_get_messages_in_mailbox_response_model() -> decode.Decoder(
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

fn decode_cursor() -> decode.Decoder(option.Option(String)) {
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

// -------------- MARK: UTILS

fn http_get_request(url: String) -> Result(response.Response(String), Nil) {
  use base_req <- result.try(request.to(url))

  let req = request.set_method(base_req, http.Get)

  // Send the HTTP request to the server
  case httpc.send(req) {
    Ok(resp) -> {
      let content_type = response.get_header(resp, "content-type")
      assert content_type == Ok("application/json; charset=utf-8")

      Ok(resp)
    }
    Error(_) -> {
      io.println_error("Could not make get request")
      Error(Nil)
    }
  }
}

// --------------- MARK: REQUESTS
pub fn create_user(
  username: String,
  password: String,
) -> Result(CreateUserResponseModel, WildDuckErrors) {
  let env_values = util.get_env_values()

  let url =
    env_values.api_url
    <> "/users"
    <> util.url_query_builder([
      #("accessToken", env_values.access_token),
    ])

  use base_req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) { RequestError }),
  )

  let req =
    request.set_method(base_req, http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(
      json.to_string(
        json.object([
          #("username", json.string(username)),
          #("password", json.string(password)),
        ]),
      ),
    )

  // Send the HTTP request to the server
  case httpc.send(req) {
    Ok(resp) if resp.status == 200 -> {
      use res <- result.try(
        json.parse(from: resp.body, using: decode_create_user_response_model())
        |> result.map_error(fn(err) {
          echo err
          JsonParseError
        }),
      )

      Ok(res)
    }
    Ok(resp) -> {
      use res <- result.try(
        json.parse(
          from: resp.body,
          using: decode_wildduck_error_response_model(),
        )
        |> result.map_error(fn(err) {
          echo err
          JsonParseError
        }),
      )

      Error(res)
    }
    Error(_) -> {
      io.println_error("Could not make get request")
      Error(RequestError)
    }
  }
}

pub fn get_user_mailboxes() -> Result(
  GetUserMailboxesResponseModel,
  WildDuckErrors,
) {
  let env_values = util.get_env_values()

  let url =
    env_values.api_url
    <> "/users/"
    <> env_values.user_id
    <> "/mailboxes"
    <> util.url_query_builder([
      #("accessToken", env_values.access_token),
    ])

  use resp <- result.try(
    // map error into my own custom type
    http_get_request(url) |> result.map_error(fn(_) { RequestError }),
  )

  use res <- result.try(
    json.parse(
      from: resp.body,
      using: decode_get_user_mailboxes_response_model(),
    )
    |> result.map_error(fn(err) {
      echo err
      JsonParseError
    }),
  )

  Ok(res)
}

pub fn get_messages_in_mailbox(
  mailbox_id mailbox_id: String,
  limit limit: Int,
  page page: Int,
) -> Result(GetMessagesInMailboxResponseModel, WildDuckErrors) {
  let env_values = util.get_env_values()

  let url =
    env_values.api_url
    <> "/users/"
    <> env_values.user_id
    <> "/mailboxes/"
    <> mailbox_id
    <> "/messages"
    <> util.url_query_builder([
      #("accessToken", env_values.access_token),
      #("limit", int.to_string(limit)),
      #("page", int.to_string(page)),
    ])

  use resp <- result.try(
    // map error into my own custom type
    http_get_request(url) |> result.map_error(fn(_) { RequestError }),
  )

  use res <- result.try(
    json.parse(
      from: resp.body,
      using: decode_get_messages_in_mailbox_response_model(),
    )
    |> result.map_error(fn(err) {
      echo err
      JsonParseError
    }),
  )

  Ok(res)
}
