///|
/// Simple per-task rate limiter for high-frequency schedules.
pub struct RateLimiter {
  interval : Int
  mut last_run : Time?
} derive(Debug)

///|
pub fn RateLimiter::new(interval : Int) -> Result[RateLimiter, String] {
  if interval < 1 {
    Err("Rate limit interval must be positive")
  } else {
    Ok({ interval, last_run: None })
  }
}

///|
pub fn RateLimiter::allows(self : RateLimiter, at : Time) -> Bool {
  match self.last_run {
    None => true
    Some(previous) =>
      match previous.minutes_until(at, self.interval) {
        Some(distance) => distance >= self.interval
        None => false
      }
  }
}

///|
pub fn RateLimiter::record(self : RateLimiter, at : Time) -> Bool {
  if self.allows(at) {
    self.last_run = Some(at)
    true
  } else {
    false
  }
}

///|
pub fn RateLimiter::remaining(self : RateLimiter, at : Time) -> Int {
  match self.last_run {
    None => 0
    Some(previous) =>
      match previous.minutes_until(at, self.interval) {
        Some(distance) =>
          if distance >= self.interval {
            0
          } else {
            self.interval - distance
          }
        None => self.interval
      }
  }
}
