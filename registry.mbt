///|
/// Registry of validated task specifications loaded from configuration.
pub struct TaskRegistry {
  specs : Array[TaskSpec]
} derive(Debug)

///|
pub fn TaskRegistry::new() -> TaskRegistry {
  { specs: [] }
}

///|
pub fn TaskRegistry::from_document(
  document : String,
) -> Result[TaskRegistry, String] {
  let specs = match parse_task_document(document) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let registry = TaskRegistry::new()
  for spec in specs {
    ignore(registry.add(spec))
  }
  Ok(registry)
}

///|
pub fn TaskRegistry::add(
  self : TaskRegistry,
  spec : TaskSpec,
) -> Result[Unit, String] {
  for existing in self.specs {
    if existing.id == spec.id {
      return Err("Task already registered: \{spec.id}")
    }
  }
  self.specs.push(spec)
  Ok(())
}

///|
pub fn TaskRegistry::remove(self : TaskRegistry, id : String) -> Bool {
  for index, spec in self.specs {
    if spec.id == id {
      let _ = self.specs.remove(index)
      return true
    }
  }
  false
}

///|
pub fn TaskRegistry::get(self : TaskRegistry, id : String) -> TaskSpec? {
  for spec in self.specs {
    if spec.id == id {
      return Some(spec)
    }
  }
  None
}

///|
pub fn TaskRegistry::enabled(self : TaskRegistry) -> Array[TaskSpec] {
  let result = []
  for spec in self.specs {
    if spec.enabled {
      result.push(spec)
    }
  }
  result
}

///|
pub fn TaskRegistry::ids(self : TaskRegistry) -> Array[String] {
  self.specs.map(fn(spec) { spec.id })
}

///|
pub fn TaskRegistry::length(self : TaskRegistry) -> Int {
  self.specs.length()
}

///|
pub fn TaskRegistry::to_document(self : TaskRegistry) -> String {
  task_document(self.specs)
}
