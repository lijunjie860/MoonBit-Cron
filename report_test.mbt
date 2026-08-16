///|
test "scheduler report summarizes configured production jobs" {
  let registry = TaskRegistry::from_document(
    "backup|0 2 * * *|true|3\nreport|0 9 * * 1-5|false|1",
  ).unwrap()
  let metrics = SchedulerMetrics::new()
  let generated = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 12,
    minute: 0,
    weekday: 4,
  }
  let report = SchedulerReport::new("production", generated, registry, metrics)
  assert_eq(report.task_count(), 2)
  assert_true(report.healthy())
  assert_eq(report.task_lines(), ["backup: 0 2 * * *"])
  assert_true(report.to_string().contains("Scheduler:"))
}
