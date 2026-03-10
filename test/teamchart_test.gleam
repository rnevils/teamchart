import gleam/set
import utils

import gleam/list

// import gleam/result.{type Error}
import gleeunit
import pokedex

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn parse_test() {
  let names_set = set.from_list(list.map(pokedex.weakness_data, fn(x) { x.0 }))
  // let weakness_data_dict = dict.from_list(pokedex.weakness_data)
  // good inputs
  let s1 = "Choice Band @ (Miltank) (F)"
  let s2 = "@@Miltanknick @@ (F) (M) @ (Miltank) (F) @ Choice Band"
  let s3 = "@@Miltanknick @ @ (F) (M) @ (Miltank) (F)"
  let s4 = "Miltank (F) @ Choice Band"
  let s5 = "asdfkjsjd (F) sajkf;asd (Miltank) (F) @ Choice Band"
  let s6 = "Miltank (F)"

  let valid_inputs = [s1, s2, s3, s4, s5, s6]
  let output1 = list.map(valid_inputs, utils.get_name(_, names_set))
  assert list.all(output1, fn(x) { x == Ok("Miltank") })

  // invalid
  let b1 = ""
  let b2 = "asdfas"
  let b3 = "Miltdfsdfsank (F)"
  let b4 = "nicknamesdf @ (F) sdfs @@ Charizardio (F) (Miltankkkk) (F)"

  let invalid_inputs = [b1, b2, b3, b4]
  let output2 = list.map(invalid_inputs, utils.get_name(_, names_set))
  assert list.all(output2, fn(x) { x == Error(Nil) })
}
