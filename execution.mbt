///|
/// A planned execution returned by a scheduler integration.
pub struct ExecutionPlan {
  task_id : String
  scheduled_for : Time
  attempt : Int
  retry_policy : RetryPolicy
} derive(Debug)

///|
pub fn ExecutionPlan::new(
  task_id : String,
  scheduled_for : Time,
  attempt : Int,
  retry_policy : RetryPolicy,
) -> Result[ExecutionPlan, String] {
  if task_id.length() == 0 || attempt < 1 {
    return Err("Execution plans require a task id and positive attempt")
  }
  Ok({ task_id, scheduled_for, attempt, retry_policy })
}

///|
pub fn ExecutionPlan::start(self : ExecutionPlan, at : Time) -> RunRecord {
  RunRecord::start(self.task_id, at, self.attempt)
}

///|
pub fn ExecutionPlan::failure(
  self : ExecutionPlan,
  at : Time,
  error : String,
) -> ExecutionSummary {
  ignore(at)
  ExecutionSummary::failure(
    self.task_id,
    self.attempt,
    error,
    self.retry_policy.decide(self.attempt),
  )
}

///|
pub fn ExecutionPlan::success(self : ExecutionPlan) -> ExecutionSummary {
  ExecutionSummary::success(self.task_id, self.attempt)
}

///|
/// Build plans for all task occurrences in a bounded window.
pub fn plan_window(
  registry : TaskRegistry,
  window : TimeWindow,
  retry_policy : RetryPolicy,
  limit_per_task : Int,
) -> Result[Array[ExecutionPlan], String] {
  if limit_per_task < 0 {
    return Err("Per-task limit must be non-negative")
  }
  let plans = []
  for spec in registry.enabled() {
    let occurrences = match spec.expression.window(window, limit_per_task) {
      Ok(value) => value
      Err(message) => return Err(message)
    }
    for occurrence in occurrences {
      let plan = match
        ExecutionPlan::new(spec.id, occurrence, 1, retry_policy) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      plans.push(plan)
    }
  }
  Ok(plans)
}

///|
/// Render a plan for logs without exposing implementation details.
pub fn ExecutionPlan::describe(self : ExecutionPlan) -> String {
  "task=\{self.task_id}, scheduled=\{self.scheduled_for.year}-\{self.scheduled_for.month}-\{self.scheduled_for.day} \{self.scheduled_for.hour}:\{self.scheduled_for.minute}, attempt=\{self.attempt}"
}
