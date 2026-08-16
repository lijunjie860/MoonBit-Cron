///|
/// Health state used by monitoring integrations.
pub(all) enum HealthState {
  Healthy
  Degraded
  Unhealthy
} derive(Debug, Eq)

///|
pub struct HealthReport {
  state : HealthState
  task_count : Int
  enabled_count : Int
  failure_count : Int
  message : String
} derive(Debug, Eq)

///|
pub fn HealthReport::from(
  registry : TaskRegistry,
  metrics : SchedulerMetrics,
  failure_limit : Int,
) -> HealthReport {
  let failures = metrics.failed
  let state = if failures > failure_limit {
    Unhealthy
  } else if failures > 0 || registry.enabled().length() == 0 {
    Degraded
  } else {
    Healthy
  }
  let message = match state {
    Healthy => "scheduler is healthy"
    Degraded => "scheduler requires attention"
    Unhealthy => "scheduler has exceeded failure budget"
  }
  {
    state,
    task_count: registry.length(),
    enabled_count: registry.enabled().length(),
    failure_count: failures,
    message,
  }
}

///|
pub fn HealthReport::is_ready(self : HealthReport) -> Bool {
  self.state is Healthy || self.state is Degraded
}

///|
pub fn HealthReport::to_string(self : HealthReport) -> String {
  "state=\{self.message}, tasks=\{self.task_count}, enabled=\{self.enabled_count}, failures=\{self.failure_count}"
}
