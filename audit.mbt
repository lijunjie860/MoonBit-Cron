///|
/// Outcome of an execution recorded by the scheduler.
pub(all) enum RunOutcome {
  Started
  Succeeded
  Failed
  Skipped
} derive(Debug, Eq)

///|
pub struct RunRecord {
  task_id : String
  started_at : Time
  finished_at : Time?
  outcome : RunOutcome
  message : String?
  attempt : Int
} derive(Debug, Eq)

///|
pub fn RunRecord::start(
  task_id : String,
  at : Time,
  attempt : Int,
) -> RunRecord {
  {
    task_id,
    started_at: at,
    finished_at: None,
    outcome: Started,
    message: None,
    attempt,
  }
}

///|
pub fn RunRecord::succeed(self : RunRecord, at : Time) -> RunRecord {
  { ..self, finished_at: Some(at), outcome: Succeeded, message: None }
}

///|
pub fn RunRecord::fail(
  self : RunRecord,
  at : Time,
  message : String,
) -> RunRecord {
  { ..self, finished_at: Some(at), outcome: Failed, message: Some(message) }
}

///|
pub fn RunRecord::skip(
  self : RunRecord,
  at : Time,
  message : String,
) -> RunRecord {
  { ..self, finished_at: Some(at), outcome: Skipped, message: Some(message) }
}

///|
pub struct AuditLog {
  records : Array[RunRecord]
  capacity : Int
} derive(Debug)

///|
pub fn AuditLog::new(capacity : Int) -> Result[AuditLog, String] {
  if capacity < 1 {
    return Err("Audit capacity must be positive")
  }
  Ok({ records: [], capacity })
}

///|
pub fn AuditLog::append(self : AuditLog, record : RunRecord) -> Unit {
  self.records.push(record)
  if self.records.length() > self.capacity {
    let _ = self.records.remove(0)
  }
}

///|
pub fn AuditLog::length(self : AuditLog) -> Int {
  self.records.length()
}

///|
pub fn AuditLog::successful(self : AuditLog) -> Int {
  let mut count = 0
  for record in self.records {
    if record.outcome is Succeeded {
      count = count + 1
    }
  }
  count
}

///|
pub fn AuditLog::failed(self : AuditLog) -> Int {
  let mut count = 0
  for record in self.records {
    if record.outcome is Failed {
      count = count + 1
    }
  }
  count
}

///|
pub fn AuditLog::for_task(
  self : AuditLog,
  task_id : String,
) -> Array[RunRecord] {
  let result = []
  for record in self.records {
    if record.task_id == task_id {
      result.push(record)
    }
  }
  result
}
