///|
test "stable errors retain machine-readable context" {
  let error = CronError::new(InvalidConfiguration, "invalid retry count").with_context(
    "backup",
  )
  assert_eq(error.kind(), InvalidConfiguration)
  assert_eq(error.to_string(), "invalid retry count (context: backup)")
}
