import frontend/ffi
import gleam/list
import gleam/result
import gleam/string

pub type AvailableCookies {
  JwtAccessToken
}

pub fn get_cookie_name(cookie: AvailableCookies) -> String {
  case cookie {
    JwtAccessToken -> "jat"
  }
}

pub fn get_single_cookie(cookie: AvailableCookies) -> Result(String, Nil) {
  let cookie_name = get_cookie_name(cookie)

  ffi.get_cookies()
  |> string.split(";")
  |> list.find(fn(cookie_text) {
    let key_val = string.trim(cookie_text) |> string.split("=")

    case key_val {
      [key, val] if key == cookie_name && val != "" -> True
      _ -> False
    }
  })
  |> result.map(fn(cookie_text) {
    let key_val = string.trim(cookie_text) |> string.split("=")

    case key_val {
      [_, val] -> val
      _ -> ""
    }
  })
}
