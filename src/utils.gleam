import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import pokedex

pub type TableData {
  TableData(
    type_name: String,
    values: List(Int),
    total_weak: String,
    total_resist: String,
  )
}

fn calc_total_weak(values: List(Int)) {
  list.count(values, fn(x) { x > 100 })
  |> int.to_string
}

fn calc_total_resist(values: List(Int)) {
  list.count(values, fn(x) { x < 100 })
  |> int.to_string
}

fn process_name_line(s: String, names_set) {
  // need to handle nicknames, items, gender
  s
  |> string.replace("(", "")
  |> string.replace(")", "")
  |> string.split(" ")
  |> list.reverse
  // There is an edge case where if the actual name is invalid but they put a valid name in the nickname it will use that valid name. I'm going to ignore that edge case
  |> list.find(set.contains(names_set, _))
}

pub fn get_name(block: String, names_set) {
  block
  |> string.split("\n")
  |> list.first
  |> result.unwrap("")
  |> string.trim
  |> process_name_line(names_set)
}

fn parse(input: String, names_set) -> Result(List(String), Nil) {
  input
  |> string.trim
  |> string.split("\n\n")
  |> list.try_map(get_name(_, names_set))
}

fn get_weakness_data(mons: List(String), weakness_data_dict) {
  mons
  |> list.try_map(dict.get(weakness_data_dict, _))
  |> result.map(list.transpose)
}

pub fn get_data(input: String) -> Result(#(List(String), List(TableData)), Nil) {
  let names_set = set.from_list(list.map(pokedex.weakness_data, fn(x) { x.0 }))
  let weakness_data_dict = dict.from_list(pokedex.weakness_data)

  case parse(input, names_set) {
    Ok(names) -> {
      case get_weakness_data(names, weakness_data_dict) {
        Ok(weakness_data) -> {
          // add on labels and stuff
          let table_data =
            list.map2(
              weakness_data,
              pokedex.pokemon_types,
              fn(values, type_name) {
                let total_weak = calc_total_weak(values)
                let total_resist = calc_total_resist(values)
                TableData(type_name:, values:, total_weak:, total_resist:)
              },
            )

          Ok(#(names, table_data))
        }
        Error(_) -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}
