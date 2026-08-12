///|
pub fn CronExpr::matches(self : CronExpr, time : Time) -> Bool {
  let min_match = self.minute.matches(time.minute)
  let hour_match = self.hour.matches(time.hour)
  let month_match = self.month.matches(time.month)

  let dom_restricted = match self.day_of_month {
    All => false
    _ => true
  }
  let dow_restricted = match self.day_of_week {
    All => false
    _ => true
  }

  let day_match = if dom_restricted && dow_restricted {
    self.day_of_month.matches(time.day) ||
    self.day_of_week.matches(time.weekday)
  } else {
    self.day_of_month.matches(time.day) &&
    self.day_of_week.matches(time.weekday)
  }

  min_match && hour_match && month_match && day_match
}

///|
fn CronField::matches(self : CronField, value : Int) -> Bool {
  match self {
    All => true
    Value(n) => n == value
    Range(start, end) => value >= start && value <= end
    Step(base, step) =>
      match base {
        All => value % step == 0
        Range(start, end) =>
          value >= start && value <= end && (value - start) % step == 0
        Value(n) => n == value
        Step(_, _) => false
        List(_) => false
      }
    List(arr) => {
      for i = 0; i < arr.length(); i = i + 1 {
        if arr[i].matches(value) {
          return true
        }
      }
      false
    }
  }
}

///|
pub fn CronExpr::next(self : CronExpr, from : Time) -> Result[Time, String] {
  let mut current = add_minute(from)
  let mut iterations = 0

  while iterations < 100000 {
    iterations = iterations + 1

    if !self.month.matches(current.month) {
      current.month = current.month + 1
      if current.month > 12 {
        current.month = 1
        current.year = current.year + 1
      }
      current.day = 1
      current.hour = 0
      current.minute = 0
      current.weekday = weekday(current.year, current.month, current.day)
      continue
    }

    let dom_restricted = match self.day_of_month {
      All => false
      _ => true
    }
    let dow_restricted = match self.day_of_week {
      All => false
      _ => true
    }
    let day_match = if dom_restricted && dow_restricted {
      self.day_of_month.matches(current.day) ||
      self.day_of_week.matches(current.weekday)
    } else {
      self.day_of_month.matches(current.day) &&
      self.day_of_week.matches(current.weekday)
    }

    if !day_match {
      current.day = current.day + 1
      if current.day > days_in_month(current.year, current.month) {
        current.day = 1
        current.month = current.month + 1
        if current.month > 12 {
          current.month = 1
          current.year = current.year + 1
        }
      }
      current.hour = 0
      current.minute = 0
      current.weekday = weekday(current.year, current.month, current.day)
      continue
    }

    if !self.hour.matches(current.hour) {
      current.hour = current.hour + 1
      if current.hour > 23 {
        current.hour = 0
        current.day = current.day + 1
        if current.day > days_in_month(current.year, current.month) {
          current.day = 1
          current.month = current.month + 1
          if current.month > 12 {
            current.month = 1
            current.year = current.year + 1
          }
        }
        current.weekday = weekday(current.year, current.month, current.day)
      }
      current.minute = 0
      continue
    }

    if !self.minute.matches(current.minute) {
      current = add_minute(current)
      continue
    }

    return Ok(current)
  }

  Err("Cannot find next execution time (unreachable or too far in the future)")
}
