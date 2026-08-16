///|
/// Stable error categories for integrations that need machine-readable failures.
pub(all) enum CronErrorKind {
  InvalidExpression
  InvalidTime
  InvalidConfiguration
  EmptySchedule
  CapacityExceeded
} derive(Debug, Eq)

///|
pub struct CronError {
  kind : CronErrorKind
  message : String
  context : String?
} derive(Debug, Eq)

///|
pub fn CronError::new(kind : CronErrorKind, message : String) -> CronError {
  { kind, message, context: None }
}

///|
pub fn CronError::with_context(self : CronError, context : String) -> CronError {
  { ..self, context: Some(context) }
}

///|
pub fn CronError::kind(self : CronError) -> CronErrorKind {
  self.kind
}

///|
pub fn CronError::message(self : CronError) -> String {
  self.message
}

///|
pub fn CronError::to_string(self : CronError) -> String {
  match self.context {
    Some(value) => "\{self.message} (context: \{value})"
    None => self.message
  }
}
