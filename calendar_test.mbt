///|
test "calendar validates and normalizes timestamps" {
  let time = Time::{
    year: 2028,
    month: 2,
    day: 29,
    hour: 23,
    minute: 59,
    weekday: 2,
  }
  assert_true(time.is_valid())
  let next = time.add_minutes(1)
  assert_eq(next.year, 2028)
  assert_eq(next.month, 3)
  assert_eq(next.day, 1)
  assert_eq(next.hour, 0)
  assert_eq(next.minute, 0)
  assert_eq(next.weekday, weekday(2028, 3, 1))
}

///|
test "calendar moves backwards across a year boundary" {
  let time = Time::{
    year: 2027,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 5,
  }
  let previous = time.add_minutes(-1)
  assert_eq(previous.year, 2026)
  assert_eq(previous.month, 12)
  assert_eq(previous.day, 31)
  assert_eq(previous.hour, 23)
  assert_eq(previous.minute, 59)
}

///|
test "calendar compares and measures bounded distances" {
  let start = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let finish = start.add_minutes(90)
  assert_eq(start.compare(finish), -1)
  assert_eq(finish.compare(start), 1)
  assert_eq(start.minutes_until(finish, 100), Some(90))
  assert_eq(start.minutes_until(finish, 10), None)
}
