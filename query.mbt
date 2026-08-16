///|
/// Find the previous matching minute before `from`.
pub fn CronExpr::previous(self : CronExpr, from : Time) -> Result[Time, String] {
  let mut current = previous_minute(from)
  let mut iterations = 0
  while iterations < 100000 {
    iterations = iterations + 1
    if self.matches(current) {
      return Ok(current)
    }
    current = previous_minute(current)
  }
  Err(
    "Cannot find previous execution time (unreachable or too far in the past)",
  )
}

///|
/// Return up to `count` future matching timestamps.
pub fn CronExpr::next_n(
  self : CronExpr,
  from : Time,
  count : Int,
) -> Result[Array[Time], String] {
  if count < 0 {
    return Err("Count must be non-negative")
  }
  let result = []
  let mut cursor = from
  for _ in 0..<count {
    let next_time = match self.next(cursor) {
      Ok(value) => value
      Err(message) => return Err(message)
    }
    result.push(next_time)
    cursor = next_time
  }
  Ok(result)
}

///|
/// Return all matching timestamps in the open interval `(start, end]`.
pub fn CronExpr::between(
  self : CronExpr,
  start : Time,
  end : Time,
  limit : Int,
) -> Result[Array[Time], String] {
  if limit < 0 {
    return Err("Limit must be non-negative")
  }
  if start.compare(end) >= 0 {
    return Ok([])
  }
  let result = []
  let mut cursor = start
  while result.length() < limit {
    let next_time = match self.next(cursor) {
      Ok(value) => value
      Err(message) => return Err(message)
    }
    if next_time.compare(end) > 0 {
      break
    }
    result.push(next_time)
    cursor = next_time
  }
  Ok(result)
}

///|
/// Return a human-readable explanation of the five fields.
pub fn CronExpr::explain(self : CronExpr) -> String {
  "minute=\{self.minute.to_string()}, hour=\{self.hour.to_string()}, day_of_month=\{self.day_of_month.to_string()}, month=\{self.month.to_string()}, day_of_week=\{self.day_of_week.to_string()}"
}
