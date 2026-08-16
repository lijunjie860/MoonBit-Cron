///|
test "registry loads and filters operational task definitions" {
  let registry = TaskRegistry::from_document(
    "backup|0 2 * * *|true|3\nreport|0 9 * * 1-5|false|1",
  ).unwrap()
  assert_eq(registry.length(), 2)
  assert_eq(registry.enabled().length(), 1)
  assert_eq(registry.ids(), ["backup", "report"])
  assert_eq(registry.get("backup").unwrap().max_attempts, 3)
  assert_true(registry.remove("report"))
  assert_eq(registry.length(), 1)
}

///|
test "metrics calculate execution health" {
  let metrics = SchedulerMetrics::new()
  metrics.record_scheduled()
  metrics.record_started()
  metrics.record_success()
  metrics.record_started()
  metrics.record_failure(true)
  metrics.record_skip()
  assert_eq(metrics.success_rate(), 50)
  assert_eq(metrics.total_outcomes(), 3)
  assert_eq(metrics.retried, 1)
}
