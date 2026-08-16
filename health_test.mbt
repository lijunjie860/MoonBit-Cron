///|
test "health report distinguishes normal and failing schedulers" {
  let registry = TaskRegistry::from_document("backup|0 2 * * *|true|3").unwrap()
  let metrics = SchedulerMetrics::new()
  let healthy = HealthReport::from(registry, metrics, 2)
  assert_eq(healthy.state, Healthy)
  assert_true(healthy.is_ready())
  metrics.record_failure(false)
  metrics.record_failure(false)
  metrics.record_failure(false)
  let unhealthy = HealthReport::from(registry, metrics, 2)
  assert_eq(unhealthy.state, Unhealthy)
  assert_false(unhealthy.is_ready())
}
