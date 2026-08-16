# Production expansion design

## Goal

Extend MoonBit Cron from a parser/next-trigger library into a reusable,
testable scheduling toolkit. The expansion prioritizes production behavior,
stable public APIs, and realistic integration scenarios instead of source-line
padding.

## Components

### Calendar and time

Add validated date/time helpers, comparison, minute arithmetic, calendar
windows, and explicit handling for leap years and month/year rollover.

### Expression queries

Keep the existing five-field Cron grammar and add canonical field output,
previous-trigger lookup, bounded future queries, and diagnostic results for
unreachable schedules.

### Scheduler

Provide an in-memory scheduler model with task identifiers, enabled state,
next-run calculation, deterministic ordering, duplicate suppression, and a
clock abstraction suitable for tests.

### Configuration and CLI

Expose serializable task definitions and CLI subcommands for validation,
explanation, next-trigger lookup, task listing, and benchmark execution.

### Verification

Add black-box tests for backups, reports, heartbeats, retries, leap years,
year boundaries, malformed configuration, and deterministic ordering. Keep a
repeatable benchmark workload separate from correctness tests.

## Acceptance gates

Each phase must pass `moon fmt --check`, `moon check --target all`, and the
available target tests. Public API changes must be reflected in `moon info`,
README examples, and the changelog. The final release is published only after
GitHub Actions passes on Ubuntu, macOS, and Windows.
