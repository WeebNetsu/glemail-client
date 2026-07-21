import backend/db
import backend/util
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
import shared/response_type

// ------------ MARK: TYPES
pub type WildDuckErrors {
  RequestError
  JsonParseError
  DatabaseError(error: String)
  WildduckError(error: String, code: String)
}

pub type SubmitMessageForDeliveryBody {
  SubmitMessageForDeliveryBody(
    from: response_type.FromToModel,
    to: List(response_type.FromToModel),
    text: String,
    subject: String,
  )
}

pub type SubmittedMessageModel {
  SubmittedMessageModel(mailbox: String, id: Int, queue_id: String)
}

pub type SubmitMessageForDeliveryResponseModel {
  SubmitMessageForDeliveryResponseModel(
    success: Bool,
    message: SubmittedMessageModel,
  )
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

fn decode_submitted_message_model() {
  use mailbox <- decode.field("mailbox", decode.string)
  use id <- decode.field("id", decode.int)
  use queue_id <- decode.field("queueId", decode.string)

  decode.success(SubmittedMessageModel(mailbox:, id:, queue_id:))
}

fn decode_submit_message_for_delivery_response_model() {
  use success <- decode.field("success", decode.bool)
  use message <- decode.field("message", decode_submitted_message_model())

  decode.success(SubmitMessageForDeliveryResponseModel(success:, message:))
}

fn encode_submit_message_for_delivery_body_model(
  data: SubmitMessageForDeliveryBody,
) {
  json.object([
    #("from", response_type.encode_from_to_model(data.from)),
    #("to", json.array(data.to, response_type.encode_from_to_model)),
    #("text", json.string(data.text)),
    #("subject", json.string(data.subject)),
  ])
}

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
    env_values.wildduck_api_url
    <> "/users"
    <> util.url_query_builder([
      #("accessToken", env_values.wildduck_access_token),
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

      case db.create_user(username:, password:, email_id: res.id) {
        Ok(_) -> Ok(res)
        Error(err) -> {
          Error(DatabaseError(err.message))
        }
      }
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

pub fn get_user_mailboxes(
  email_id: String,
) -> Result(GetUserMailboxesResponseModel, WildDuckErrors) {
  let env_values = util.get_env_values()

  let url =
    env_values.wildduck_api_url
    <> "/users/"
    <> email_id
    <> "/mailboxes"
    <> util.url_query_builder([
      #("accessToken", env_values.wildduck_access_token),
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
  email_id email_id: String,
  mailbox_id mailbox_id: String,
  limit limit: Int,
  page page: Int,
) -> Result(response_type.GetMessagesInMailboxResponseModel, WildDuckErrors) {
  let env_values = util.get_env_values()

  let url =
    env_values.wildduck_api_url
    <> "/users/"
    <> email_id
    <> "/mailboxes/"
    <> mailbox_id
    <> "/messages"
    <> util.url_query_builder([
      #("accessToken", env_values.wildduck_access_token),
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
      using: response_type.decode_get_messages_in_mailbox_response_model(),
    )
    |> result.map_error(fn(err) {
      echo err
      JsonParseError
    }),
  )

  Ok(res)
}

pub fn submit_message_for_delivery(
  email_id email_id: String,
  data data: SubmitMessageForDeliveryBody,
) -> Result(SubmitMessageForDeliveryResponseModel, WildDuckErrors) {
  let env_values = util.get_env_values()

  let url =
    env_values.wildduck_api_url
    <> "/users/"
    <> email_id
    <> "/submit"
    <> util.url_query_builder([
      #("accessToken", env_values.wildduck_access_token),
    ])

  use base_req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) { RequestError }),
  )

  let req =
    request.set_method(base_req, http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(
      json.to_string(encode_submit_message_for_delivery_body_model(data)),
    )

  // Send the HTTP request to the server
  case httpc.send(req) {
    Ok(resp) if resp.status == 200 -> {
      use res <- result.try(
        json.parse(
          from: resp.body,
          using: decode_submit_message_for_delivery_response_model(),
        )
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
