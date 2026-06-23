import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import glemail_client/wildduck

pub fn to_and_from(to: List(wildduck.FromToModel)) -> String {
  case to {
    [] -> "N/A"
    rest ->
      string.join(
        list.map(rest, fn(to_data) {
          case to_data.name {
            option.None -> to_data.address
            option.Some(name) -> name <> "<" <> to_data.address <> ">"
          }
        }),
        ", ",
      )
  }
}

pub fn messages_in_mailbox(mailbox_name: String, count: Int, page: Int) {
  use mailboxes <- result.try(
    wildduck.get_user_mailboxes()
    |> result.map_error(fn(_) { io.println_error("Could not get mailboxes") }),
  )

  use mailbox <- result.try(
    list.find(mailboxes.results, fn(box) {
      string.lowercase(box.name) == string.lowercase(mailbox_name)
    })
    |> result.map_error(fn(_) {
      io.println_error("No mailbox named '" <> mailbox_name <> "' found")
    }),
  )

  use messages <- result.try(
    wildduck.get_messages_in_mailbox(
      mailbox_id: mailbox.id,
      limit: count,
      page:,
    )
    |> result.map_error(fn(_) {
      io.println_error("Was unable to retrieve mailbox messages")
    }),
  )

  list.each(messages.results, fn(message) {
    io.println(
      "----------- MESSAGE: " <> int.to_string(message.id) <> "------------",
    )
    io.println("|> To: " <> to_and_from(message.to))
    io.println("|> From: " <> to_and_from([message.from]))
    io.println("\n|> Subject: " <> message.subject)
    io.println("|> Intro: " <> option.unwrap(message.intro, "N/A"))
    io.println("----------- MESSAGE END -------------\n")
  })

  // I heard we can just wrap the whole method in a result.unwrap to achieve Nil
  // return, but I think this should be fine
  Ok(Nil)
}

pub fn list_mailboxes() {
  use mailboxes <- result.try(
    wildduck.get_user_mailboxes()
    |> result.map_error(fn(_) { Nil }),
  )

  list.each(mailboxes.results, fn(data) {
    io.println("----------- Mailbox: " <> data.name <> "------------")
    io.println("|> ID: " <> data.id)
    io.println("|> Total: " <> int.to_string(option.unwrap(data.total, 0)))
    io.println(
      "|> Unseen Messages: " <> int.to_string(option.unwrap(data.unseen, 0)),
    )
    io.println("----------- MESSAGE END -------------\n")
  })

  Ok(Nil)
}
