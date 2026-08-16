///|
/// Event emitted by a scheduler integration.
pub(all) enum SchedulerEvent {
  Scheduled(String, Time)
  Started(String, Time)
  Succeeded(String, Time)
  Failed(String, Time, String)
  Skipped(String, Time, String)
} derive(Debug, Eq)

///|
pub fn event_task_id(event : SchedulerEvent) -> String {
  match event {
    Scheduled(id, _)
    | Started(id, _)
    | Succeeded(id, _)
    | Failed(id, _, _)
    | Skipped(id, _, _) => id
  }
}

///|
pub fn event_time(event : SchedulerEvent) -> Time {
  match event {
    Scheduled(_, at)
    | Started(_, at)
    | Succeeded(_, at)
    | Failed(_, at, _)
    | Skipped(_, at, _) => at
  }
}

///|
pub fn filter_task_events(
  events : Array[SchedulerEvent],
  id : String,
) -> Array[SchedulerEvent] {
  events.filter(fn(event) { event_task_id(event) == id })
}

///|
pub fn event_is_terminal(event : SchedulerEvent) -> Bool {
  match event {
    Succeeded(_, _) | Failed(_, _, _) | Skipped(_, _, _) => true
    _ => false
  }
}

///|
pub fn event_summary(events : Array[SchedulerEvent]) -> String {
  let mut scheduled = 0
  let mut completed = 0
  for event in events {
    match event {
      Scheduled(_, _) => scheduled += 1
      Succeeded(_, _) | Failed(_, _, _) | Skipped(_, _, _) => completed += 1
      Started(_, _) => ()
    }
  }
  "scheduled=\{scheduled}, terminal=\{completed}"
}
