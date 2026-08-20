# Performance validation

Measured 21 August 2026 on the Linux development/CI host with Flutter widget tests in debug mode.
These repeatable host measurements are regression gates, not substitutes for release-profile measurements
on representative Android and iOS hardware.

| Scenario | Budget | Observed | Result |
|---|---:|---:|---|
| Bundle of depth-of-field, exposure-comparison, and long-exposure calculations, p95 of 1,000 iterations | < 100 ms | 0.010 ms | Pass |
| Load and map 1,000 camera records, p95 of 20 reads | < 500 ms | 39.828 ms | Pass |
| Cold widget/application composition to interactive calculator catalog | < 2,000 ms | 371 ms | Pass |
| Large-inventory drag and frame pump, p95 of 20 steps | < 100 ms host regression threshold | 29.489 ms | Pass |

The automated gates live in `test/performance/release_budgets_test.dart` and
`test/performance/ui_budgets_test.dart`. They print their measured values in CI and fail if a budget is
exceeded. Database seeding is intentionally excluded from inventory-readiness timing; the measurement
covers the user-facing query and domain mapping after data already exists.

Limitations:

- Debug host timing does not represent AOT execution, GPU raster time, thermal throttling, or storage on
  a physical phone.
- The scroll gate catches major build/layout regressions but cannot prove a device sustains 60 or 120 Hz.
- Android and iOS release-profile traces remain part of the platform validation tasks and should record
  device model, OS version, build SHA, frame timings, and cold/warm launch separately.
