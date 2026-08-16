///|
test "validation flags risky deployment schedules" {
  let frequent = TaskRegistry::from_document("heartbeat|* * * * *|true|0").unwrap()
  let issues = validate_registry(frequent)
  assert_eq(issues.length(), 1)
  assert_true(issues[0].to_string().contains("HIGH_FREQUENCY"))
  let disabled = TaskRegistry::from_document("report|0 9 * * 1-5|false|0").unwrap()
  assert_eq(validate_registry(disabled).length(), 0)
}
