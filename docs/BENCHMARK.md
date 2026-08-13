# Benchmark notes

The scheduler's hot paths are parsing, matching, and finding the next trigger.
The following repeatable workload is used when comparing releases:

1. Parse `*/15 9-17 * JAN-MAR MON-FRI` 10,000 times.
2. Match the resulting expression against 10,000 weekday timestamps.
3. Resolve the next trigger from the last timestamp 1,000 times.

Run the workload with the same MoonBit toolchain and target for every release.
Record wall-clock time, target, compiler version, and host CPU. Keep benchmark
results outside the correctness test suite so CI remains deterministic.

The 0.1.1 release adds canonical serialization without changing the matching
algorithm. This makes the benchmark useful as a regression guard for future
parser and scheduler optimizations.
