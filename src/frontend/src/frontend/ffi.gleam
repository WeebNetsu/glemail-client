@external(javascript, "./js/dom.js", "set_title")
pub fn set_title(title: String) -> Nil

/// Creates or updates a cookie. If no expiry date is provided, then cookie will expire after session
@external(javascript, "./js/cookie.js", "set_cookie")
pub fn set_cookie(
  key key: String,
  value value: String,
  expiry_date expiry_date: String,
) -> Bool

/// Gets all cookies, in the following form: "cookie1=val1; cookie2=val2;"
@external(javascript, "./js/cookie.js", "get_cookies")
pub fn get_cookies() -> String

@external(javascript, "./js/cookie.js", "delete_cookie")
pub fn delete_cookie(key: String) -> Nil
