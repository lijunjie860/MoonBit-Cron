# Changelog

## 0.1.1 — 2026-08-13

- Added `CronExpr::to_string()` for deterministic, canonical five-field Cron
  serialization.
- Added regression coverage for parse/serialize round-tripping.
- Updated the CLI and README with the normalized schedule representation.

## 0.1.0

- Initial public release with parsing, matching, and next-trigger calculation.
