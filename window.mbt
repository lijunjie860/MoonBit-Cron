///|
/// A closed interval of valid timestamps used for schedule queries.
pub struct TimeWindow {
  start : Time
  end : Time
} derive(Debug, Eq)

///|
pub fn TimeWindow::new(start : Time, end : Time) -> Result[TimeWindow, String] {
  if !start.is_valid() || !end.is_valid() {
    return Err("Time window contains an invalid timestamp")
  }
  if start.compare(end) > 0 {
    return Err("Time window start must not be after end")
  }
  Ok({ start, end })
}

///|
pub fn TimeWindow::start(self : TimeWindow) -> Time {
  self.start
}

///|
pub fn TimeWindow::end(self : TimeWindow) -> Time {
  self.end
}

///|
pub fn TimeWindow::contains(self : TimeWindow, value : Time) -> Bool {
  self.start.compare(value) <= 0 && value.compare(self.end) <= 0
}

///|
pub fn TimeWindow::minutes(self : TimeWindow, limit : Int) -> Int? {
  self.start.minutes_until(self.end, limit)
}

///|
pub fn CronExpr::window(
  self : CronExpr,
  window : TimeWindow,
  limit : Int,
) -> Result[Array[Time], String] {
  self.between(window.start, window.end, limit)
}

///|
/// Return the next trigger only when it falls inside a window.
pub fn CronExpr::next_in(
  self : CronExpr,
  window : TimeWindow,
  from : Time,
) -> Result[Time, String] {
  let next = match self.next(from) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  if window.contains(next) {
    Ok(next)
  } else {
    Err("No trigger exists inside the requested time window")
  }
}

///|
/// A reusable business-hours rule for reports and operational jobs.
pub struct BusinessHours {
  first_hour : Int
  last_hour : Int
  weekdays : Array[Int]
} derive(Debug, Eq)

///|
pub fn BusinessHours::new(
  first_hour : Int,
  last_hour : Int,
  weekdays : Array[Int],
) -> Result[BusinessHours, String] {
  if first_hour < 0 ||
    first_hour > 23 ||
    last_hour < first_hour ||
    last_hour > 23 {
    return Err("Business hours must be between 0 and 23")
  }
  for day in weekdays {
    if day < 0 || day > 6 {
      return Err("Weekdays must use values from 0 through 6")
    }
  }
  Ok({ first_hour, last_hour, weekdays })
}

///|
pub fn BusinessHours::accepts(self : BusinessHours, value : Time) -> Bool {
  if value.hour < self.first_hour || value.hour > self.last_hour {
    return false
  }
  for day in self.weekdays {
    if day == value.weekday {
      return true
    }
  }
  false
}

///|
pub fn CronExpr::business_window(
  self : CronExpr,
  window : TimeWindow,
  business_hours : BusinessHours,
  limit : Int,
) -> Result[Array[Time], String] {
  if limit < 0 {
    return Err("Limit must be non-negative")
  }
  let values = []
  let mut cursor = window.start
  while values.length() < limit {
    let next = match self.next(cursor) {
      Ok(value) => value
      Err(message) => return Err(message)
    }
    if next.compare(window.end) > 0 {
      break
    }
    if business_hours.accepts(next) {
      values.push(next)
    }
    cursor = next
  }
  Ok(values)
}
