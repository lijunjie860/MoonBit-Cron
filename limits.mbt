///|
/// Deployment limits that prevent accidental high-volume schedules.
pub struct SchedulerLimits {
  max_tasks : Int
  max_window_results : Int
  max_retry_attempts : Int
} derive(Debug, Eq)

///|
pub fn SchedulerLimits::new(
  max_tasks : Int,
  max_window_results : Int,
  max_retry_attempts : Int,
) -> Result[SchedulerLimits, String] {
  if max_tasks < 1 || max_window_results < 1 || max_retry_attempts < 0 {
    return Err("Scheduler limits must be positive")
  }
  Ok({ max_tasks, max_window_results, max_retry_attempts })
}

///|
pub fn SchedulerLimits::check_registry(
  self : SchedulerLimits,
  registry : TaskRegistry,
) -> Result[Unit, String] {
  if registry.length() > self.max_tasks {
    return Err("Task registry exceeds configured capacity")
  }
  for spec in registry.enabled() {
    if spec.max_attempts > self.max_retry_attempts {
      return Err("Task retry count exceeds configured capacity")
    }
  }
  Ok(())
}

///|
pub fn SchedulerLimits::check_window(
  self : SchedulerLimits,
  values : Array[Time],
) -> Result[Unit, String] {
  if values.length() > self.max_window_results {
    Err("Schedule window exceeds configured capacity")
  } else {
    Ok(())
  }
}
