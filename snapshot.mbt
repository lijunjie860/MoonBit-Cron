///|
/// Serializable snapshot of scheduler state for diagnostics and recovery.
pub struct SchedulerSnapshot {
  generated_at : Time
  task_ids : Array[String]
  due_ids : Array[String]
  metrics : SchedulerMetrics
} derive(Debug)

///|
pub fn SchedulerSnapshot::capture(
  scheduler : Scheduler,
  now : Time,
  metrics : SchedulerMetrics,
) -> SchedulerSnapshot {
  {
    generated_at: now,
    task_ids: scheduler.tasks.map(fn(task) { task.id }),
    due_ids: scheduler.due(now),
    metrics,
  }
}

///|
pub fn SchedulerSnapshot::task_count(self : SchedulerSnapshot) -> Int {
  self.task_ids.length()
}

///|
pub fn SchedulerSnapshot::due_count(self : SchedulerSnapshot) -> Int {
  self.due_ids.length()
}

///|
pub fn SchedulerSnapshot::to_string(self : SchedulerSnapshot) -> String {
  "generated=\{format_time_iso(self.generated_at)};tasks=\{self.task_ids.join(",")};due=\{self.due_ids.join(",")};\{self.metrics.to_string()}"
}

///|
pub fn SchedulerSnapshot::has_due(
  self : SchedulerSnapshot,
  id : String,
) -> Bool {
  for due_id in self.due_ids {
    if due_id == id {
      return true
    }
  }
  false
}

///|
/// Build a snapshot from a registry when no live scheduler exists yet.
pub fn registry_snapshot(
  registry : TaskRegistry,
  now : Time,
) -> SchedulerSnapshot {
  let scheduler = Scheduler::new()
  for spec in registry.enabled() {
    match CronTask::new(spec.id, spec.expression, now, spec.max_attempts) {
      Ok(task) => ignore(scheduler.add(task))
      Err(_) => ()
    }
  }
  SchedulerSnapshot::capture(scheduler, now, SchedulerMetrics::new())
}
