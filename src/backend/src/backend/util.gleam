import dot_env/env
import gleam/io
import gleam/list
import gleam/string

pub type EnvValues {
  EnvValues(
    client_url: String,
    api_url: String,
    user_id: String,
    access_token: String,
    secret_key: String,
  )
}

pub fn get_env_values() -> EnvValues {
  // required env variables, if they do not exist, the code can't function
  case
    env.get_string("CLIENT_URL"),
    env.get_string("API_URL"),
    env.get_string("ACCESS_TOKEN"),
    env.get_string("SECRET_KEY"),
    // todo will be replaced by other values later
    env.get_string("USER_ID")
  {
    Ok(client_url), Ok(api_url), Ok(access_token), Ok(secret_key), Ok(user_id)
    -> {
      EnvValues(client_url:, api_url:, user_id:, access_token:, secret_key:)
    }
    _, _, _, _, _ -> {
      io.print_error("Some ENV variables are missing")
      panic
    }
  }
}

pub fn url_query_builder(queries: List(#(String, String))) -> String {
  let generated_queries =
    list.map(queries, fn(query) {
      let #(key, value) = query

      key <> "=" <> value
    })
    |> string.join("&")

  case generated_queries {
    "" -> ""
    _ -> "?" <> generated_queries
  }
}
