# Integration examples

## Persist a normalized schedule

```moonbit
let expression = match @cron.parse("0 9 * JAN-MAR MON-FRI") {
  Ok(value) => value
  Err(message) => panic(message)
}
let persisted = expression.to_string()
// persisted == "0 9 * 1-3 1-5"
```

Persisting the canonical form avoids differences between named aliases and
numeric fields when schedules are compared, cached, or reviewed in a config
change.

## Check a trigger before enqueueing work

```moonbit
if expression.matches(now) {
  enqueue_job()
}
```

Use `expression.next(now)` when a future timestamp is needed instead of
polling every minute in application code.
