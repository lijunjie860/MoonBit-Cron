///|
test "compatibility metadata is stable for deployment checks" {
  assert_eq(library_name(), "moonbit_cron")
  assert_eq(library_version(), "0.1.1")
  assert_eq(supported_targets().length(), 4)
  assert_true(compatibility_summary().contains("0.1.1"))
}
