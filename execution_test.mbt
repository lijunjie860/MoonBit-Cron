///|
test "execution plans cover enabled operational tasks" {
  let registry = TaskRegistry::from_document(
    "backup|0 2 * * *|true|3\nreport|0 9 * * 1-5|false|1",
  ).unwrap()
  let start = Time::{
    year: 2026,
    month: 1,
    day: 5,
    hour: 0,
    minute: 0,
    weekday: 1,
  }
  let end = Time::{
    year: 2026,
    month: 1,
    day: 5,
    hour: 23,
    minute: 59,
    weekday: 1,
  }
  let window = TimeWindow::new(start, end).unwrap()
  let policy = RetryPolicy::new(3, 5, 2, 30).unwrap()
  let plans = plan_window(registry, window, policy, 5).unwrap()
  assert_eq(plans.length(), 1)
  assert_eq(plans[0].task_id, "backup")
  assert_eq(plans[0].attempt, 1)
}

///|
test "execution plans produce records and retry summaries" {
  let policy = RetryPolicy::new(3, 5, 2, 30).unwrap()
  let time = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 2,
    minute: 0,
    weekday: 4,
  }
  let plan = ExecutionPlan::new("backup", time, 1, policy).unwrap()
  let record = plan.start(time)
  assert_eq(record.task_id, "backup")
  let success = plan.success()
  assert_true(success.succeeded)
  let failure = plan.failure(time, "temporary network outage")
  assert_false(failure.succeeded)
  assert_eq(failure.next_retry, Some(5))
}
