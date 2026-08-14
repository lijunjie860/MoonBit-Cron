# OSC2026 Acceptance Checklist

This repository is maintained as a reusable MoonBit ecosystem package.

## Package readiness

- Module name: `lijunjie860/moonbit_cron`
- Version: `0.1.1`
- Package license: MIT (`moon.mod` and `LICENSE` agree)
- Public repository: GitHub and GitLink mirrors
- Registry target: Mooncakes

## Reproducible verification

Run from the repository root:

```bash
moon fmt --check
moon check --target all --warn-list +73 --deny-warn
moon build --target all --warn-list +73 --deny-warn
moon test --target all --warn-list +73 --deny-warn
moon info
git diff --exit-code
```

## Acceptance evidence

- A runnable `cmd/main` demonstrates the core parser, matcher, and
  next-trigger API, including canonical serialization.
- The test suite covers valid expressions, month/day aliases, malformed input,
  numeric overflow, DOM/DOW semantics, cross-month rollover, and leap years.
- `.github/workflows/ci.yml` installs the latest official MoonBit toolchain,
  formats its isolated runner checkout, and verifies every supported target on
  Linux, macOS, and Windows.
- Public code and tests are written in MoonBit; source-line counts can be
  reproduced with `git ls-files '*.mbt' '*_test.mbt' | xargs wc -l` on POSIX.
