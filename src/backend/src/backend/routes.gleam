import gleam/http
import wisp

fn home_page(req: wisp.Request) -> wisp.Response {
  // The home page can only be accessed via GET requests, so this middleware is
  // used to return a 405: Method Not Allowed response for all other methods.
  use <- wisp.require_method(req, http.Get)

  wisp.ok()
  |> wisp.html_body("Hello, Joe!")
}

fn list_comments() -> wisp.Response {
  // In a later example we'll show how to read from a database.
  wisp.ok()
  |> wisp.html_body("Comments!")
}

fn create_comment(_req: wisp.Request) -> wisp.Response {
  // In a later example we'll show how to parse data from the request body.
  wisp.created()
  |> wisp.html_body("Created")
}

fn comments(req: wisp.Request) -> wisp.Response {
  // This handler for `/comments` can respond to both GET and POST requests,
  // so we pattern match on the method here.
  case req.method {
    http.Get -> list_comments()
    http.Post -> create_comment(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn show_comment(req: wisp.Request, id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // The `id` path parameter has been passed to this function, so we could use
  // it to look up a comment in a database.
  // For now we'll just include in the response body.
  wisp.ok()
  |> wisp.html_body("Comment with id " <> id)
}

/// The middleware stack that the request handler uses. The stack is itself a
/// middleware function!
///
/// Middleware wrap each other, so the request travels through the stack from
/// top to bottom until it reaches the request handler, at which point the
/// response travels back up through the stack.
/// 
/// The middleware used here are the ones that are suitable for use in your
/// typical web application.
/// 
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
  use req <- wisp.csrf_known_header_protection(req)

  // Handle the request!
  request_handler(req)
}

pub fn handle_request(req: wisp.Request) -> wisp.Response {
  use req <- middleware(req)

  // Wisp doesn't have a special router abstraction, instead we recommend using
  // regular old pattern matching. This is faster than a router, is type safe,
  // and means you don't have to learn or be limited by a special DSL.
  //
  case wisp.path_segments(req) {
    // This matches `/`.
    [] -> home_page(req)

    // This matches `/comments`.
    ["comments"] -> comments(req)

    // This matches `/comments/:id`.
    // The `id` segment is bound to a variable and passed to the handler.
    ["comments", id] -> show_comment(req, id)

    // This matches all other paths.
    _ -> wisp.not_found()
  }
}
