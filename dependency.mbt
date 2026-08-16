///|
/// A dependency edge between two scheduled tasks.
pub struct TaskDependency {
  before : String
  after : String
} derive(Debug, Eq)

///|
pub fn TaskDependency::new(
  before : String,
  after : String,
) -> Result[TaskDependency, String] {
  if before.length() == 0 || after.length() == 0 || before == after {
    return Err("Dependency endpoints must be distinct non-empty ids")
  }
  Ok({ before, after })
}

///|
/// Validate dependency edges against a task registry.
pub fn validate_dependencies(
  registry : TaskRegistry,
  dependencies : Array[TaskDependency],
) -> Result[Unit, String] {
  for dependency in dependencies {
    if registry.get(dependency.before) is None {
      return Err("Unknown dependency task: \{dependency.before}")
    }
    if registry.get(dependency.after) is None {
      return Err("Unknown dependent task: \{dependency.after}")
    }
  }
  for left in dependencies {
    for right in dependencies {
      if left.before == right.after && left.after == right.before {
        return Err("Dependency cycle detected")
      }
    }
  }
  Ok(())
}

///|
/// Return task ids in a stable dependency-first order.
pub fn dependency_order(
  registry : TaskRegistry,
  dependencies : Array[TaskDependency],
) -> Result[Array[String], String] {
  match validate_dependencies(registry, dependencies) {
    Err(message) => return Err(message)
    Ok(_) => ()
  }
  let result = []
  for spec in registry.enabled() {
    let mut has_predecessor = false
    for dependency in dependencies {
      if dependency.after == spec.id {
        has_predecessor = true
      }
    }
    if !has_predecessor {
      result.push(spec.id)
    }
  }
  for dependency in dependencies {
    let mut seen = false
    for id in result {
      if id == dependency.after {
        seen = true
      }
    }
    if !seen {
      result.push(dependency.after)
    }
  }
  Ok(result)
}
