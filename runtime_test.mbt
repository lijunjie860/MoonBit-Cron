///|
test "business windows filter realistic report schedules" {
  let expression = match parse("0 9 * * 1-5") {
    Ok(value) => value
    Err(_) => panic()
  }
  let start = Time::{
    year: 2026,
    month: 1,
    day: 5,
    hour: 8,
    minute: 0,
    weekday: 1,
  }
  let end = Time::{
    year: 2026,
    month: 1,
    day: 9,
    hour: 18,
    minute: 0,
    weekday: 5,
  }
  let window = TimeWindow::new(start, end).unwrap()
  let hours = BusinessHours::new(9, 17, [1, 2, 3, 4, 5]).unwrap()
  let values = expression.business_window(window, hours, 10).unwrap()
  assert_eq(values.length(), 5)
  assert_eq(values[0].day, 5)
}

///|
test "retry policy computes bounded exponential delays" {
  let policy = RetryPolicy::new(4, 5, 2, 12).unwrap()
  assert_eq(policy.delay_for(1), Some(5))
  assert_eq(policy.delay_for(2), Some(10))
  assert_eq(policy.delay_for(3), Some(12))
  assert_true(policy.should_retry(1))
  assert_false(policy.should_retry(4))
  assert_eq(policy.decide(2), RetryAfter(10))
}

///|
test "audit log retains bounded execution history" {
  let at = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let log = AuditLog::new(2).unwrap()
  let first = RunRecord::start("backup", at, 1)
  log.append(first.succeed(at.add_minutes(1)))
  log.append(RunRecord::start("report", at, 1).fail(at, "network"))
  log.append(RunRecord::start("backup", at, 2).skip(at, "disabled"))
  assert_eq(log.length(), 2)
  assert_eq(log.successful(), 0)
  assert_eq(log.failed(), 1)
  assert_eq(log.for_task("backup").length(), 1)
}
