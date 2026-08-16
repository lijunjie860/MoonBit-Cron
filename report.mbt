///|
/// A human-readable operational report for a scheduler deployment.
pub struct SchedulerReport {
  name : String
  generated_at : Time
  registry : TaskRegistry
  metrics : SchedulerMetrics
  health : HealthReport
} derive(Debug)

///|
pub fn SchedulerReport::new(
  name : String,
  generated_at : Time,
  registry : TaskRegistry,
  metrics : SchedulerMetrics,
) -> SchedulerReport {
  let health = HealthReport::from(registry, metrics, 3)
  { name, generated_at, registry, metrics, health }
}

///|
pub fn SchedulerReport::task_count(self : SchedulerReport) -> Int {
  self.registry.length()
}

///|
pub fn SchedulerReport::healthy(self : SchedulerReport) -> Bool {
  self.health.is_ready()
}

///|
pub fn SchedulerReport::lines(self : SchedulerReport) -> Array[String] {
  [
    "Scheduler: \{self.name}",
    "Generated: \{self.generated_at.year}-\{self.generated_at.month}-\{self.generated_at.day}",
    "Tasks: \{self.registry.length()}",
    "Enabled: \{self.registry.enabled().length()}",
    "Metrics: \{self.metrics.to_string()}",
    "Health: \{self.health.to_string()}",
  ]
}

///|
pub fn SchedulerReport::to_string(self : SchedulerReport) -> String {
  self.lines().join("\n")
}

///|
/// Produce one report line per configured task for terminal tables.
pub fn SchedulerReport::task_lines(self : SchedulerReport) -> Array[String] {
  let lines = []
  for spec in self.registry.enabled() {
    lines.push("\{spec.id}: \{spec.expression.to_string()}")
  }
  lines
}
