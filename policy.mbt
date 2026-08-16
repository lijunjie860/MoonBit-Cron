///|
/// Policy for handling a task that is already running when another trigger arrives.
pub(all) enum ConcurrencyMode {
  Allow
  Skip
  Queue
} derive(Debug, Eq)

///|
pub struct ConcurrencyPolicy {
  mode : ConcurrencyMode
  max_running : Int
  max_queued : Int
} derive(Debug, Eq)

///|
pub fn ConcurrencyPolicy::new(
  mode : ConcurrencyMode,
  max_running : Int,
  max_queued : Int,
) -> Result[ConcurrencyPolicy, String] {
  if max_running < 1 || max_queued < 0 {
    return Err("Concurrency limits are invalid")
  }
  Ok({ mode, max_running, max_queued })
}

///|
pub fn ConcurrencyPolicy::admit(
  self : ConcurrencyPolicy,
  running : Int,
  queued : Int,
) -> Bool {
  match self.mode {
    Allow => running < self.max_running
    Skip => running == 0
    Queue => running < self.max_running || queued < self.max_queued
  }
}

///|
pub fn ConcurrencyPolicy::mode(self : ConcurrencyPolicy) -> ConcurrencyMode {
  self.mode
}

///|
pub fn ConcurrencyPolicy::describe(self : ConcurrencyPolicy) -> String {
  let mode = match self.mode {
    Allow => "allow"
    Skip => "skip"
    Queue => "queue"
  }
  "mode=\{mode}, max_running=\{self.max_running}, max_queued=\{self.max_queued}"
}
