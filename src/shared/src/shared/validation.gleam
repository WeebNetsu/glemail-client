import gleam/regexp
import gleam/result
import gleam/string

pub type ValidationError {
  /// could not initiate regex
  RegexError
  /// the passed in value did not match required regex
  FailedRegexValidationError
}

pub fn validate_username(username: String) -> Result(Nil, ValidationError) {
  let clean_username = string.trim(username)

  use regex <- result.try(
    // username may only be string and numbers, and between 7 and 24 in length
    regexp.from_string("^[a-zA-Z0-9]{7,24}$")
    |> result.map_error(fn(_) { RegexError }),
  )

  case regexp.check(regex, clean_username) {
    True -> Ok(Nil)
    False -> Error(FailedRegexValidationError)
  }
}

pub fn validate_password(username: String) -> Result(Nil, ValidationError) {
  let clean_username = string.trim(username)

  use regex <- result.try(
    // no spaces, min len 6 max len 128
    regexp.from_string("^\\S{6,128}$")
    |> result.map_error(fn(_) { RegexError }),
  )

  case regexp.check(regex, clean_username) {
    True -> Ok(Nil)
    False -> Error(FailedRegexValidationError)
  }
}
