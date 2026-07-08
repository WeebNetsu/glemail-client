import frontend/config
import frontend/cookies
import gleam/http
import gleam/http/request

pub fn build_request(
  method method: http.Method,
  path path: String,
  body body: String,
  include_auth include_auth: Bool,
) -> Result(request.Request(String), Nil) {
  let jwt = cookies.get_single_cookie(cookies.JwtAccessToken)

  let req =
    request.new()
    |> request.set_method(method)
    |> request.set_scheme(http.Http)
    |> request.set_host(config.api.host)
    |> request.set_path(path)
    |> request.set_body(body)

  // if we include auth, but token does not exist, then we need to stop the build of this request
  case include_auth, jwt {
    True, Ok(token) -> {
      Ok(request.set_header(req, "authorization", "Bearer " <> token))
    }
    True, Error(_) -> {
      Error(Nil)
    }
    False, _ -> Ok(req)
  }
}
