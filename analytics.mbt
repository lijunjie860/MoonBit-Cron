///|
/// Per-task workload statistics for a bounded planning window.
pub struct TaskLoad {
  task_id : String
  mut occurrences : Int
  mut first : Time?
  mut last : Time?
  enabled : Bool
} derive(Debug, Eq)

///|
pub fn TaskLoad::new(task_id : String, enabled : Bool) -> TaskLoad {
  { task_id, occurrences: 0, first: None, last: None, enabled }
}

///|
pub fn TaskLoad::record(self : TaskLoad, at : Time) -> Unit {
  self.occurrences += 1
  match self.first {
    None => self.first = Some(at)
    Some(current) => if at.compare(current) < 0 { self.first = Some(at) }
  }
  match self.last {
    None => self.last = Some(at)
    Some(current) => if at.compare(current) > 0 { self.last = Some(at) }
  }
}

///|
pub fn TaskLoad::task_id(self : TaskLoad) -> String {
  self.task_id
}

///|
pub fn TaskLoad::count(self : TaskLoad) -> Int {
  self.occurrences
}

///|
pub fn TaskLoad::is_empty(self : TaskLoad) -> Bool {
  self.occurrences == 0
}

///|
pub fn TaskLoad::first_run(self : TaskLoad) -> Time? {
  self.first
}

///|
pub fn TaskLoad::last_run(self : TaskLoad) -> Time? {
  self.last
}

///|
pub fn TaskLoad::describe(self : TaskLoad) -> String {
  let first = match self.first {
    Some(value) => format_time_iso(value)
    None => "-"
  }
  let last = match self.last {
    Some(value) => format_time_iso(value)
    None => "-"
  }
  let state = if self.enabled { "enabled" } else { "disabled" }
  "task=\{self.task_id}, count=\{self.occurrences}, first=\{first}, last=\{last}, state=\{state}"
}

///|
/// A deterministic report describing scheduler pressure in a time window.
pub struct WindowAnalysis {
  start : Time
  end : Time
  total_occurrences : Int
  loads : Array[TaskLoad]
  rejected_tasks : Array[String]
} derive(Debug, Eq)

///|
pub fn WindowAnalysis::total(self : WindowAnalysis) -> Int {
  self.total_occurrences
}

///|
pub fn WindowAnalysis::task_count(self : WindowAnalysis) -> Int {
  self.loads.length()
}

///|
pub fn WindowAnalysis::rejected_count(self : WindowAnalysis) -> Int {
  self.rejected_tasks.length()
}

///|
pub fn WindowAnalysis::loads(self : WindowAnalysis) -> Array[TaskLoad] {
  self.loads
}

///|
pub fn WindowAnalysis::rejected(self : WindowAnalysis) -> Array[String] {
  self.rejected_tasks
}

///|
pub fn WindowAnalysis::peak(self : WindowAnalysis) -> TaskLoad? {
  let mut result : TaskLoad? = None
  for load in self.loads {
    match result {
      None => result = Some(load)
      Some(current) =>
        if load.occurrences > current.occurrences {
          result = Some(load)
        } else if load.occurrences == current.occurrences &&
          load.task_id < current.task_id {
          result = Some(load)
        }
    }
  }
  result
}

///|
pub fn WindowAnalysis::describe(self : WindowAnalysis) -> String {
  let lines = [
    "window=\{format_time_iso(self.start)}..\{format_time_iso(self.end)}",
    "total_occurrences=\{self.total_occurrences}",
    "tasks=\{self.loads.length()}",
    "rejected=\{self.rejected_tasks.length()}",
  ]
  lines.join("; ")
}

///|
fn find_load(loads : Array[TaskLoad], id : String) -> TaskLoad? {
  for load in loads {
    if load.task_id == id {
      return Some(load)
    }
  }
  None
}

///|
fn load_for(loads : Array[TaskLoad], spec : TaskSpec) -> TaskLoad {
  match find_load(loads, spec.id) {
    Some(load) => load
    None => {
      let load = TaskLoad::new(spec.id, spec.enabled)
      loads.push(load)
      load
    }
  }
}

///|
/// Analyze every enabled task without executing it. Invalid expressions are
/// isolated in `rejected` so one bad task cannot hide the healthy workload.
pub fn analyze_window(
  registry : TaskRegistry,
  window : TimeWindow,
  limit_per_task : Int,
) -> Result[WindowAnalysis, String] {
  if limit_per_task < 0 {
    return Err("Analysis limit must be non-negative")
  }
  let loads : Array[TaskLoad] = []
  let rejected : Array[String] = []
  let mut total = 0
  for spec in registry.enabled() {
    let load = load_for(loads, spec)
    match spec.expression.window(window, limit_per_task) {
      Ok(occurrences) =>
        for occurrence in occurrences {
          load.record(occurrence)
          total += 1
        }
      Err(_) => rejected.push(spec.id)
    }
  }
  Ok({
    start: window.start(),
    end: window.end(),
    total_occurrences: total,
    loads,
    rejected_tasks: rejected,
  })
}

///|
/// Estimate whether a window can be handled by a fixed execution budget.
pub fn fits_budget(analysis : WindowAnalysis, budget : Int) -> Bool {
  budget >= 0 && analysis.total_occurrences <= budget
}

///|
pub fn utilization_percent(analysis : WindowAnalysis, budget : Int) -> Int {
  if budget <= 0 {
    return 0
  }
  let value = analysis.total_occurrences * 100 / budget
  if value > 100 {
    100
  } else {
    value
  }
}

///|
pub fn render_load_table(analysis : WindowAnalysis) -> String {
  let lines : Array[String] = ["task | occurrences | first | last | state"]
  for load in analysis.loads {
    lines.push(load.describe())
  }
  lines.join("\n")
}

///|
/// Calculate a stable histogram by occurrence count. The returned array is
/// indexed by count and is useful for dashboards and capacity planning.
pub fn occurrence_histogram(analysis : WindowAnalysis) -> Array[Int] {
  let histogram : Array[Int] = []
  for load in analysis.loads {
    while histogram.length() <= load.occurrences {
      histogram.push(0)
    }
    histogram[load.occurrences] = histogram[load.occurrences] + 1
  }
  histogram
}

///|
pub fn busiest_tasks(analysis : WindowAnalysis, limit : Int) -> Array[String] {
  if limit <= 0 {
    return []
  }
  let remaining = analysis.loads.copy()
  let result : Array[String] = []
  let mut count = 0
  while count < limit && remaining.length() > 0 {
    let mut best_index = 0
    for index in 1..<remaining.length() {
      let candidate = remaining[index]
      let best = remaining[best_index]
      if candidate.occurrences > best.occurrences ||
        (
          candidate.occurrences == best.occurrences &&
          candidate.task_id < best.task_id
        ) {
        best_index = index
      }
    }
    result.push(remaining[best_index].task_id)
    let _ = remaining.remove(best_index)
    count += 1
  }
  result
}

///|
pub fn analysis_csv(analysis : WindowAnalysis) -> String {
  let lines : Array[String] = ["task_id,occurrences,first,last,enabled"]
  for load in analysis.loads {
    let first = match load.first {
      Some(value) => format_time_iso(value)
      None => ""
    }
    let last = match load.last {
      Some(value) => format_time_iso(value)
      None => ""
    }
    let enabled = if load.enabled { "true" } else { "false" }
    lines.push(
      "\{load.task_id},\{load.occurrences},\{first},\{last},\{enabled}",
    )
  }
  lines.join("\n")
}

///|
pub fn analysis_health(analysis : WindowAnalysis, budget : Int) -> HealthState {
  if analysis.rejected_tasks.length() > 0 {
    Unhealthy
  } else if !fits_budget(analysis, budget) {
    Degraded
  } else {
    Healthy
  }
}

///|
pub fn WindowAnalysis::load_for(
  self : WindowAnalysis,
  id : String,
) -> TaskLoad? {
  find_load(self.loads, id)
}

///|
pub fn WindowAnalysis::empty_tasks(self : WindowAnalysis) -> Array[String] {
  let result : Array[String] = []
  for load in self.loads {
    if load.is_empty() {
      result.push(load.task_id)
    }
  }
  result
}

///|
pub fn WindowAnalysis::share_percent(self : WindowAnalysis, id : String) -> Int {
  if self.total_occurrences == 0 {
    return 0
  }
  match self.load_for(id) {
    Some(load) => load.occurrences * 100 / self.total_occurrences
    None => 0
  }
}

///|
pub fn WindowAnalysis::within(
  self : WindowAnalysis,
  start : Time,
  end : Time,
) -> Bool {
  start.compare(self.start) <= 0 && self.end.compare(end) <= 0
}

///|
pub fn WindowAnalysis::budget_message(
  self : WindowAnalysis,
  budget : Int,
) -> String {
  if budget < 0 {
    return "budget must be non-negative"
  }
  if self.total_occurrences > budget {
    "over budget by \{self.total_occurrences - budget} occurrence(s)"
  } else {
    "\{budget - self.total_occurrences} execution slot(s) remain"
  }
}

///|
pub fn sort_loads_by_count(loads : Array[TaskLoad]) -> Array[TaskLoad] {
  let result = loads.copy()
  for index in 0..<result.length() {
    let mut best = index
    for candidate in (index + 1)..<result.length() {
      if result[candidate].occurrences > result[best].occurrences ||
        (
          result[candidate].occurrences == result[best].occurrences &&
          result[candidate].task_id < result[best].task_id
        ) {
        best = candidate
      }
    }
    if best != index {
      let value = result[index]
      result[index] = result[best]
      result[best] = value
    }
  }
  result
}

///|
pub fn WindowAnalysis::analysis_ranked_table(self : WindowAnalysis) -> String {
  let lines : Array[String] = ["rank | task | occurrences | share"]
  let ranked = sort_loads_by_count(self.loads)
  for index, load in ranked {
    lines.push(
      "\{index + 1} | \{load.task_id} | \{load.occurrences} | \{self.share_percent(load.task_id)}%",
    )
  }
  lines.join("\n")
}

///|
pub fn WindowAnalysis::analysis_summary(
  self : WindowAnalysis,
  budget : Int,
) -> String {
  let peak = match self.peak() {
    Some(load) => load.task_id
    None => "-"
  }
  "total=\{self.total_occurrences}; peak=\{peak}; \{self.budget_message(budget)}"
}
