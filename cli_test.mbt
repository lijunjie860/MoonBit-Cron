///|
test "cli parses validation and time commands" {
  match parse_cli(["validate", "*/15 * * * *"]) {
    Ok(Validate(expression)) => assert_eq(expression, "*/15 * * * *")
    _ => fail("expected validate command")
  }
  match parse_cli(["next", "0 9 * * 1-5", "2026-01-05-08-30"]) {
    Ok(Next(_, time)) => {
      assert_eq(time.year, 2026)
      assert_eq(time.weekday, 1)
    }
    _ => fail("expected next command")
  }
}

///|
test "cli rejects malformed time and benchmark arguments" {
  assert_true(parse_cli(["next", "* * * * *", "bad"]) is Err(_))
  assert_true(parse_cli(["benchmark", "* * * * *", "0"]) is Err(_))
  assert_true(parse_cli(["unknown"]) is Err(_))
}

///|
test "benchmark produces deterministic workload report" {
  match benchmark("*/15 * * * *", 8) {
    Ok(report) => {
      assert_eq(report.iterations, 8)
      assert_eq(report.parsed, 8)
      assert_eq(report.next_runs, 8)
    }
    Err(message) => fail(message)
  }
}
