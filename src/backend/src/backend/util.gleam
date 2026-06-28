import dot_env/env
import gleam/list
import gleam/result
import gleam/string

pub type EnvValues {
  EnvValues(
    api_url: String,
    user_id: String,
    access_token: String,
    secret_key: String,
  )
}

pub fn get_env_values() -> EnvValues {
  let api_url = result.unwrap(env.get_string("API_URL"), "")
  //   todo: needs to be replaced with logged in/user entered value?
  let user_id = result.unwrap(env.get_string("USER_ID"), "")
  let access_token = result.unwrap(env.get_string("ACCESS_TOKEN"), "")
  let secret_key = result.unwrap(env.get_string("SECRET_KEY"), "")

  EnvValues(api_url:, user_id:, access_token:, secret_key:)
}

pub fn url_query_builder(queries: List(#(String, String))) -> String {
  let generated_queries =
    queries
    |> list.map(fn(query) {
      let #(key, value) = query

      key <> "=" <> value
    })
    |> string.join("&")

  case generated_queries {
    "" -> ""
    _ -> "?" <> generated_queries
  }
}
