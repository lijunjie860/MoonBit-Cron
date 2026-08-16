///|
fn test_plan(id : String, minute : Int) -> ExecutionPlan {
  let time = Time::{ year: 2026, month: 1, day: 1, hour: 2, minute, weekday: 4 }
  let policy = RetryPolicy::new(3, 5, 2, 30).unwrap()
  ExecutionPlan::new(id, time, 1, policy).unwrap()
}

///|
test "dispatch queue leases acknowledges and drains work" {
  let queue = DispatchQueue::new(2).unwrap()
  let first = DispatchItem::new("a#1", test_plan("backup", 0), {
    year: 2026,
    month: 1,
    day: 1,
    hour: 1,
    minute: 0,
    weekday: 4,
  }).unwrap()
  let second = DispatchItem::new("b#1", test_plan("report", 5), {
    year: 2026,
    month: 1,
    day: 1,
    hour: 1,
    minute: 0,
    weekday: 4,
  }).unwrap()
  assert_eq(queue.enqueue(first), Ok(()))
  assert_eq(queue.enqueue(second), Ok(()))
  assert_eq(queue.pending(), 2)
  assert_true(
    queue.enqueue(
      DispatchItem::new("c", test_plan("x", 10), {
        year: 2026,
        month: 1,
        day: 1,
        hour: 1,
        minute: 0,
        weekday: 4,
      }).unwrap(),
    )
    is Err(_),
  )
  match queue.claim() {
    Some(item) => {
      assert_eq(item.key(), "a#1")
      assert_eq(item.state(), Leased)
      assert_eq(item.lease_count(), 1)
    }
    None => fail("expected lease")
  }
  assert_eq(queue.leased(), 1)
  assert_true(queue.acknowledge("a#1"))
  assert_eq(queue.completed(), 1)
  assert_eq(queue.drain_acknowledged(), 1)
  assert_eq(queue.length(), 1)
}

///|
test "dispatch queue rejects and requeues only valid states" {
  let queue = DispatchQueue::new(4).unwrap()
  let item = DispatchItem::new("retry#1", test_plan("sync", 15), {
    year: 2026,
    month: 1,
    day: 1,
    hour: 1,
    minute: 0,
    weekday: 4,
  }).unwrap()
  assert_eq(queue.enqueue(item), Ok(()))
  assert_true(queue.contains("retry#1"))
  assert_true(queue.requeue("retry#1", "transport timeout") is false)
  ignore(queue.claim())
  assert_true(queue.requeue("retry#1", "transport timeout"))
  assert_eq(queue.pending(), 1)
  ignore(queue.claim())
  assert_true(queue.reject("retry#1", "bad payload"))
  assert_eq(queue.rejected(), 1)
  assert_false(queue.acknowledge("retry#1"))
  match queue.item("retry#1") {
    Some(value) => {
      assert_eq(value.state(), Rejected)
      assert_true(value.describe().contains("bad payload"))
    }
    None => fail("missing rejected item")
  }
}

///|
test "dispatch queue reconciliation is idempotent" {
  let queue = DispatchQueue::new(5).unwrap()
  let plan = test_plan("daily", 30)
  let now = Time::{
    year: 2026,
    month: 1,
    day: 1,
    hour: 1,
    minute: 0,
    weekday: 4,
  }
  assert_eq(queue.reconcile([plan], now), Ok(1))
  assert_eq(queue.reconcile([plan], now), Ok(0))
  assert_eq(queue.length(), 1)
  assert_eq(queue.active_keys(), ["daily@2026-1-1T2:30:00#1"])
  assert_true(queue.describe().contains("capacity=5"))
  assert_true(queue.remove("daily@2026-1-1T2:30:00#1"))
  assert_eq(queue.length(), 0)
}
