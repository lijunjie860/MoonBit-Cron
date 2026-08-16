///|
/// Return whether a timestamp contains a valid Gregorian calendar value.
pub fn Time::is_valid(self : Time) -> Bool {
  self.year >= 1 &&
  self.month >= 1 &&
  self.month <= 12 &&
  self.day >= 1 &&
  self.day <= days_in_month(self.year, self.month) &&
  self.hour >= 0 &&
  self.hour <= 23 &&
  self.minute >= 0 &&
  self.minute <= 59 &&
  self.weekday >= 0 &&
  self.weekday <= 6 &&
  self.weekday == weekday(self.year, self.month, self.day)
}

///|
/// Return a copy with the weekday recalculated from the date fields.
pub fn Time::normalized(self : Time) -> Time {
  { ..self, weekday: weekday(self.year, self.month, self.day) }
}

///|
/// Compare two timestamps in chronological order.
pub fn Time::compare(self : Time, other : Time) -> Int {
  if self.year != other.year {
    return if self.year < other.year { -1 } else { 1 }
  }
  if self.month != other.month {
    return if self.month < other.month { -1 } else { 1 }
  }
  if self.day != other.day {
    return if self.day < other.day { -1 } else { 1 }
  }
  if self.hour != other.hour {
    return if self.hour < other.hour { -1 } else { 1 }
  }
  if self.minute != other.minute {
    return if self.minute < other.minute { -1 } else { 1 }
  }
  0
}

///|
/// Add a signed number of minutes and recalculate the weekday.
pub fn Time::add_minutes(self : Time, amount : Int) -> Time {
  let mut result = self.normalized()
  if amount >= 0 {
    for _ in 0..<amount {
      result = add_minute(result)
    }
  } else {
    for _ in 0..<-amount {
      result = previous_minute(result)
    }
  }
  result
}

///|
/// Move one minute backwards.
pub fn previous_minute(t : Time) -> Time {
  let mut minute = t.minute - 1
  let mut hour = t.hour
  let mut day = t.day
  let mut month = t.month
  let mut year = t.year
  if minute < 0 {
    minute = 59
    hour = hour - 1
  }
  if hour < 0 {
    hour = 23
    day = day - 1
  }
  if day < 1 {
    month = month - 1
    if month < 1 {
      month = 12
      year = year - 1
    }
    day = days_in_month(year, month)
  }
  { year, month, day, hour, minute, weekday: weekday(year, month, day) }
}

///|
/// Return the number of minute steps from self to other, when bounded.
pub fn Time::minutes_until(self : Time, other : Time, limit : Int) -> Int? {
  if limit < 0 || self.compare(other) > 0 {
    return None
  }
  let mut cursor = self.normalized()
  for distance in 0..<=limit {
    if cursor.compare(other) == 0 {
      return Some(distance)
    }
    cursor = add_minute(cursor)
  }
  None
}
