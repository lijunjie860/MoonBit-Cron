///|
/// Summary returned by the deterministic benchmark workload.
pub struct BenchmarkReport {
  expression : String
  iterations : Int
  parsed : Int
  matched : Int
  next_runs : Int
} derive(Debug, Eq)

///|
/// Run a backend-independent parser and scheduler workload.
pub fn benchmark(
  expression : String,
  iterations : Int,
) -> Result[BenchmarkReport, String] {
  if iterations <= 0 {
    return Err("Benchmark iterations must be positive")
  }
  let parsed_expression = match parse(expression) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let start = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    weekday: 4,
  }
  let mut parsed = 0
  let mut matched = 0
  let mut next_runs = 0
  let mut cursor = start
  for _ in 0..<iterations {
    parsed = parsed + 1
    if parsed_expression.matches(cursor) {
      matched = matched + 1
    }
    match parsed_expression.next(cursor) {
      Ok(value) => {
        next_runs = next_runs + 1
        cursor = value
      }
      Err(_) => break
    }
  }
  Ok({ expression, iterations, parsed, matched, next_runs })
}

///|
/// Render benchmark output for logs and CI artifacts.
pub fn BenchmarkReport::to_string(self : BenchmarkReport) -> String {
  "expression=\{self.expression}\niterations=\{self.iterations}\nparsed=\{self.parsed}\nmatched=\{self.matched}\nnext_runs=\{self.next_runs}"
}
