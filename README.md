# MoonBit Cron

[![MoonBit CI](https://github.com/lijunjie860/MoonBit-Cron/actions/workflows/ci.yml/badge.svg)](https://github.com/lijunjie860/MoonBit-Cron/actions/workflows/ci.yml)

`MoonBit Cron` is a zero-dependency, pure MoonBit library for parsing standard
five-field Cron expressions, matching times, and calculating the next trigger.
It is suitable for schedulers, automation tools, backend services, and CLIs.

## Features

- Parses minute, hour, day-of-month, month, and day-of-week fields.
- Supports `*`, values, ranges (`a-b`), lists (`a,b`), and steps (`*/n`).
- Supports uppercase month aliases (`JAN` through `DEC`) and weekday aliases
  (`SUN` through `SAT`).
- Rejects malformed input, out-of-range values, non-positive steps, and
  oversized numeric fields before integer overflow.
- Uses standard Cron day-of-month/day-of-week **OR** semantics.
- Finds the next matching minute across month and leap-year boundaries.
- Exposes `CronExpr::to_string()` for canonical serialization and config
  round-tripping.
- Supports wasm, wasm-gc, JavaScript, and native targets.

## Install

Install MoonBit with the official installer, then add the package from
Mooncakes:

```bash
moon add lijunjie860/moonbit_cron
```

To develop locally:

```bash
git clone https://github.com/lijunjie860/MoonBit-Cron.git
cd MoonBit-Cron
moon check --target all --warn-list +73 --deny-warn
moon test --target all --warn-list +73 --deny-warn
moon run cmd/main
```

## API example

```moonbit
import {
  "lijunjie860/moonbit_cron" @cron,
}

fn next_workday_trigger() -> Result[@cron.Time, String] {
  match @cron.parse("*/15 9-17 * JAN-MAR MON-FRI") {
    Err(message) => Err(message)
    Ok(expr) => expr.next(@cron.Time::{
      year: 2026,
      month: 1,
      day: 5,
      hour: 9,
      minute: 7,
      weekday: 1,
    })
  }
}
```

## Runnable CLI demonstration

```bash
moon run cmd/main
```

Expected output:

```text
Expression: */15 9-17 * * 1-5
Canonical: */15 9-17 * * 1-5
Matches now: false
Next trigger: 2026-10-15 9:15 (weekday 4)
```

`CronExpr::to_string()` emits a normalized numeric form. Named aliases such
as `JAN` and `MON` are parsed correctly and serialize to their numeric values,
which makes persisted schedules deterministic.

## Validation

The GitHub Actions workflow installs the latest official MoonBit toolchain,
formats its isolated checkout, then runs warning-free checks, builds,
generated-interface generation, and tests on Ubuntu, macOS, and Windows.

Run the same checks locally:

```bash
moon fmt --check
moon check --target all --warn-list +73 --deny-warn
moon build --target all --warn-list +73 --deny-warn
moon test --target all --warn-list +73 --deny-warn
moon info
```

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

Copyright (c) 2026 lijunjie860. Licensed under the [MIT License](LICENSE).
