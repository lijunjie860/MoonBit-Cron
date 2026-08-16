///|
test "conflict detector finds simultaneous production jobs" {
  let time = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 2,
    minute: 0,
    weekday: 4,
  }
  let policy = RetryPolicy::new(1, 0, 1, 0).unwrap()
  let plans = [
    ExecutionPlan::new("backup", time, 1, policy).unwrap(),
    ExecutionPlan::new("report", time, 1, policy).unwrap(),
  ]
  let conflicts = detect_conflicts(plans)
  assert_eq(conflicts.length(), 1)
  assert_true(conflicts[0].describe().contains("backup"))
}
