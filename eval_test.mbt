///|
test "eval match time" {
  let expr = match parse("*/15 1-10/2 1,15 * 1-5") {
    Ok(v) => v
    Err(_) => panic()
  }

  let t1 = Time::{
    year: 2026,
    month: 10,
    day: 15,
    hour: 3,
    minute: 30,
    weekday: 3,
  }
  if !expr.matches(t1) {
    panic()
  }

  let t2 = Time::{
    year: 2026,
    month: 10,
    day: 15,
    hour: 4, // 4-1 = 3 % 2 != 0 -> fails
    minute: 30,
    weekday: 3,
  }
  if expr.matches(t2) {
    panic()
  }
}

///|
test "next trigger basic" {
  let expr = match parse("*/15 * * * *") {
    Ok(v) => v
    Err(_) => panic()
  }

  let t = Time::{
    year: 2026,
    month: 10,
    day: 15,
    hour: 3,
    minute: 31,
    weekday: 4,
  }
  let next_t = match expr.next(t) {
    Ok(v) => v
    Err(_) => panic()
  }
  if next_t.minute != 45 {
    panic()
  }
}

///|
test "next trigger leap year" {
  let expr = match parse("0 0 29 2 *") {
    Ok(v) => v
    Err(_) => panic()
  }
  let t = Time::{ year: 2026, month: 1, day: 1, hour: 0, minute: 0, weekday: 4 }
  let next_t = match expr.next(t) {
    Ok(v) => v
    Err(_) => panic()
  }
  // 2028 is the next leap year
  if next_t.year != 2028 || next_t.month != 2 || next_t.day != 29 {
    panic()
  }
}

///|
test "day of month and day of week use cron OR semantics" {
  let expr = match parse("0 0 13 * 1") {
    Ok(value) => value
    Err(_) => panic()
  }
  let thirteenth = Time::{
    year: 2026,
    month: 5,
    day: 13,
    hour: 0,
    minute: 0,
    weekday: 3,
  }
  let monday = Time::{
    year: 2026,
    month: 5,
    day: 11,
    hour: 0,
    minute: 0,
    weekday: 1,
  }
  let neither = Time::{
    year: 2026,
    month: 5,
    day: 12,
    hour: 0,
    minute: 0,
    weekday: 2,
  }
  assert_true(expr.matches(thirteenth))
  assert_true(expr.matches(monday))
  assert_false(expr.matches(neither))
}

///|
test "next trigger crosses the end of a month" {
  let expr = match parse("0 0 * * *") {
    Ok(value) => value
    Err(_) => panic()
  }
  let from = Time::{
    year: 2026,
    month: 1,
    day: 31,
    hour: 23,
    minute: 59,
    weekday: 6,
  }
  match expr.next(from) {
    Ok(next_time) => {
      assert_eq(next_time.year, 2026)
      assert_eq(next_time.month, 2)
      assert_eq(next_time.day, 1)
      assert_eq(next_time.hour, 0)
      assert_eq(next_time.minute, 0)
      assert_eq(next_time.weekday, 0)
    }
    Err(_) => fail("expected the first minute of the next month")
  }
}
