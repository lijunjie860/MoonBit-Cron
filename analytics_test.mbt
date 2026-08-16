///|
test "window analysis counts occurrences and identifies peak load" {
  let registry = TaskRegistry::from_document(
    "fast|*/15 * * * *|true|1\nslow|0 * * * *|true|1\noff|0 0 * * *|false|1",
  ).unwrap()
  let start = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let end = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 1,
    minute: 0,
    weekday: 4,
  }
  let window = TimeWindow::new(start, end).unwrap()
  let report = analyze_window(registry, window, 20).unwrap()
  assert_eq(report.total(), 5)
  assert_eq(report.task_count(), 2)
  match report.peak() {
    Some(load) => {
      assert_eq(load.task_id(), "fast")
      assert_eq(load.count(), 4)
      assert_true(load.first_run() is Some(_))
      assert_true(load.last_run() is Some(_))
    }
    None => fail("expected peak task")
  }
  assert_true(fits_budget(report, 5))
  assert_false(fits_budget(report, 4))
  assert_eq(utilization_percent(report, 10), 50)
}

///|
test "analysis renders deterministic exports and histogram" {
  let registry = TaskRegistry::from_document("daily|0 0 * * *|true|1").unwrap()
  let start = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let end = Time::{
    year: 2026,
    month: 1,
    day: 3,
    hour: 0,
    minute: 0,
    weekday: 6,
  }
  let report = analyze_window(
    registry,
    TimeWindow::new(start, end).unwrap(),
    10,
  ).unwrap()
  let histogram = occurrence_histogram(report)
  assert_eq(histogram[2], 1)
  assert_true(render_load_table(report).contains("daily"))
  assert_true(analysis_csv(report).contains("occurrences"))
  assert_eq(busiest_tasks(report, 1), ["daily"])
  assert_eq(analysis_health(report, 3), Healthy)
}

///|
test "analysis handles empty windows and capacity warnings" {
  let registry = TaskRegistry::from_document("hour|0 * * * *|true|1").unwrap()
  let start = Time::{
    year: 2026,
    month: 1,
    day: 2,
    hour: 0,
    minute: 1,
    weekday: 5,
  }
  let end = Time::{
    year: 2026,
    month: 1,
    day: 2,
    hour: 0,
    minute: 2,
    weekday: 5,
  }
  let report = analyze_window(registry, TimeWindow::new(start, end).unwrap(), 3).unwrap()
  assert_eq(report.total(), 0)
  assert_eq(report.rejected_count(), 0)
  assert_eq(utilization_percent(report, 0), 0)
  assert_eq(analysis_health(report, 0), Healthy)
}
