///|
test "parse all stars" {
  let res = parse("* * * * *")
  let expected = CronExpr::new(All, All, All, All, All)
  if res != Ok(expected) {
    panic()
  }
}

///|
test "parse numbers" {
  let res = parse("1 2 3 4 5")
  let expected = CronExpr::new(Value(1), Value(2), Value(3), Value(4), Value(5))
  if res != Ok(expected) {
    panic()
  }
}

///|
test "parse invalid length" {
  let res = parse("* * * *")
  match res {
    Err(msg) =>
      if msg != "Invalid cron expression: must have exactly 5 fields" {
        panic()
      }
    _ => panic()
  }
}

///|
test "parse range" {
  let res = parse("1-5 * * * *")
  let expected = CronExpr::new(Range(1, 5), All, All, All, All)
  if res != Ok(expected) {
    panic()
  }
}

///|
test "parse out of bounds" {
  let res1 = parse("60 * * * *")
  match res1 {
    Err(msg) =>
      if msg != "Failed to parse minute: Value out of bounds: expected 0-59" {
        panic()
      }
    _ => panic()
  }

  let res2 = parse("1-60 * * * *")
  match res2 {
    Err(msg) =>
      if msg !=
        "Failed to parse minute: Range value out of bounds: expected 0-59" {
        panic()
      }
    _ => panic()
  }
}

///|
test "parse step" {
  let res = parse("*/5 1-10/2 * * *")
  let expected = CronExpr::new(
    Step(All, 5),
    Step(Range(1, 10), 2),
    All,
    All,
    All,
  )
  if res != Ok(expected) {
    panic()
  }
}

///|
test "parse list" {
  let res = parse("1,2,3 1-5,7-10 * * *")
  let expected = CronExpr::new(
    List([Value(1), Value(2), Value(3)]),
    List([Range(1, 5), Range(7, 10)]),
    All,
    All,
    All,
  )
  if res != Ok(expected) {
    panic()
  }
}

///|
test "parse rejects numeric fields before integer overflow" {
  match
    parse("999999999999999999999999999999999999999999999999999999 * * * *") {
    Err(message) =>
      assert_eq(message, "Failed to parse minute: Numeric value is too large")
    Ok(_) => fail("expected an oversized number to be rejected")
  }
}

///|
test "parse rejects an empty list item" {
  match parse("1,,2 * * * *") {
    Err(message) =>
      assert_eq(message, "Failed to parse minute: Empty numeric value")
    Ok(_) => fail("expected an empty list item to be rejected")
  }
}

///|
test "parse accepts standard month and weekday names" {
  let expected = CronExpr::new(
    Value(0),
    Value(9),
    All,
    List([Value(1), Value(3)]),
    Range(1, 5),
  )
  match parse("0 9 * JAN,MAR MON-FRI") {
    Ok(expression) =>
      if expression != expected {
        fail("named fields produced an unexpected expression")
      }
    Err(message) => fail("expected named fields to parse: \{message}")
  }
}

///|
test "cron expressions round trip through to_string" {
  let source = "*/15 9-17 * 1,3 1-5"
  match parse(source) {
    Ok(expression) => assert_eq(expression.to_string(), source)
    Err(message) => fail("expected expression to parse: \{message}")
  }
}

///|
test "named aliases serialize to deterministic numeric fields" {
  match parse("0 9 * JAN,MAR MON-FRI") {
    Ok(expression) =>
      assert_eq(expression.to_string(), "0 9 * 1,3 1-5")
    Err(message) => fail("expected aliases to parse: \{message}")
  }
}
