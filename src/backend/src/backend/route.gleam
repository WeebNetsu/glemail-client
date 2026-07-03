import backend/util
import backend/wildduck
import cors_builder
import gleam/http
import gleam/http/response
import gleam/json
import gleam/list
import shared/response_type
import wisp

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
          wisp.internal_server_error()
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn users(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Post -> {
      use body <- wisp.require_string_body(req)

      let parsed_body =
        json.parse(body, response_type.decode_create_user_body())

      case parsed_body {
        Ok(bod) -> {
          case wildduck.create_user(bod.username, bod.password) {
            Ok(resp) -> {
              case resp.success {
                True -> {
                  echo resp.id

                  wisp.ok()
                }
                False -> wisp.internal_server_error()
              }
            }
            Error(err) -> {
              case err {
                wildduck.WildduckError(error, _) -> {
                  wisp.json_response(error, 500)
                }
                _ -> wisp.internal_server_error()
              }
            }
          }
        }
        Error(_) -> wisp.internal_server_error()
      }
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn cors_policy() -> cors_builder.Cors {
  cors_builder.new()
  |> cors_builder.allow_origin(util.get_env_values().client_url)
  |> cors_builder.allow_header("content-type")
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

    // This matches all other paths.
    _ -> wisp.not_found()
  }
}
