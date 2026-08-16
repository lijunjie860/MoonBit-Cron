///|
test "preflight blocks risky schedules and accepts normal workloads" {
  let limits = SchedulerLimits::new(10, 100, 3).unwrap()
  let normal = TaskRegistry::from_document("backup|0 2 * * *|true|2").unwrap()
  assert_true(preflight(normal, limits).ready())
  let risky = TaskRegistry::from_document("heartbeat|* * * * *|true|0").unwrap()
  assert_false(preflight(risky, limits).ready())
}
