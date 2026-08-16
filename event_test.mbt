///|
test "event filters preserve task execution history" {
  let time = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 2,
    minute: 0,
    weekday: 4,
  }
  let events : Array[SchedulerEvent] = [
    Scheduled("backup", time),
    Started("backup", time),
    Succeeded("backup", time),
    Scheduled("report", time),
  ]
  assert_eq(filter_task_events(events, "backup").length(), 3)
  assert_true(event_is_terminal(events[2]))
  assert_eq(event_summary(events), "scheduled=2, terminal=1")
}
