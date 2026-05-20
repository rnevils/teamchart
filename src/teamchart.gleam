import gleam/dict
import gleam/dynamic/decode
import gleam/list
import gleam/string
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import pokedex
import timer
import utils.{type TableData}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  TeamNeedsToBeEntered(user_input: String, toasts: List(String))
  TeamHasBeenEntered(
    names: List(String),
    table_data: List(TableData),
    num_lookup: dict.Dict(String, String),
  )
}

fn init(_) -> #(Model, Effect(Msg)) {
  let model = TeamNeedsToBeEntered("", [])
  let effect = effect.none()
  #(model, effect)
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserChangedTextArea(String)
  UserSubmitTeam
  CloseToast
}

fn pure(value: value) -> #(value, Effect(message)) {
  #(value, effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSubmitTeam -> handle_submit_team(model)
    UserChangedTextArea(input) -> TeamNeedsToBeEntered(input, []) |> pure
    CloseToast -> {
      case model {
        TeamNeedsToBeEntered(user_input:, toasts:) -> {
          case toasts {
            [] -> panic
            [_, ..rest] ->
              TeamNeedsToBeEntered(user_input:, toasts: rest) |> pure
          }
        }
        _ -> panic
      }
    }
  }
}

fn handle_submit_team(model: Model) {
  case model {
    TeamNeedsToBeEntered(user_input, _) -> {
      case utils.get_data(user_input) {
        Ok(#(names, table_data)) ->
          TeamHasBeenEntered(
            names,
            table_data,
            dict.from_list(pokedex.number_lookup),
          )
          |> pure
        Error(_) -> {
          let toast_text = "Unable to parse input"
          let model =
            TeamNeedsToBeEntered(
              ..model,
              toasts: list.prepend(model.toasts, toast_text),
            )

          let effect = timer.after(1500, CloseToast)

          #(model, effect)
        }
      }
    }
    _ -> pure(model)
  }
}

pub fn on_enter_and_modifier(message) -> Attribute(message) {
  event.on("keydown", {
    use key <- decode.field("key", decode.string)
    use ctrl_key <- decode.field("ctrlKey", decode.bool)
    use meta_key <- decode.field("metaKey", decode.bool)

    case { ctrl_key || meta_key } && key == "Enter" {
      True -> message |> decode.success
      False -> message |> decode.failure("")
    }
  })
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div(
    [attribute.class("font-mono p-4 w-full max-w-5xl mx-auto space-y-8")],
    case model {
      TeamNeedsToBeEntered(user_input:, toasts:) -> [
        view_header(),
        view_input(user_input, toasts),
        submit_button(),
      ]
      TeamHasBeenEntered(names, table_data, num_lookup) -> [
        view_header(),
        view_parsed(names, table_data, num_lookup),
      ]
    },
  )
}

fn view_header() {
  html.div(
    [
      attribute.id("navbar"),
      attribute.class("navbar p-0"),
    ],
    [
      html.div([attribute.class("flex-1 text-4xl")], [
        html.text("Team Weakness Chart"),
      ]),
      // html.div([attribute.class("flex-none")], [
    //   html.ul([attribute.class("menu menu-horizontal px-1")], [
    //     html.li([], [
    //       html.a(
    //         [
    //           attribute.target("_blank"),
    //           attribute.href(
    //             "https://github.com/rnevils/defense-ev-calculator",
    //           ),
    //         ],
    //         [
    //           html.img([
    //             attribute.height(28),
    //             attribute.width(28),
    //             attribute.alt("GitHub"),
    //             case model.light_theme {
    //               True -> attribute.src("GitHub.svg")
    //               False -> attribute.src("GitHub_white.svg")
    //             },
    //           ]),
    //         ],
    //       ),
    //     ]),
    //     html.li([attribute.class("justify-center")], [
    //       html.input([
    //         event.on_check(UserToggledTheme),
    //         attribute.class("toggle theme-controller al"),
    //         attribute.checked(model.light_theme),
    //         attribute.value("light"),
    //         attribute.type_("checkbox"),
    //       ]),
    //     ]),
    //   ]),
    // ]),
    ],
  )
}

fn render_toasts(toasts: List(String)) {
  list.map(toasts, fn(t) {
    html.div(
      [
        attribute.class("alert alert-error alert-soft"),
      ],
      [
        html.span([], [html.text(t)]),
      ],
    )
  })
}

fn view_input(input: String, toasts: List(String)) {
  html.div([attribute.class("")], [
    html.div([attribute.class("")], [
      html.textarea(
        [
          attribute.placeholder("Paste Team Here"),
          attribute.spellcheck(False),
          attribute.class(
            "textarea textarea-xs resize-none w-full h-[65dvh] bg-base-300",
          ),
          attribute.value(input),
          event.on_input(UserChangedTextArea),
          on_enter_and_modifier(UserSubmitTeam),
        ],
        "",
      ),
      html.div([attribute.class("toast toast-start")], render_toasts(toasts)),
    ]),
  ])
}

fn submit_button() {
  html.div([attribute.class("text-right")], [
    html.button(
      [
        event.on_click(UserSubmitTeam),
        attribute.class("btn btn-primary "),
      ],
      [html.text("Submit")],
    ),
  ])
}

fn th_summary(text) {
  html.th([attribute.class("text-center text-xs")], [html.text(text)])
}

fn pkmn_img(name: String, num_lookup) {
  case dict.get(num_lookup, name) {
    Ok(num) -> {
      let url =
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/"
        <> num
        <> ".png"
      html.td([], [
        html.img([
          attribute.class("mx-auto"),
          attribute.alt(name),
          attribute.src(url),
          attribute.width(42),
          attribute.height(42),
        ]),
      ])
    }
    Error(_) -> {
      html.th([attribute.class("text-center text-xs")], [html.text(name)])
    }
  }
}

fn render_headers(mons, num_lookup) {
  list.map(mons, pkmn_img(_, num_lookup))
  |> list.prepend(html.th([], []))
  |> list.append([th_summary("Total Weak")])
  |> list.append([th_summary("Total Resist")])
}

fn td_type(type_name: String) {
  let class = "type-" <> type_name <> ""
  html.td([attribute.class(class), attribute.class("text-center")], [
    html.text(string.uppercase(type_name)),
  ])
}

fn td_total_resist(num: String) {
  let class = case num {
    "0" -> "bg-success/10"
    "1" -> "bg-success/20"
    "2" -> "bg-success/30"
    "3" -> "bg-success/40"
    "4" -> "bg-success/50"
    "5" -> "bg-success/60"
    _ -> "bg-success"
  }
  html.td([attribute.class(class), attribute.class("text-center")], [
    html.text(string.uppercase(num)),
  ])
}

fn td_total_weak(num: String) {
  let class = case num {
    "0" -> "bg-error/10"
    "1" -> "bg-error/20"
    "2" -> "bg-error/30"
    "3" -> "bg-error/40"
    "4" -> "bg-error/50"
    "5" -> "bg-error/60"
    _ -> "bg-error"
  }
  html.td([attribute.class(class), attribute.class("text-center")], [
    html.text(string.uppercase(num)),
  ])
}

fn render_num(class, num) {
  html.td([], [
    html.div([attribute.class("flex justify-center")], [
      html.div([attribute.class(class)], [
        html.text(num),
      ]),
    ]),
  ])
}

fn td_num_weak(num: Int) {
  case num {
    0 -> render_num("no-eff", "0")
    25 -> render_num("quad-resist", "¼")
    50 -> render_num("normal-num", "½")
    200 -> render_num("normal-num", "2")
    400 -> render_num("quad-eff", "4")
    _ -> render_num("normal-num", "")
  }
}

fn render_row(row: TableData) {
  let temprename =
    row.values
    |> list.map(td_num_weak)
    |> list.prepend(td_type(row.type_name))
    |> list.append([td_total_weak(row.total_weak)])
    |> list.append([td_total_resist(row.total_resist)])

  html.tr([attribute.class("hover:bg-base-100")], temprename)
}

fn render_body(data) {
  list.map(data, render_row)
}

fn view_parsed(names: List(String), table_data: List(TableData), num_lookup) {
  html.div(
    [
      attribute.class(
        "overflow-x-auto rounded-box border border-base-content/5 bg-base-300",
      ),
    ],
    [
      html.table([attribute.class("table table-xs ")], [
        html.thead([], [
          html.tr([], render_headers(names, num_lookup)),
        ]),
        html.tbody([], render_body(table_data)),
      ]),
    ],
  )
}
