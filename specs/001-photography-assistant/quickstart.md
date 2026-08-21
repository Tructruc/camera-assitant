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
9. For a 36 × 24 mm sensor, 50 mm lens, and 10 m distance, verify field of view is approximately
   39.6° × 27.0° with 7.2 m × 4.8 m coverage.
10. At f/8, 550 nm, and 4 µm pixels, verify the Airy disk is approximately 10.736 µm or 2.684 pixels and
    the app explains that this is guidance, not a universal sharpness cutoff.
11. Create a 0.5–1 m focus-stack plan at 100 mm, f/8, 0.03 mm circle of confusion, and 20% overlap;
    verify ordered focus distances start at 0.5 m, end at 1 m, and persist in the saved snapshot.
12. For guide number 40 at ISO 100, full power, and 5 m, verify flash guidance recommends f/8 and states
    that bounce, modifiers, ambient light, and TTL metering are outside the model.
13. Plan a one-hour timelapse at ten-second intervals, 30 fps, 25 MB per frame, ramping from one to four
    seconds; verify 361 frames, 12.03 seconds playback, 9,025 MB storage, and a +2-stop ramp.
14. Add a saved 25 mm extension tube, select it with a 50 mm lens at native 0.2× and f/8, and verify the
    macro estimate reports 0.70×, effective f/13.6, approximately 51.4 mm subject width on a 36 mm sensor,
    and explicit working-distance/internal-focus limitations.
15. Switch between reversed-lens and coupled-lens configurations and verify irrelevant inputs disappear,
    saved lens provenance remains visible, and each saved result retains only its active model inputs.
16. Plan a 90° × 45° panorama with a 36 × 24 mm sensor, 50 mm lens, landscape orientation, and 30%
    overlap on both axes; verify a 3 × 2 grid (six frames), approximately 27.7° yaw and 18.9° pitch
    increments, at least the requested coverage, centered serpentine positions, and a reusable saved plan.
17. Offline, select Sirius at Greenwich (`51.4779° N, 0° E`) for `2026-01-15 22:00 UTC`; verify
    approximately `20.4°` altitude and `163.7°` true azimuth, UTC rise/transit/set events, a 20.8-second
    500-rule estimate and 10.3-second NPF estimate for 24 mm, f/2.8, 5 µm, plus a saved immutable plan.
18. Search the Sun at Greenwich on `2026-03-20 UTC` for a 180° true bearing toward a target 800 m above
    the observer at 1,000 m distance; verify ordered alignment candidates near solar noon, explicit
    ten-minute/terrain/refraction limitations, and the persistent certified-solar-filter safety warning.
19. Open numeric, timeline, compass, map, and AR views with camera/orientation/location access unavailable;
    verify the same plan remains usable, no synthetic heading or live camera is shown, and AR explains its
    capability requirements without blocking the other views.
20. Add a manual saved location with elevation and time zone, restart offline, and apply it in both the
    night-sky and alignment planners. Edit the location and verify an already saved plan retains its
    original coordinates, candidate list, assumptions, and field checklist.
21. On a supported phone, explicitly open live AR, grant camera access, and verify the camera preview and
    target reticle respond to compass heading. Confirm magnetic heading and true target bearing are labeled
    separately, calibration limitations remain visible, and denying camera/location returns to the full
    numeric/timeline/compass/map plan.

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
