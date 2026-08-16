///|
test "scheduler limits protect deployment capacity" {
  let limits = SchedulerLimits::new(2, 10, 3).unwrap()
  let registry = TaskRegistry::from_document("backup|0 2 * * *|true|3").unwrap()
  assert_eq(limits.check_registry(registry), Ok(()))
  let too_many = TaskRegistry::from_document("backup|0 2 * * *|true|4").unwrap()
  assert_true(limits.check_registry(too_many) is Err(_))
  assert_eq(limits.check_window([]), Ok(()))
}
