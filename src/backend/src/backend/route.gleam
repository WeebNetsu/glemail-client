import backend/db
import backend/util
import backend/wildduck
import cors_builder
import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import gose
import gose/jose/jwt
import shared/response_type
import wisp

type RouteError {
  JwtError
  JwtExpiredError
  JwtDecodeError
}

type JwtData {
  JwtData(email_id: String, user_id: Int)
}

fn validate_jwt(token: String) -> Result(String, RouteError) {
  use signing_key <- result.try(
    gose.from_octet_bits(bit_array.from_string(util.get_env_values().secret_key))
    |> result.map_error(fn(_) { JwtError }),
  )

  use verifier <- result.try(
    jwt.verifier(
      gose.Mac(gose.Hmac(gose.HmacSha256)),
      keys: [signing_key],
      options: jwt.default_validation(),
    )
    |> result.map_error(fn(_) { JwtError }),
  )

  use verified <- result.try(
    jwt.verify_and_validate(verifier, token, timestamp.system_time())
    |> result.map_error(fn(err) {
      case err {
        jwt.TokenExpired(_) -> JwtExpiredError
        _ -> JwtError
      }
    }),
  )

  let decoder = decode.field("sub", decode.string, decode.success)
  use val <- result.try(
    jwt.decode(verified, using: decoder)
    |> result.map_error(fn(_) { JwtDecodeError }),
  )

  Ok(val)
}

fn encode_jwt_to_json(data: JwtData) {
  json.object([
    #("email_id", json.string(data.email_id)),
    #("user_id", json.int(data.user_id)),
  ])
}

fn decode_jwt() -> decode.Decoder(JwtData) {
  use email_id <- decode.field("email_id", decode.string)
  use user_id <- decode.field("user_id", decode.int)

  decode.success(JwtData(email_id:, user_id:))
}

fn generate_jwt(jwt: JwtData) -> Result(String, RouteError) {
  use signing_key <- result.try(
    gose.from_octet_bits(bit_array.from_string(util.get_env_values().secret_key))
    |> result.map_error(fn(_) { JwtError }),
  )

  let claims =
    jwt.claims()
    |> jwt.with_subject(json.to_string(encode_jwt_to_json(jwt)))
    |> jwt.with_issuer(util.get_env_values().app)
    |> jwt.with_expiration(timestamp.add(
      timestamp.system_time(),
      duration.hours(24),
    ))

  use signed <- result.try(
    jwt.sign(gose.Mac(gose.Hmac(gose.HmacSha256)), claims:, key: signing_key)
    |> result.map_error(fn(_) { JwtError }),
  )

  Ok(jwt.serialize(signed))
}

fn get_jwt_from_token(token: String) -> Result(JwtData, RouteError) {
  use str_jwt <- result.try(validate_jwt(token))
  use parsed_jwt <- result.try(
    json.parse(str_jwt, decode_jwt())
    |> result.map_error(fn(_) { JwtError }),
  )

  Ok(parsed_jwt)
}

fn wisp_error_response(code: Int, reason: String) {
  wisp.json_response(
    json.to_string(
      response_type.encode_error_to_json(response_type.ErrorBody(reason:)),
    ),
    code,
  )
}

fn mailboxes(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> {
      case wildduck.get_user_mailboxes() {
        Ok(mailboxes) -> {
          wisp.ok()
          |> wisp.json_body(
            json.to_string(
              response_type.encode_get_mailboxes_response_to_json(
                response_type.GetMailboxesResponse(
                  list.map(mailboxes.results, fn(res) {
                    response_type.Mailbox(
                      id: res.id,
                      name: res.name,
                      total: res.total,
                      unseen: res.unseen,
                    )
                  }),
                ),
              ),
            ),
          )
        }
        Error(_) -> {
          wisp_error_response(500, "Could not get mailboxes")
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn handle_create_user(body: String) -> Result(String, wisp.Response) {
  use parsed_body <- result.try(
    json.parse(body, response_type.decode_create_user_body())
    |> result.map_error(fn(_) { wisp.internal_server_error() }),
  )

  case wildduck.create_user(parsed_body.username, parsed_body.password) {
    // ok but only if response was considered successful
    Ok(resp) if resp.success -> Ok(resp.id)
    // error but only if error was provided
    Error(wildduck.WildduckError(error, _)) -> {
      Error(wisp.json_response(
        json.to_string(
          response_type.encode_error_to_json(response_type.ErrorBody(
            reason: error,
          )),
        ),
        500,
      ))
    }
    _ -> Error(wisp.internal_server_error())
  }
}

fn users(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_string_body(req)

      case handle_create_user(body) {
        Ok(_) -> wisp.ok()
        Error(err) -> err
      }
    }
    _ -> wisp.method_not_allowed(allowed: [http.Post])
  }
}

fn handle_user_login(body: String) -> Result(String, wisp.Response) {
  use parsed_body <- result.try(
    json.parse(body, response_type.decode_user_login_body())
    |> result.map_error(fn(_) {
      wisp_error_response(400, "Invalid data provided for request")
    }),
  )

  case db.get_user(parsed_body.username) {
    Ok(user) -> {
      let hashed_pass = db.hash_value(parsed_body.password)

      case hashed_pass == user.password {
        True -> Ok(user.email_id)
        False -> {
          Error(wisp_error_response(400, "Invalid Password"))
        }
      }
    }
    Error(err) -> {
      case err {
        db.NotFoundError -> {
          Error(wisp_error_response(404, "Account not found"))
        }
        db.SqliteError(msg) -> {
          Error(wisp_error_response(500, msg))
        }
      }
    }
  }
}

fn users_login(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_string_body(req)

      case handle_user_login(body) {
        Ok(email_id) -> {
          let token = generate_jwt(JwtData(email_id:, user_id: 0))

          //   let jwt_data = case token {
          //     Ok(val) -> get_jwt_from_token(val)
          //     Error(err) -> Error(err)
          //   }
          //   echo jwt_data

          case token {
            Ok(val) -> {
              wisp.json_response(
                json.to_string(
                  response_type.encode_login_success_response_to_json(
                    response_type.UserLoginResponseBody(jwt: val),
                  ),
                ),
                200,
              )
            }
            Error(_) -> {
              wisp_error_response(500, "Could not generate token")
            }
          }
        }
        Error(err) -> err
      }
    }
    _ -> wisp.method_not_allowed(allowed: [http.Post])
  }
}

fn cors_policy() -> cors_builder.Cors {
  cors_builder.new()
  |> cors_builder.allow_origin(util.get_env_values().client_url)
  |> cors_builder.allow_header("content-type")
  |> cors_builder.allow_header("authorization")
  |> cors_builder.allow_method(http.Get)
  |> cors_builder.allow_method(http.Post)
  |> cors_builder.allow_method(http.Options)
}

fn middleware(
  req: wisp.Request,
  request_handler: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  // Permit browsers to simulate methods other than GET and POST using the
  // `_method` query parameter.
  let req = wisp.method_override(req)
  // Log information about the request and response.
  use <- wisp.log_request(req)
  // Return a default 500 response if the request handler crashes.
  use <- wisp.rescue_crashes
  // Rewrite HEAD requests to GET requests and return an empty body.
  use req <- wisp.handle_head(req)

  //   let auth_head = list.find(req.headers, fn(head) { head.0 == "authorization" })
  //   echo auth_head

  // Known-header based CSRF protection for non-HEAD/GET requests
  //   use req <- wisp.csrf_known_header_protection(req)

  // Handle the request!
  request_handler(req)
}

pub fn handle_request(req: wisp.Request) -> wisp.Response {
  // order is important, do cors before middleware
  use cors_req <- cors_builder.wisp_middleware(req, cors_policy())
  use middleware_req <- middleware(cors_req)

  // Wisp doesn't have a special router abstraction, instead we recommend using
  // regular old pattern matching. This is faster than a router, is type safe,
  // and means you don't have to learn or be limited by a special DSL.
  case wisp.path_segments(middleware_req) {
    ["mailboxes"] -> mailboxes(middleware_req)
    ["users"] -> users(middleware_req)
    ["users", "login"] -> users_login(middleware_req)

    // This matches all other paths.
    _ -> wisp.not_found()
  }
}
