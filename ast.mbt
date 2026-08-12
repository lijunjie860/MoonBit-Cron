///|
pub(all) enum CronField {
  All // *
  Value(Int) // n
  Range(Int, Int) // a-b
  Step(CronField, Int) // a/b
  List(Array[CronField]) // a,b,c
} derive(Eq, Debug)

///|
/// Represents a parsed cron expression with 5 fields.
pub(all) struct CronExpr {
  minute : CronField
  hour : CronField
  day_of_month : CronField
  month : CronField
  day_of_week : CronField
} derive(Eq, Debug)

///|
pub fn CronExpr::new(
  minute : CronField,
  hour : CronField,
  day_of_month : CronField,
  month : CronField,
  day_of_week : CronField,
) -> CronExpr {
  { minute, hour, day_of_month, month, day_of_week }
}

///|
/// Represents a specific time used for matching.
pub(all) struct Time {
  mut year : Int
  mut month : Int // 1-12
  mut day : Int // 1-31
  mut hour : Int // 0-23
  mut minute : Int // 0-59
  mut weekday : Int // 0-6 (Sunday is 0)
} derive(Eq, Debug)
