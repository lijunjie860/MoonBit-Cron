///|
/// Retry policy for task execution failures.
pub struct RetryPolicy {
  max_attempts : Int
  initial_delay : Int
  multiplier : Int
  max_delay : Int
} derive(Debug, Eq)

///|
pub fn RetryPolicy::new(
  max_attempts : Int,
  initial_delay : Int,
  multiplier : Int,
  max_delay : Int,
) -> Result[RetryPolicy, String] {
  if max_attempts < 0 ||
    initial_delay < 0 ||
    multiplier < 1 ||
    max_delay < initial_delay {
    return Err("Invalid retry policy values")
  }
  Ok({ max_attempts, initial_delay, multiplier, max_delay })
}

///|
pub fn RetryPolicy::attempts(self : RetryPolicy) -> Int {
  self.max_attempts
}

///|
pub fn RetryPolicy::delay_for(self : RetryPolicy, attempt : Int) -> Int? {
  if attempt < 1 || attempt > self.max_attempts {
    return None
  }
  let mut delay = self.initial_delay
  for _ in 1..<attempt {
    if delay > self.max_delay / self.multiplier {
      delay = self.max_delay
    } else {
      delay = delay * self.multiplier
    }
  }
  Some(if delay > self.max_delay { self.max_delay } else { delay })
}

///|
pub fn RetryPolicy::should_retry(
  self : RetryPolicy,
  failed_attempt : Int,
) -> Bool {
  failed_attempt >= 1 && failed_attempt < self.max_attempts
}

///|
/// Result of applying a retry policy to one failure.
pub(all) enum RetryDecision {
  RetryAfter(Int)
  Stop
} derive(Debug, Eq)

///|
pub fn RetryPolicy::decide(
  self : RetryPolicy,
  failed_attempt : Int,
) -> RetryDecision {
  if !self.should_retry(failed_attempt) {
    Stop
  } else {
    match self.delay_for(failed_attempt) {
      Some(delay) => RetryAfter(delay)
      None => Stop
    }
  }
}

///|
/// A compact execution summary used by monitoring and reporting code.
pub struct ExecutionSummary {
  task_id : String
  attempts : Int
  succeeded : Bool
  last_error : String?
  next_retry : Int?
} derive(Debug, Eq)

///|
pub fn ExecutionSummary::success(
  task_id : String,
  attempts : Int,
) -> ExecutionSummary {
  { task_id, attempts, succeeded: true, last_error: None, next_retry: None }
}

///|
pub fn ExecutionSummary::failure(
  task_id : String,
  attempts : Int,
  error : String,
  decision : RetryDecision,
) -> ExecutionSummary {
  let next_retry = match decision {
    RetryAfter(delay) => Some(delay)
    Stop => None
  }
  { task_id, attempts, succeeded: false, last_error: Some(error), next_retry }
}
