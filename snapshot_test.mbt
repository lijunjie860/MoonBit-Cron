///|
test "scheduler snapshots expose due work for recovery" {
  let registry = TaskRegistry::from_document(
    "backup|0 2 * * *|true|2\nreport|0 9 * * *|true|1",
  ).unwrap()
  let now = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 1,
    minute: 59,
    weekday: 4,
  }
  let snapshot = registry_snapshot(registry, now)
  assert_eq(snapshot.task_count(), 2)
  assert_eq(snapshot.due_count(), 0)
  assert_false(snapshot.has_due("backup"))
  assert_true(snapshot.to_string().contains("generated="))
}
