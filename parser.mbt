///|
priv enum FieldKind {
  Numeric
  Month
  Weekday
}

///|
pub fn parse(cron_str : String) -> Result[CronExpr, String] {
  let parts = split_spaces(cron_str)
  if parts.length() != 5 {
    return Err("Invalid cron expression: must have exactly 5 fields")
  }

  let minute = match parse_field(parts[0], 0, 59, Numeric) {
    Ok(v) => v
    Err(e) => return Err("Failed to parse minute: \{e}")
  }
  let hour = match parse_field(parts[1], 0, 23, Numeric) {
    Ok(v) => v
    Err(e) => return Err("Failed to parse hour: \{e}")
  }
  let day_of_month = match parse_field(parts[2], 1, 31, Numeric) {
    Ok(v) => v
    Err(e) => return Err("Failed to parse day_of_month: \{e}")
  }
  let month = match parse_field(parts[3], 1, 12, Month) {
    Ok(v) => v
    Err(e) => return Err("Failed to parse month: \{e}")
  }
  let day_of_week = match parse_field(parts[4], 0, 6, Weekday) {
    Ok(v) => v
    Err(e) => return Err("Failed to parse day_of_week: \{e}")
  }

  Ok({ minute, hour, day_of_month, month, day_of_week })
}

///|
fn split_spaces(s : String) -> Array[String] {
  let res = []
  let mut start = -1
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == ' ' || c == '\t' {
      if start != -1 {
        res.push(s[start:i].to_owned())
        start = -1
      }
    } else if start == -1 {
      start = i
    }
  }
  if start != -1 {
    res.push(s[start:s.length()].to_owned())
  }
  res
}

///|
fn split_comma(s : String) -> Array[String] {
  let res = []
  let mut start = 0
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == ',' {
      res.push(s[start:i].to_owned())
      start = i + 1
    }
  }
  res.push(s[start:s.length()].to_owned())
  res
}

///|
fn parse_number(s : String, kind : FieldKind) -> Result[Int, String] {
  if s.length() == 0 {
    return Err("Empty numeric value")
  }
  match named_value(s, kind) {
    Some(value) => return Ok(value)
    None => ()
  }
  let mut num = 0
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c >= '0' && c <= '9' {
      num = num * 10 + (c.to_int() - '0'.to_int())
      if num > 1000 {
        return Err("Numeric value is too large")
      }
    } else {
      return Err("Invalid numeric value: \{s}")
    }
  }
  Ok(num)
}

///|
fn named_value(s : String, kind : FieldKind) -> Int? {
  match kind {
    Numeric => None
    Month =>
      match s {
        "JAN" => Some(1)
        "FEB" => Some(2)
        "MAR" => Some(3)
        "APR" => Some(4)
        "MAY" => Some(5)
        "JUN" => Some(6)
        "JUL" => Some(7)
        "AUG" => Some(8)
        "SEP" => Some(9)
        "OCT" => Some(10)
        "NOV" => Some(11)
        "DEC" => Some(12)
        _ => None
      }
    Weekday =>
      match s {
        "SUN" => Some(0)
        "MON" => Some(1)
        "TUE" => Some(2)
        "WED" => Some(3)
        "THU" => Some(4)
        "FRI" => Some(5)
        "SAT" => Some(6)
        _ => None
      }
  }
}

///|
fn parse_field(
  s : String,
  min : Int,
  max : Int,
  kind : FieldKind,
) -> Result[CronField, String] {
  let mut has_comma = false
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == ',' {
      has_comma = true
      break
    }
  }
  if has_comma {
    let parts = split_comma(s)
    let list = []
    for i = 0; i < parts.length(); i = i + 1 {
      let part = parts[i]
      let field = match parse_single_item(part, min, max, kind) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      list.push(field)
    }
    return Ok(List(list))
  }
  parse_single_item(s, min, max, kind)
}

///|
fn parse_single_item(
  s : String,
  min : Int,
  max : Int,
  kind : FieldKind,
) -> Result[CronField, String] {
  // Check for step '/'
  let mut slash_idx = -1
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == '/' {
      slash_idx = i
      break
    }
  }

  if slash_idx != -1 {
    let base_str = s[0:slash_idx].to_owned()
    let step_str = s[slash_idx + 1:s.length()].to_owned()

    let step_num = match parse_number(step_str, Numeric) {
      Ok(v) => v
      Err(e) => return Err(e)
    }

    let base_field = match parse_single_item(base_str, min, max, kind) {
      Ok(v) => v
      Err(e) => return Err(e)
    }

    if step_num <= 0 {
      return Err("Invalid step size: must be > 0")
    }

    return Ok(Step(base_field, step_num))
  }

  if s == "*" {
    return Ok(All)
  }

  // Check for range '-'
  let mut dash_idx = -1
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == '-' {
      dash_idx = i
      break
    }
  }

  if dash_idx != -1 {
    let start_str = s[0:dash_idx].to_owned()
    let end_str = s[dash_idx + 1:s.length()].to_owned()
    let start_num = match parse_number(start_str, kind) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    let end_num = match parse_number(end_str, kind) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    if start_num < min || start_num > max || end_num < min || end_num > max {
      return Err("Range value out of bounds: expected \{min}-\{max}")
    }
    if start_num > end_num {
      return Err("Invalid range: start > end")
    }
    return Ok(Range(start_num, end_num))
  }

  // Try to parse as integer
  let num = match parse_number(s, kind) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  if num < min || num > max {
    return Err("Value out of bounds: expected \{min}-\{max}")
  }
  Ok(Value(num))
}
