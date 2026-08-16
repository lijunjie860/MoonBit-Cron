///|
/// A collision between two task occurrences in a bounded window.
pub struct ScheduleConflict {
  first_task : String
  second_task : String
  at : Time
} derive(Debug, Eq)

///|
pub fn ScheduleConflict::describe(self : ScheduleConflict) -> String {
  "\{self.first_task} conflicts with \{self.second_task} at \{format_time(self.at)}"
}

///|
/// Detect same-minute collisions among execution plans.
pub fn detect_conflicts(
  plans : Array[ExecutionPlan],
) -> Array[ScheduleConflict] {
  let conflicts = []
  for left_index, left in plans {
    for right_index, right in plans {
      if left_index < right_index &&
        left.scheduled_for.compare(right.scheduled_for) == 0 {
        conflicts.push({
          first_task: left.task_id,
          second_task: right.task_id,
          at: left.scheduled_for,
        })
      }
    }
  }
  conflicts
}

///|
pub fn conflict_messages(conflicts : Array[ScheduleConflict]) -> Array[String] {
  conflicts.map(fn(conflict) { conflict.describe() })
}
