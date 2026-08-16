///|
test "query returns previous and next occurrences" {
  let expression = match parse("0 0 * * *") {
    Ok(value) => value
    Err(_) => panic()
  }
  let from = Time::{
    year: 2026,
    month: 2,
    day: 1,
    hour: 0,
    minute: 1,
    weekday: 0,
  }
  match expression.previous(from) {
    Ok(value) => {
      assert_eq(value.day, 1)
      assert_eq(value.minute, 0)
    }
    Err(_) => fail("expected previous midnight")
  }
  assert_eq(expression.next_n(from, 3).unwrap().length(), 3)
}

///|
test "query bounds a future window" {
  let expression = match parse("*/15 * * * *") {
    Ok(value) => value
    Err(_) => panic()
  }
  let start = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 9,
    minute: 7,
    weekday: 4,
  }
  let end = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 10,
    minute: 0,
    weekday: 4,
  }
  match expression.between(start, end, 10) {
    Ok(values) => {
      assert_eq(values.length(), 4)
      assert_eq(values[0].minute, 15)
      assert_eq(values[2].minute, 45)
      assert_eq(values[3].minute, 0)
    }
    Err(_) => fail("expected three quarter-hour occurrences")
  }
}

///|
test "query explains normalized fields" {
  let expression = match parse("0 9 * JAN MON-FRI") {
    Ok(value) => value
    Err(_) => panic()
  }
  assert_eq(
    expression.explain(),
    "minute=0, hour=9, day_of_month=*, month=1, day_of_week=1-5",
  )
}
