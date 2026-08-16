///|
/// Counters suitable for a scheduler health endpoint or CLI report.
pub struct SchedulerMetrics {
  mut scheduled : Int
  mut started : Int
  mut succeeded : Int
  mut failed : Int
  mut skipped : Int
  mut retried : Int
} derive(Debug, Eq)

///|
pub fn SchedulerMetrics::new() -> SchedulerMetrics {
  { scheduled: 0, started: 0, succeeded: 0, failed: 0, skipped: 0, retried: 0 }
}

///|
pub fn SchedulerMetrics::record_scheduled(self : SchedulerMetrics) -> Unit {
  self.scheduled += 1
}

///|
pub fn SchedulerMetrics::record_started(self : SchedulerMetrics) -> Unit {
  self.started += 1
}

///|
pub fn SchedulerMetrics::record_success(self : SchedulerMetrics) -> Unit {
  self.succeeded += 1
}

///|
pub fn SchedulerMetrics::record_failure(
  self : SchedulerMetrics,
  retry : Bool,
) -> Unit {
  self.failed += 1
  if retry {
    self.retried += 1
  }
}

///|
pub fn SchedulerMetrics::record_skip(self : SchedulerMetrics) -> Unit {
  self.skipped += 1
}

///|
pub fn SchedulerMetrics::success_rate(self : SchedulerMetrics) -> Int {
  if self.started == 0 {
    0
  } else {
    self.succeeded * 100 / self.started
  }
}

///|
pub fn SchedulerMetrics::total_outcomes(self : SchedulerMetrics) -> Int {
  self.succeeded + self.failed + self.skipped
}

///|
pub fn SchedulerMetrics::to_string(self : SchedulerMetrics) -> String {
  "scheduled=\{self.scheduled}, started=\{self.started}, succeeded=\{self.succeeded}, failed=\{self.failed}, skipped=\{self.skipped}, retried=\{self.retried}"
}
