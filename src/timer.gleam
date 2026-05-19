import lustre/effect.{type Effect}

pub type Timer

pub fn after(delay: Int, msg: msg) -> Effect(msg) {
  use dispatch <- effect.from
  let _ = set_timeout(delay, fn() { dispatch(msg) })

  Nil
}

@external(javascript, "./teamchart.ffi.mjs", "set_timeout")
fn set_timeout(delay: Int, cb: fn() -> Nil) -> Timer
