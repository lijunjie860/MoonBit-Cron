///|
pub fn is_leap_year(year : Int) -> Bool {
  (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

///|
pub fn days_in_month(year : Int, month : Int) -> Int {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(year) { 29 } else { 28 }
    _ => 0
  }
}

///|
pub fn weekday(year : Int, month : Int, day : Int) -> Int {
  let mut m = month
  let mut y = year
  if m < 3 {
    m = m + 12
    y = y - 1
  }
  let k = y % 100
  let j = y / 100
  let h = (day + 13 * (m + 1) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
  let d = (h + 6) % 7
  d
}

///|
pub fn add_minute(t : Time) -> Time {
  let mut min = t.minute + 1
  let mut hour = t.hour
  let mut day = t.day
  let mut month = t.month
  let mut year = t.year

  if min > 59 {
    min = 0
    hour = hour + 1
  }
  if hour > 23 {
    hour = 0
    day = day + 1
  }
  if day > days_in_month(year, month) {
    day = 1
    month = month + 1
  }
  if month > 12 {
    month = 1
    year = year + 1
  }

  { year, month, day, hour, minute: min, weekday: weekday(year, month, day) }
}
