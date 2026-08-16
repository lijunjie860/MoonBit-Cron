///|
test "configuration loads realistic scheduled jobs" {
  let document = "# production jobs\nbackup|0 2 * * *|true|3\nreport|0 9 * * MON-FRI|true|1\nheartbeat|*/5 * * * *|false|0\n"
  match parse_task_document(document) {
    Ok(specs) => {
      assert_eq(specs.length(), 3)
      assert_eq(specs[0].id, "backup")
      assert_eq(specs[1].expression.to_string(), "0 9 * * 1-5")
      assert_false(specs[2].enabled)
      assert_eq(specs[0].to_line(), "backup|0 2 * * *|true|3")
    }
    Err(message) => fail(message)
  }
}

///|
test "configuration reports malformed lines and duplicates" {
  match
    parse_task_document("backup|0 2 * * *|true|3\nbackup|0 3 * * *|true|3") {
    Err(message) => assert_true(message.contains("duplicate task id"))
    Ok(_) => fail("expected duplicate id error")
  }
  match parse_task_line("broken|0 2 * * *|maybe|3") {
    Err(message) => assert_true(message.contains("true or false"))
    Ok(_) => fail("expected boolean error")
  }
}

///|
test "configuration round trips task documents" {
  let original = "backup|0 2 * * *|true|3\nreport|0 9 * * 1-5|true|1"
  let specs = match parse_task_document(original) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  assert_eq(task_document(specs), original)
}
