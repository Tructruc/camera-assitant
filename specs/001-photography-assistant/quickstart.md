# Quickstart Validation: Photography Assistant Foundation

## Prerequisites

- Flutter 3.44.x stable with its bundled Dart SDK
- Android SDK and an Android emulator/device
- macOS with Xcode and an iOS simulator/device for iOS validation

## Bootstrap and static checks

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
```

Expected: dependencies resolve from the lockfile, formatting reports no changes, and analysis has no
errors or warnings permitted by project policy.

## Automated test layers

```sh
flutter test test/unit
flutter test test/data
flutter test test/widget
flutter test --coverage
flutter test integration_test -d <device-id>
```

Expected:

- Formula fixtures and all validation/unit-conversion boundaries pass.
- Database constraints, migrations, archival, and immutable snapshots pass in memory.
- Widget states, semantics, 200% text scale, light/dark/low-light modes, and selected goldens pass.
- Integration journeys create equipment, apply it to each calculator, save a snapshot, restart offline,
  and reopen the unchanged result.

## Manual acceptance journey

1. Start with network access disabled and confirm no sign-in or connection warning blocks the app.
2. Create a custom camera with sensor dimensions and a lens with a focal range.
3. Select them in depth of field, calculate a published fixture, and inspect formula assumptions.
4. Change display units and verify physical values remain equivalent.
5. Compare two exposures and confirm swapping them reverses the stop difference.
6. Stack a 3-stop and 7-stop ND filter on a 1/30-second base exposure; verify the raw result is
   approximately 34.133 seconds and the app explains conventional timing.
7. Save each result, edit/archive the lens, restart the app, and verify saved snapshots retain the exact
   equipment values originally applied.
8. Enable 200% text scaling and a screen reader; complete the same journey without clipped content,
   unlabeled controls, or color-only feedback.

## Platform build gates

```sh
flutter build appbundle --debug
flutter build ios --simulator --no-codesign
```

The Android command runs on Linux CI. The iOS command runs on macOS CI. Release candidates additionally
run smoke journeys on representative Android and iOS devices.

## Performance checks

- Profile calculator updates and confirm p95 is below 100 ms for reference and boundary fixtures.
- Seed 1,000 equipment records and confirm inventory readiness below 500 ms p95 with smooth scrolling.
- Confirm cold start reaches an interactive screen below two seconds on representative mid-range devices.

## Traceability

- Domain shapes and persistence lifecycle: [data-model.md](data-model.md)
- Observable calculator/repository behavior: [contracts/feature-contracts.md](contracts/feature-contracts.md)
- Product acceptance criteria: [spec.md](spec.md)
