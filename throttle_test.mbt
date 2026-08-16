///|
test "rate limiter prevents duplicate high-frequency executions" {
  let limiter = RateLimiter::new(15).unwrap()
  let first = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let second = first.add_minutes(5)
  let third = first.add_minutes(15)
  assert_true(limiter.record(first))
  assert_false(limiter.record(second))
  assert_eq(limiter.remaining(second), 10)
  assert_true(limiter.record(third))
}
