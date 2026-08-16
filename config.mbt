///|
/// A serializable task definition for configuration files.
pub struct TaskSpec {
  id : String
  expression : CronExpr
  enabled : Bool
  max_attempts : Int
} derive(Debug, Eq)

///|
/// Construct a validated task definition.
pub fn TaskSpec::new(
  id : String,
  expression : CronExpr,
  enabled : Bool,
  max_attempts : Int,
) -> Result[TaskSpec, String] {
  if id.length() == 0 {
    return Err("Task id must not be empty")
  }
  if max_attempts < 0 {
    return Err("Maximum attempts must be non-negative")
  }
  Ok({ id, expression, enabled, max_attempts })
}

///|
/// Convert a task into a stable pipe-delimited configuration line.
pub fn TaskSpec::to_line(self : TaskSpec) -> String {
  let enabled = if self.enabled { "true" } else { "false" }
  "\{self.id}|\{self.expression.to_string()}|\{enabled}|\{self.max_attempts}"
}

///|
fn split_config_fields(line : String) -> Array[String] {
  let result : Array[String] = []
  let mut start = 0
  for index in 0..<line.length() {
    if line[index] == '|' {
      result.push(line[start:index].to_owned())
      start = index + 1
    }
  }
  result.push(line[start:line.length()].to_owned())
  result
}

///|
fn parse_config_bool(value : String) -> Bool? {
  match value {
    "true" => Some(true)
    "false" => Some(false)
    _ => None
  }
}

///|
fn parse_config_int(value : String) -> Int? {
  if value.length() == 0 {
    return None
  }
  let mut result = 0
  for index in 0..<value.length() {
    let character = value[index]
    if character < '0' || character > '9' {
      return None
    }
    result = result * 10 + character.to_int() - '0'.to_int()
  }
  Some(result)
}

///|
/// Parse one task line in `id|cron expression|enabled|retries` format.
pub fn parse_task_line(line : String) -> Result[TaskSpec, String] {
  let fields = split_config_fields(line)
  if fields.length() != 4 {
    return Err("Task line must contain four pipe-delimited fields")
  }
  let expression = match parse(fields[1]) {
    Ok(value) => value
    Err(message) => return Err("Invalid task expression: \{message}")
  }
  let enabled = match parse_config_bool(fields[2]) {
    Some(value) => value
    None => return Err("Enabled must be true or false")
  }
  let max_attempts = match parse_config_int(fields[3]) {
    Some(value) => value
    None => return Err("Retries must be a non-negative integer")
  }
  TaskSpec::new(fields[0], expression, enabled, max_attempts)
}

///|
fn config_lines(document : String) -> Array[String] {
  let lines = []
  let mut start = 0
  for index in 0..<document.length() {
    if document[index] == '\n' {
      lines.push(document[start:index].to_owned())
      start = index + 1
    }
  }
  if start < document.length() {
    lines.push(document[start:document.length()].to_owned())
  }
  lines
}

///|
/// Parse a complete task document. Blank lines and `#` comments are ignored.
pub fn parse_task_document(
  document : String,
) -> Result[Array[TaskSpec], String] {
  let result : Array[TaskSpec] = []
  for line_number, raw_line in config_lines(document) {
    let line = raw_line.trim()
    if line.length() == 0 || line[0] == '#' {
      continue
    }
    let task = match parse_task_line(line.to_owned()) {
      Ok(value) => value
      Err(message) => return Err("Line \{line_number + 1}: \{message}")
    }
    for existing in result {
      if existing.id == task.id {
        return Err("Line \{line_number + 1}: duplicate task id \{task.id}")
      }
    }
    result.push(task)
  }
  Ok(result)
}

///|
/// Serialize task definitions as a deterministic configuration document.
pub fn task_document(specs : Array[TaskSpec]) -> String {
  let lines = specs.map(fn(spec) { spec.to_line() })
  lines.join("\n")
}
