///|
/// Output formats used by the CLI and monitoring integrations.
pub(all) enum OutputFormat {
  Text
  Compact
  Lines
} derive(Debug, Eq)

///|
pub fn parse_output_format(value : String) -> Result[OutputFormat, String] {
  match value {
    "text" => Ok(Text)
    "compact" => Ok(Compact)
    "lines" => Ok(Lines)
    _ => Err("Output format must be text, compact, or lines")
  }
}

///|
pub fn format_time(value : Time) -> String {
  "\{value.year}-\{value.month}-\{value.day} \{value.hour}:\{value.minute}"
}

///|
pub fn format_time_iso(value : Time) -> String {
  "\{value.year}-\{value.month}-\{value.day}T\{value.hour}:\{value.minute}:00"
}

///|
pub fn format_occurrences(
  values : Array[Time],
  format : OutputFormat,
) -> String {
  match format {
    Text => values.map(format_time).join("\n")
    Compact => values.map(format_time_iso).join(",")
    Lines => values.map(fn(value) { "- \{format_time(value)}" }).join("\n")
  }
}

///|
pub fn format_task_specs(
  specs : Array[TaskSpec],
  format : OutputFormat,
) -> String {
  match format {
    Text =>
      specs
      .map(fn(spec) { "\{spec.id}: \{spec.expression.to_string()}" })
      .join("\n")
    Compact => specs.map(fn(spec) { spec.to_line() }).join(";")
    Lines => specs.map(fn(spec) { "- \{spec.to_line()}" }).join("\n")
  }
}

///|
pub fn format_health(report : HealthReport, format : OutputFormat) -> String {
  match format {
    Text => report.to_string()
    Compact => "\{report.failure_count}/\{report.task_count}"
    Lines =>
      [
        "- tasks: \{report.task_count}",
        "- enabled: \{report.enabled_count}",
        "- failures: \{report.failure_count}",
      ].join("\n")
  }
}

///|
pub fn format_plan(plan : ExecutionPlan, format : OutputFormat) -> String {
  match format {
    Text => plan.describe()
    Compact => "\{plan.task_id}@\{format_time_iso(plan.scheduled_for)}"
    Lines => "- \{plan.describe()}"
  }
}
