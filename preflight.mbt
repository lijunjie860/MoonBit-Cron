///|
/// Preflight result used before starting a scheduler process.
pub struct PreflightResult {
  ready : Bool
  issues : Array[String]
} derive(Debug, Eq)

///|
pub fn preflight(
  registry : TaskRegistry,
  limits : SchedulerLimits,
) -> PreflightResult {
  let issues = []
  match limits.check_registry(registry) {
    Ok(_) => ()
    Err(message) => issues.push(message)
  }
  for issue in validate_registry(registry) {
    issues.push(issue.to_string())
  }
  { ready: issues.length() == 0, issues }
}

///|
pub fn PreflightResult::ready(self : PreflightResult) -> Bool {
  self.ready
}

///|
pub fn PreflightResult::issues(self : PreflightResult) -> Array[String] {
  self.issues
}

///|
pub fn PreflightResult::summary(self : PreflightResult) -> String {
  if self.ready {
    "preflight=ready"
  } else {
    "preflight=blocked;issues=\{self.issues.length()}"
  }
}
