///|
/// Lifecycle state of a scheduled task.
pub(all) enum TaskState {
  Enabled
  Disabled
  Completed
  Failed
} derive(Eq, Debug)

///|
/// A named task and its Cron expression.
pub struct CronTask {
  id : String
  expression : CronExpr
  mut state : TaskState
  mut last_run : Time?
  mut next_run : Time?
  mut attempts : Int
  max_attempts : Int
} derive(Debug)

///|
/// Construct an enabled task whose first run is after `from`.
pub fn CronTask::new(
  id : String,
  expression : CronExpr,
  from : Time,
  max_attempts : Int,
) -> Result[CronTask, String] {
  if id.length() == 0 {
    return Err("Task id must not be empty")
  }
  if max_attempts < 0 {
    return Err("Maximum attempts must be non-negative")
  }
  let next_run = match expression.next(from) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  Ok({
    id,
    expression,
    state: Enabled,
    last_run: None,
    next_run: Some(next_run),
    attempts: 0,
    max_attempts,
  })
}

///|
/// Disable a task without removing it from the scheduler.
pub fn CronTask::disable(self : CronTask) -> Unit {
  self.state = Disabled
}

///|
/// Enable a disabled task and recalculate its next run.
pub fn CronTask::enable(self : CronTask, from : Time) -> Result[Unit, String] {
  let next_run = match self.expression.next(from) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  self.state = Enabled
  self.next_run = Some(next_run)
  Ok(())
}

///|
/// Mark a task execution as successful and calculate its following run.
pub fn CronTask::record_success(
  self : CronTask,
  at : Time,
) -> Result[Unit, String] {
  self.last_run = Some(at)
  self.attempts = 0
  match self.expression.next(at) {
    Ok(value) => {
      self.next_run = Some(value)
      Ok(())
    }
    Err(message) => {
      self.state = Completed
      self.next_run = None
      Err(message)
    }
  }
}

///|
/// Mark a failed execution and apply the retry policy.
pub fn CronTask::record_failure(self : CronTask, at : Time) -> Unit {
  self.last_run = Some(at)
  self.attempts = self.attempts + 1
  if self.max_attempts > 0 && self.attempts >= self.max_attempts {
    self.state = Failed
  }
}

///|
/// Whether this task is ready to run at the supplied time.
pub fn CronTask::is_due(self : CronTask, now : Time) -> Bool {
  match self.state {
    Enabled =>
      match self.next_run {
        Some(next) => next.compare(now) <= 0
        None => false
      }
    _ => false
  }
}

///|
/// A deterministic in-memory collection of scheduled tasks.
pub struct Scheduler {
  tasks : Array[CronTask]
} derive(Debug)

///|
/// Construct an empty scheduler.
pub fn Scheduler::new() -> Scheduler {
  { tasks: [] }
}

///|
/// Add a task, rejecting duplicate identifiers.
pub fn Scheduler::add(
  self : Scheduler,
  task : CronTask,
) -> Result[Unit, String] {
  for existing in self.tasks {
    if existing.id == task.id {
      return Err("Task id already exists: {task.id}")
    }
  }
  self.tasks.push(task)
  Ok(())
}

///|
/// Remove a task by identifier.
pub fn Scheduler::remove(self : Scheduler, id : String) -> Bool {
  for index, task in self.tasks {
    if task.id == id {
      let _ = self.tasks.remove(index)
      return true
    }
  }
  false
}

///|
/// Return identifiers of all tasks due at `now`, preserving insertion order.
pub fn Scheduler::due(self : Scheduler, now : Time) -> Array[String] {
  let result = []
  for task in self.tasks {
    if task.is_due(now) {
      result.push(task.id)
    }
  }
  result
}

///|
/// Find a task by id without exposing scheduler internals to callers.
pub fn Scheduler::find(self : Scheduler, id : String) -> CronTask? {
  for task in self.tasks {
    if task.id == id {
      return Some(task)
    }
  }
  None
}

///|
/// Disable a task selected by identifier.
pub fn Scheduler::disable(self : Scheduler, id : String) -> Bool {
  for task in self.tasks {
    if task.id == id {
      task.disable()
      return true
    }
  }
  false
}

///|
/// Enable a task selected by identifier.
pub fn Scheduler::enable(
  self : Scheduler,
  id : String,
  from : Time,
) -> Result[Bool, String] {
  for task in self.tasks {
    if task.id == id {
      match task.enable(from) {
        Ok(_) => return Ok(true)
        Err(message) => return Err(message)
      }
    }
  }
  Ok(false)
}

///|
/// Record a successful run for one task.
pub fn Scheduler::record_success(
  self : Scheduler,
  id : String,
  at : Time,
) -> Result[Bool, String] {
  for task in self.tasks {
    if task.id == id {
      match task.record_success(at) {
        Ok(_) => return Ok(true)
        Err(message) => return Err(message)
      }
    }
  }
  Ok(false)
}

///|
/// Record a failed run for one task.
pub fn Scheduler::record_failure(
  self : Scheduler,
  id : String,
  at : Time,
) -> Bool {
  for task in self.tasks {
    if task.id == id {
      task.record_failure(at)
      return true
    }
  }
  false
}

///|
/// Return the earliest next run among enabled tasks.
pub fn Scheduler::next_due(self : Scheduler) -> (String, Time)? {
  let mut selected : (String, Time)? = None
  for task in self.tasks {
    if task.state is Enabled {
      match task.next_run {
        Some(candidate) =>
          match selected {
            None => selected = Some((task.id, candidate))
            Some((_, current)) =>
              if candidate.compare(current) < 0 {
                selected = Some((task.id, candidate))
              }
          }
        None => ()
      }
    }
  }
  selected
}

///|
/// Count tasks in a lifecycle state.
pub fn Scheduler::count_state(self : Scheduler, state : TaskState) -> Int {
  let mut count = 0
  for task in self.tasks {
    if task.state == state {
      count = count + 1
    }
  }
  count
}

///|
/// Number of tasks currently stored.
pub fn Scheduler::length(self : Scheduler) -> Int {
  self.tasks.length()
}
