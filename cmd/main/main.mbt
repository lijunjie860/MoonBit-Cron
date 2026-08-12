///|
/// Demonstrates parsing, matching, and calculating the next Cron trigger.
/// Run with `moon run cmd/main` from the module root.
fn main {
  let expression = "*/15 9-17 * * 1-5"
  let now = @cron.Time::{
    year: 2026,
    month: 10,
    day: 15,
    hour: 9,
    minute: 7,
    weekday: 4,
  }
  match @cron.parse(expression) {
    Err(message) => println("Parse error: \{message}")
    Ok(expr) => {
      println("Expression: \{expression}")
      println("Canonical: \{expr.to_string()}")
      println("Matches now: \{expr.matches(now)}")
      match expr.next(now) {
        Err(message) => println("Schedule error: \{message}")
        Ok(next_time) =>
          println(
            "Next trigger: \{next_time.year}-\{next_time.month}-\{next_time.day} \{next_time.hour}:\{next_time.minute} (weekday \{next_time.weekday})",
          )
      }
    }
  }
}
