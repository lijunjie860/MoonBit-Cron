///|
test "dependency validation orders backup pipeline tasks" {
  let registry = TaskRegistry::from_document(
    "extract|0 1 * * *|true|0\ntransform|0 2 * * *|true|0\nload|0 3 * * *|true|0",
  ).unwrap()
  let dependencies = [
    TaskDependency::new("extract", "transform").unwrap(),
    TaskDependency::new("transform", "load").unwrap(),
  ]
  let order = dependency_order(registry, dependencies).unwrap()
  assert_eq(order, ["extract", "transform", "load"])
}

///|
test "dependency validation rejects unknown tasks and cycles" {
  let registry = TaskRegistry::from_document("backup|0 2 * * *|true|0").unwrap()
  let unknown = [TaskDependency::new("backup", "report").unwrap()]
  assert_true(validate_dependencies(registry, unknown) is Err(_))
  let cycle_registry = TaskRegistry::from_document(
    "a|0 1 * * *|true|0\nb|0 2 * * *|true|0",
  ).unwrap()
  let cycle = [
    TaskDependency::new("a", "b").unwrap(),
    TaskDependency::new("b", "a").unwrap(),
  ]
  assert_true(validate_dependencies(cycle_registry, cycle) is Err(_))
}
