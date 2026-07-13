import dot_env/env
import gleam/io
import gleam/list
import gleam/string

pub type EnvValues {
  EnvValues(
    client_url: String,
    wildduck_api_url: String,
    wildduck_access_token: String,
    secret_key: String,
    app: String,
  )
}

pub fn get_env_values() -> EnvValues {
  // required env variables, if they do not exist, the code can't function
  case
    env.get_string("CLIENT_URL"),
    env.get_string("WILDDUCK_API_URL"),
    env.get_string("WILDDUCK_ACCESS_TOKEN"),
    env.get_string("SECRET_KEY"),
    env.get_string("APP")
  {
    Ok(client_url),
      Ok(wildduck_api_url),
      Ok(wildduck_access_token),
      Ok(secret_key),
      Ok(app)
    -> {
      EnvValues(
        client_url:,
        wildduck_api_url:,
        wildduck_access_token:,
        app:,
        secret_key:,
      )
    }
    _, _, _, _, _ -> {
      io.println_error("Some ENV variables are missing")
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
