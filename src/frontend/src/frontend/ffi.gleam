@external(javascript, "./js/dom.js", "set_title")
pub fn set_title(title: String) -> Nil

@external(javascript, "./js/cookie.js", "set_cookie")
pub fn set_cookie(
  key key: String,
  value value: String,
  expiry_date expiry_date: String,
) -> Bool

@external(javascript, "./js/cookie.js", "get_cookies")
pub fn get_cookies() -> String

@external(javascript, "./js/cookie.js", "delete_cookie")
pub fn delete_cookie(key: String) -> Nil
