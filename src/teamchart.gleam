import gleam/dict
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import pokedex
import utils.{type TableData}

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  TeamNeedsToBeEntered(user_input: String)
  TeamHasBeenEntered(
    names: List(String),
    table_data: List(TableData),
    num_lookup: dict.Dict(String, String),
  )
}

fn init(_) -> Model {
  TeamNeedsToBeEntered("")
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  UserChangedTextArea(String)
  UserSubmittedTeam(String)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserSubmittedTeam(input) -> {
      case utils.get_data(input) {
        Ok(#(names, table_data)) ->
          TeamHasBeenEntered(
            names,
            table_data,
            dict.from_list(pokedex.number_lookup),
          )
        Error(_) -> model
      }
    }
    UserChangedTextArea(input) -> {
      TeamNeedsToBeEntered(input)
    }
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div(
    [attribute.class("font-mono p-4 w-full max-w-5xl mx-auto space-y-8")],
    case model {
      TeamNeedsToBeEntered(user_input) -> [
        view_header(),
        view_input(user_input),
        butttton(user_input),
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

fn view_input(input: String) {
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
        ],
        "",
      ),
    ]),
  ])
}

fn butttton(input: String) {
  html.div([attribute.class("text-right")], [
    html.button(
      [
        event.on_click(UserSubmittedTeam(input)),
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
      html.th([], [
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

fn special_num(class, num) {
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
    0 -> special_num("no-eff", "0")
    25 -> special_num("quad-resist", "¼")
    50 -> html.td([attribute.class("text-center")], [html.text("½")])
    200 -> html.td([attribute.class("text-center")], [html.text("2")])
    400 -> special_num("quad-eff", "4")
    _ -> html.td([attribute.class("text-center")], [html.text("")])
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
      html.table([attribute.class("table table-xs table-zebra")], [
        html.thead([], [
          html.tr([], render_headers(names, num_lookup)),
        ]),
        html.tbody([], render_body(table_data)),
      ]),
    ],
  )
}
