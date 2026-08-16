///|
test "deterministic clock drives repeatable scheduler scenarios" {
  let first = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 9,
    minute: 0,
    weekday: 4,
  }
  let second = first.add_minutes(15)
  let clock = ClockSequence::new([
    ClockSample::new(first, "start"),
    ClockSample::new(second, "next"),
  ])
  assert_eq(clock.remaining(), 2)
  assert_eq(clock.advance().unwrap().label, "start")
  assert_eq(clock.current().unwrap().at, second)
  assert_eq(clock.advance().unwrap().label, "next")
  assert_eq(clock.remaining(), 0)
  clock.reset()
  assert_eq(clock.remaining(), 2)
}
