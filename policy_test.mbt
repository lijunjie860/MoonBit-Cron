///|
test "concurrency policies control overlap" {
  let allow = ConcurrencyPolicy::new(Allow, 2, 0).unwrap()
  assert_true(allow.admit(1, 0))
  assert_false(allow.admit(2, 0))
  let skip = ConcurrencyPolicy::new(Skip, 1, 0).unwrap()
  assert_false(skip.admit(1, 0))
  let queue = ConcurrencyPolicy::new(Queue, 1, 2).unwrap()
  assert_true(queue.admit(1, 1))
  assert_false(queue.admit(1, 2))
}
