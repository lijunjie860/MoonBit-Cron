///|
test "formatters support terminal and machine-friendly output" {
  let value = Time::{
    year: 2026,
    month: 1,
    day: 2,
    hour: 3,
    minute: 4,
    weekday: 5,
  }
  assert_eq(format_time(value), "2026-1-2 3:4")
  assert_eq(format_time_iso(value), "2026-1-2T3:4:00")
  assert_eq(format_occurrences([value], Compact), "2026-1-2T3:4:00")
  assert_eq(parse_output_format("lines"), Ok(Lines))
}

///|
test "formatters render task and health summaries" {
  let registry = TaskRegistry::from_document("backup|0 2 * * *|true|3").unwrap()
  let specs = registry.enabled()
  assert_true(format_task_specs(specs, Text).contains("backup"))
  let report = HealthReport::from(registry, SchedulerMetrics::new(), 1)
  assert_true(format_health(report, Lines).contains("tasks"))
}
