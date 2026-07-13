import frontend/ffi
import frontend/page/login
import frontend/page/mail
import frontend/page/not_found
import frontend/page/register
import frontend/utils
import gleam/fetch
import gleam/uri
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import shared
import shared/response_type

// Modem is a package providing effects and functionality for routing in SPAs.
// This means instead of links taking you to a new page and reloading everything,
// they are intercepted and your `update` function gets told about the new URL.
import modem

type Model {
  Model(
    route: utils.Route,
    register_page: register.Model,
    login_page: login.Model,
    mail_page: mail.Model,
  )
}

type Message {
  UserNavigatedTo(route: utils.Route)
  RegisterMsg(register.Message)
  LoginMsg(login.Message)
  MailMsg(mail.Message)
}

fn parse_route(link: uri.Uri) -> utils.Route {
  case uri.path_segments(link.path) {
    [] | [""] | ["register"] -> utils.RegisterRoute
    ["login"] -> utils.LoginRoute
    ["mail"] -> utils.MailRoute

    // ["post", post_id] ->
    //   case int.parse(post_id) {
    //     Ok(post_id) -> PostById(id: post_id)
    //     Error(_) -> NotFound(link:)
    //   }
    _ -> utils.NotFoundRoute(link:)
  }
}

pub type Msg {
  UserFetchedMailboxes(
    Result(response_type.GetMailboxesResponse, fetch.FetchError),
  )
}

fn init(_flags) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> utils.RegisterRoute
  }

  let #(register_page_model, register_page_effect) = register.init()
  let #(login_page_model, login_page_effect) = login.init()
  let #(mail_page_model, mail_page_effect) = mail.init()

  let model =
    Model(
      route:,
      register_page: register_page_model,
      login_page: login_page_model,
      mail_page: mail_page_model,
    )

  let title_effect = effect.from(fn(_) { ffi.set_title(shared.site_name) })
  let modem_effect =
    modem.init(fn(uri) {
      uri
      |> parse_route
      |> UserNavigatedTo
    })

  let batch_effect =
    effect.batch([
      modem_effect,
      title_effect,
      effect.map(register_page_effect, RegisterMsg),
      effect.map(login_page_effect, LoginMsg),
      effect.map(mail_page_effect, MailMsg),
    ])

  #(model, batch_effect)
}

fn update(model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    UserNavigatedTo(route:) -> #(Model(..model, route:), effect.none())
    RegisterMsg(register_message) -> {
      let #(updated_register, register_effect) =
        register.update(model.register_page, register_message)

      #(
        Model(..model, register_page: updated_register),
        effect.map(register_effect, RegisterMsg),
      )
    }
    LoginMsg(login_message) -> {
      let #(updated_login, login_effect) =
        login.update(model.login_page, login_message)

      #(
        Model(..model, login_page: updated_login),
        effect.map(login_effect, LoginMsg),
      )
    }
    MailMsg(mail_message) -> {
      let #(updated_mail, mail_effect) =
        mail.update(model.mail_page, mail_message)

      #(
        Model(..model, mail_page: updated_mail),
        effect.map(mail_effect, MailMsg),
      )
    }
  }
}

fn view(model: Model) -> element.Element(Message) {
  html.main(
    [
      attribute.class(
        "dark bg-gray-700 min-w-screen w-full min-h-screen h-full p-1 text-slate-100 flex",
      ),
    ],
    [
      case model.route {
        utils.RegisterRoute -> {
          html.div(
            [
              attribute.class("flex-1"),
            ],
            register.view(model.register_page),
          )
          |> element.map(RegisterMsg)
        }
        utils.LoginRoute -> {
          html.div(
            [
              attribute.class("flex-1"),
            ],
            login.view(model.login_page),
          )
          |> element.map(LoginMsg)
        }
        utils.MailRoute -> {
          html.div(
            [
              attribute.class("flex-1"),
            ],
            mail.view(model.mail_page),
          )
          |> element.map(MailMsg)
        }
        // PostById(post_id) -> view_post(model, post_id)
        utils.NotFoundRoute(_) -> html.div([], not_found.view())
      },
    ],
  )
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
