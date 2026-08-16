///|
/// Lifecycle of an item in the integration dispatch queue.
pub(all) enum DispatchState {
  Pending
  Leased
  Acknowledged
  Rejected
} derive(Debug, Eq)

///|
/// Queue entry connecting a planned execution to an idempotency key.
pub struct DispatchItem {
  key : String
  plan : ExecutionPlan
  mut state : DispatchState
  mut lease_count : Int
  mut last_error : String?
  enqueued_at : Time
} derive(Debug)

///|
pub fn DispatchItem::new(
  key : String,
  plan : ExecutionPlan,
  enqueued_at : Time,
) -> Result[DispatchItem, String] {
  if key.length() == 0 {
    return Err("Dispatch key must not be empty")
  }
  Ok({
    key,
    plan,
    state: Pending,
    lease_count: 0,
    last_error: None,
    enqueued_at,
  })
}

///|
pub fn DispatchItem::key(self : DispatchItem) -> String {
  self.key
}

///|
pub fn DispatchItem::state(self : DispatchItem) -> DispatchState {
  self.state
}

///|
pub fn DispatchItem::attempts(self : DispatchItem) -> Int {
  self.plan.attempt
}

///|
pub fn DispatchItem::task_id(self : DispatchItem) -> String {
  self.plan.task_id
}

///|
pub fn DispatchItem::lease_count(self : DispatchItem) -> Int {
  self.lease_count
}

///|
pub fn DispatchItem::is_active(self : DispatchItem) -> Bool {
  self.state is Pending || self.state is Leased
}

///|
pub fn DispatchItem::describe(self : DispatchItem) -> String {
  let state = match self.state {
    Pending => "pending"
    Leased => "leased"
    Acknowledged => "acknowledged"
    Rejected => "rejected"
  }
  let error = match self.last_error {
    Some(value) => ": \{value}"
    None => ""
  }
  "key=\{self.key}, task=\{self.plan.task_id}, attempt=\{self.plan.attempt}, state=\{state}, leases=\{self.lease_count}\{error}"
}

///|
pub struct DispatchQueue {
  items : Array[DispatchItem]
  capacity : Int
  mut sequence : Int
} derive(Debug)

///|
pub fn DispatchQueue::new(capacity : Int) -> Result[DispatchQueue, String] {
  if capacity < 1 {
    return Err("Dispatch capacity must be positive")
  }
  Ok({ items: [], capacity, sequence: 0 })
}

///|
pub fn DispatchQueue::capacity(self : DispatchQueue) -> Int {
  self.capacity
}

///|
pub fn DispatchQueue::length(self : DispatchQueue) -> Int {
  self.items.length()
}

///|
pub fn DispatchQueue::pending(self : DispatchQueue) -> Int {
  self.count_state(Pending)
}

///|
pub fn DispatchQueue::leased(self : DispatchQueue) -> Int {
  self.count_state(Leased)
}

///|
pub fn DispatchQueue::completed(self : DispatchQueue) -> Int {
  self.count_state(Acknowledged)
}

///|
pub fn DispatchQueue::rejected(self : DispatchQueue) -> Int {
  self.count_state(Rejected)
}

///|
fn DispatchQueue::count_state(
  self : DispatchQueue,
  state : DispatchState,
) -> Int {
  let mut result = 0
  for item in self.items {
    if item.state == state {
      result += 1
    }
  }
  result
}

///|
fn DispatchQueue::index_of(self : DispatchQueue, key : String) -> Int? {
  for index, item in self.items {
    if item.key == key {
      return Some(index)
    }
  }
  None
}

///|
pub fn DispatchQueue::contains(self : DispatchQueue, key : String) -> Bool {
  self.index_of(key) is Some(_)
}

///|
/// Enqueue an item exactly once. Duplicate keys are rejected for idempotency.
pub fn DispatchQueue::enqueue(
  self : DispatchQueue,
  item : DispatchItem,
) -> Result[Unit, String] {
  if self.items.length() >= self.capacity {
    return Err("Dispatch queue is full")
  }
  if self.contains(item.key) {
    return Err("Duplicate dispatch key: {item.key}")
  }
  self.items.push(item)
  self.sequence += 1
  Ok(())
}

///|
fn DispatchQueue::first_pending(self : DispatchQueue) -> Int? {
  for index, item in self.items {
    if item.state is Pending {
      return Some(index)
    }
  }
  None
}

///|
/// Lease the oldest pending item. Leases are explicit so integrations can
/// acknowledge work only after an external process has accepted it.
pub fn DispatchQueue::claim(self : DispatchQueue) -> DispatchItem? {
  match self.first_pending() {
    None => None
    Some(index) => {
      let item = self.items[index]
      item.state = Leased
      item.lease_count += 1
      Some(item)
    }
  }
}

///|
pub fn DispatchQueue::acknowledge(self : DispatchQueue, key : String) -> Bool {
  match self.index_of(key) {
    None => false
    Some(index) => {
      let item = self.items[index]
      if item.state is Leased {
        item.state = Acknowledged
        true
      } else {
        false
      }
    }
  }
}

///|
pub fn DispatchQueue::reject(
  self : DispatchQueue,
  key : String,
  error : String,
) -> Bool {
  match self.index_of(key) {
    None => false
    Some(index) => {
      let item = self.items[index]
      if item.state is Leased || item.state is Pending {
        item.state = Rejected
        item.last_error = Some(error)
        true
      } else {
        false
      }
    }
  }
}

///|
/// Return a leased item to pending after a transient transport failure.
pub fn DispatchQueue::requeue(
  self : DispatchQueue,
  key : String,
  error : String,
) -> Bool {
  match self.index_of(key) {
    None => false
    Some(index) => {
      let item = self.items[index]
      if item.state is Leased {
        item.state = Pending
        item.last_error = Some(error)
        true
      } else {
        false
      }
    }
  }
}

///|
pub fn DispatchQueue::remove(self : DispatchQueue, key : String) -> Bool {
  match self.index_of(key) {
    None => false
    Some(index) => {
      let _ = self.items.remove(index)
      true
    }
  }
}

///|
pub fn DispatchQueue::item(self : DispatchQueue, key : String) -> DispatchItem? {
  match self.index_of(key) {
    None => None
    Some(index) => Some(self.items[index])
  }
}

///|
pub fn DispatchQueue::keys(self : DispatchQueue) -> Array[String] {
  self.items.map(fn(item) { item.key })
}

///|
pub fn DispatchQueue::active_keys(self : DispatchQueue) -> Array[String] {
  let result : Array[String] = []
  for item in self.items {
    if item.is_active() {
      result.push(item.key)
    }
  }
  result
}

///|
pub fn DispatchQueue::drain_acknowledged(self : DispatchQueue) -> Int {
  let mut removed = 0
  let mut index = self.items.length() - 1
  while index >= 0 {
    if self.items[index].state is Acknowledged {
      let _ = self.items.remove(index)
      removed += 1
    }
    index -= 1
  }
  removed
}

///|
pub fn DispatchQueue::summary(self : DispatchQueue) -> String {
  "capacity=\{self.capacity}, pending=\{self.pending()}, leased=\{self.leased()}, acknowledged=\{self.completed()}, rejected=\{self.rejected()}"
}

///|
pub fn DispatchQueue::available(self : DispatchQueue) -> Int {
  self.capacity - self.items.length()
}

///|
pub fn DispatchQueue::is_full(self : DispatchQueue) -> Bool {
  self.items.length() >= self.capacity
}

///|
pub fn DispatchQueue::is_empty(self : DispatchQueue) -> Bool {
  self.items.length() == 0
}

///|
pub fn DispatchQueue::retryable(self : DispatchQueue) -> Array[String] {
  let result : Array[String] = []
  for item in self.items {
    if item.state is Rejected &&
      item.lease_count < item.plan.retry_policy.attempts() {
      result.push(item.key)
    }
  }
  result
}

///|
pub fn DispatchQueue::pending_tasks(self : DispatchQueue) -> Array[String] {
  let result : Array[String] = []
  for item in self.items {
    if item.state is Pending {
      let mut seen = false
      for id in result {
        if id == item.plan.task_id {
          seen = true
        }
      }
      if !seen {
        result.push(item.plan.task_id)
      }
    }
  }
  result
}

///|
pub fn DispatchQueue::leased_items(self : DispatchQueue) -> Array[DispatchItem] {
  let result : Array[DispatchItem] = []
  for item in self.items {
    if item.state is Leased {
      result.push(item)
    }
  }
  result
}

///|
pub fn DispatchQueue::acknowledge_all(self : DispatchQueue) -> Int {
  let mut result = 0
  for item in self.items {
    if item.state is Leased {
      item.state = Acknowledged
      result += 1
    }
  }
  result
}

///|
pub fn DispatchQueue::requeue_all(
  self : DispatchQueue,
  message : String,
) -> Int {
  let mut result = 0
  for item in self.items {
    if item.state is Leased {
      item.state = Pending
      item.last_error = Some(message)
      result += 1
    }
  }
  result
}

///|
pub fn DispatchQueue::reject_all(self : DispatchQueue, message : String) -> Int {
  let mut result = 0
  for item in self.items {
    if item.state is Pending || item.state is Leased {
      item.state = Rejected
      item.last_error = Some(message)
      result += 1
    }
  }
  result
}

///|
pub fn DispatchQueue::state_counts(self : DispatchQueue) -> Array[Int] {
  [self.pending(), self.leased(), self.completed(), self.rejected()]
}

///|
pub fn DispatchQueue::completion_percent(self : DispatchQueue) -> Int {
  if self.items.length() == 0 {
    return 100
  }
  self.completed() * 100 / self.items.length()
}

///|
pub fn DispatchQueue::failure_percent(self : DispatchQueue) -> Int {
  if self.items.length() == 0 {
    return 0
  }
  self.rejected() * 100 / self.items.length()
}

///|
pub fn DispatchQueue::find_task(
  self : DispatchQueue,
  task_id : String,
) -> Array[String] {
  let result : Array[String] = []
  for item in self.items {
    if item.plan.task_id == task_id {
      result.push(item.key)
    }
  }
  result
}

///|
pub fn DispatchQueue::export_keys(self : DispatchQueue) -> String {
  self.items.map(fn(item) { item.key }).join("\n")
}

///|
pub fn DispatchQueue::state_report(self : DispatchQueue) -> String {
  let counts = self.state_counts()
  "pending=\{counts[0]},leased=\{counts[1]},acknowledged=\{counts[2]},rejected=\{counts[3]},completion=\{self.completion_percent()}%"
}

///|
pub fn DispatchQueue::describe(self : DispatchQueue) -> String {
  let lines : Array[String] = [self.summary()]
  for item in self.items {
    lines.push(item.describe())
  }
  lines.join("\n")
}

///|
/// Reconcile a queue with a fresh execution plan set. Existing acknowledged
/// items are retained; missing pending items are removed as stale work.
pub fn DispatchQueue::reconcile(
  self : DispatchQueue,
  plans : Array[ExecutionPlan],
  now : Time,
) -> Result[Int, String] {
  let mut added = 0
  for plan in plans {
    let key = "\{plan.task_id}@\{format_time_iso(plan.scheduled_for)}#\{plan.attempt}"
    if !self.contains(key) {
      let item = match DispatchItem::new(key, plan, now) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      match self.enqueue(item) {
        Ok(_) => added += 1
        Err(message) => return Err(message)
      }
    }
  }
  Ok(added)
}
