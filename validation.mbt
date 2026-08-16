///|
/// Validation issue reported before a schedule is accepted by a service.
pub(all) enum ValidationSeverity {
  Warning
  Error
} derive(Debug, Eq)

///|
pub struct ValidationIssue {
  severity : ValidationSeverity
  code : String
  message : String
} derive(Debug, Eq)

///|
pub fn ValidationIssue::warning(
  code : String,
  message : String,
) -> ValidationIssue {
  { severity: Warning, code, message }
}

///|
pub fn ValidationIssue::error(
  code : String,
  message : String,
) -> ValidationIssue {
  { severity: Error, code, message }
}

///|
pub fn ValidationIssue::to_string(self : ValidationIssue) -> String {
  let level = match self.severity {
    Warning => "warning"
    Error => "error"
  }
  "\{level}[\{self.code}]: \{self.message}"
}

///|
/// Validate a task specification for deployment.
pub fn validate_task(spec : TaskSpec) -> Array[ValidationIssue] {
  let issues = []
  if spec.id.length() > 64 {
    issues.push(
      ValidationIssue::warning(
        "ID_LENGTH", "task id is longer than 64 characters",
      ),
    )
  }
  if spec.expression.to_string() == "* * * * *" {
    issues.push(
      ValidationIssue::warning("HIGH_FREQUENCY", "task runs every minute"),
    )
  }
  if !spec.enabled {
    issues.push(ValidationIssue::warning("DISABLED", "task is disabled"))
  }
  issues
}

///|
pub fn validate_registry(registry : TaskRegistry) -> Array[ValidationIssue] {
  let issues = []
  for spec in registry.enabled() {
    for issue in validate_task(spec) {
      issues.push(issue)
    }
  }
  issues
}
