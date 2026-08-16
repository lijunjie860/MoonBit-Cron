///|
/// Commands supported by the Cron command-line interface.
pub(all) enum CronCommand {
  Help
  Validate(String)
  Explain(String)
  Next(String, Time)
  Previous(String, Time)
  List(String)
  Benchmark(String, Int)
} derive(Debug, Eq)

///|
/// Parse command-line arguments after the executable name.
pub fn parse_cli(args : Array[String]) -> Result[CronCommand, String] {
  if args.length() == 0 {
    return Ok(Help)
  }
  match args[0] {
    "help" | "--help" | "-h" => Ok(Help)
    "validate" => one_expression(args, fn(value) { Validate(value) })
    "explain" => one_expression(args, fn(value) { Explain(value) })
    "list" => one_expression(args, fn(value) { List(value) })
    "next" => parse_time_command(args, false)
    "previous" => parse_time_command(args, true)
    "benchmark" => parse_benchmark_command(args)
    _ => Err("Unknown command: {args[0]}")
  }
}

///|
fn one_expression(
  args : Array[String],
  build : (String) -> CronCommand,
) -> Result[CronCommand, String] {
  if args.length() != 2 {
    return Err("Expected one Cron expression argument")
  }
  Ok(build(args[1]))
}

///|
fn parse_time_value(value : String) -> Result[Time, String] {
  let fields : Array[String] = []
  for field in value.split("-") {
    fields.push(field.to_owned())
  }
  if fields.length() != 5 {
    return Err("Time must use YYYY-MM-DD-hh-mm format")
  }
  let numbers : Array[Int?] = []
  for field in fields {
    numbers.push(parse_integer(field))
  }
  for number in numbers {
    if number is None {
      return Err("Time contains a non-numeric field")
    }
  }
  let year = numbers[0].unwrap()
  let month = numbers[1].unwrap()
  let day = numbers[2].unwrap()
  let hour = numbers[3].unwrap()
  let minute = numbers[4].unwrap()
  let value = Time::{
    year,
    month,
    day,
    hour,
    minute,
    weekday: weekday(year, month, day),
  }
  if !value.is_valid() {
    return Err("Time is outside the Gregorian calendar")
  }
  Ok(value)
}

///|
fn parse_integer(value : String) -> Int? {
  if value.length() == 0 {
    return None
  }
  let mut result = 0
  for character in value {
    if character < '0' || character > '9' {
      return None
    }
    result = result * 10 + character.to_int() - '0'.to_int()
  }
  Some(result)
}

///|
fn parse_time_command(
  args : Array[String],
  backwards : Bool,
) -> Result[CronCommand, String] {
  if args.length() != 3 {
    return Err("Expected an expression and a YYYY-MM-DD-hh-mm timestamp")
  }
  let time = match parse_time_value(args[2]) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  if backwards {
    Ok(Previous(args[1], time))
  } else {
    Ok(Next(args[1], time))
  }
}

///|
fn parse_benchmark_command(args : Array[String]) -> Result[CronCommand, String] {
  if args.length() != 3 {
    return Err("Expected an expression and iteration count")
  }
  match parse_integer(args[2]) {
    Some(iterations) if iterations > 0 => Ok(Benchmark(args[1], iterations))
    _ => Err("Benchmark iterations must be positive")
  }
}

///|
/// Return concise help text suitable for terminal output.
pub fn cli_help() -> String {
  "MoonBit Cron\n\nCommands:\n  validate EXPR\n  explain EXPR\n  next EXPR YYYY-MM-DD-hh-mm\n  previous EXPR YYYY-MM-DD-hh-mm\n  list CONFIG\n  benchmark EXPR ITERATIONS\n"
}
