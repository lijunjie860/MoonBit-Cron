///|
test "scheduler tracks due tasks and rejects duplicates" {
  let expression = match parse("0 * * * *") {
    Ok(value) => value
    Err(_) => panic()
  }
  let now = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 9,
    minute: 0,
    weekday: 4,
  }
  let task = match CronTask::new("backup", expression, now, 3) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  let scheduler = Scheduler::new()
  assert_eq(scheduler.add(task), Ok(()))
  assert_eq(scheduler.length(), 1)
  assert_eq(scheduler.due(now.add_minutes(60)), ["backup"])
  let duplicate = match CronTask::new("backup", expression, now, 3) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  assert_true(scheduler.add(duplicate) is Err(_))
}

///|
test "task lifecycle applies retry policy" {
  let expression = match parse("0 0 * * *") {
    Ok(value) => value
    Err(_) => panic()
  }
  let now = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let task = match CronTask::new("report", expression, now, 2) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  task.record_failure(now)
  assert_eq(task.state, Enabled)
  task.record_failure(now)
  assert_eq(task.state, Failed)
}

///|
test "task success schedules the following occurrence" {
  let expression = match parse("0 0 * * *") {
    Ok(value) => value
    Err(_) => panic()
  }
  let now = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let task = match CronTask::new("heartbeat", expression, now, 0) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  match task.record_success(now) {
    Ok(_) =>
      match task.next_run {
        Some(next) => assert_eq(next.day, 2)
        None => fail("expected next run")
      }
    Err(message) => fail(message)
  }
}
