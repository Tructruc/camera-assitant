# iOS validation

Status: **no iOS evidence recorded.** T059 stays open. This file exists so the missing record is explicit
rather than implied by the absence of a file, and so the next person with a macOS host knows exactly what
to capture.

## What is configured today

`.github/workflows/mobile-builds.yml` is set up to, on every push, pull request, and the nightly schedule:

- `ios` job — `flutter build ios --simulator --no-codesign` on `macos-latest`, then package and upload the
  simulator application as an artifact (not on pull requests).
- `ios-integration` job — boot an available iPhone simulator and run `flutter test integration_test -d <udid>`
  on `macos-latest`. This job is marked `continue-on-error: true`, so a failure is visible but does not fail
  the workflow.

Neither job has been observed executing from this workstation, and no artifact, log, or screenshot from them
has been recorded here. Treat the list above as configuration, not evidence.

## Automated coverage that is platform-independent

The host-runnable journeys are recorded scenario by scenario in
[quickstart-evidence.md](quickstart-evidence.md). They run against the host Flutter engine and verify
calculation, persistence, offline, and presentation behaviour, but they do not exercise UIKit, iOS
permission prompts, CoreMotion, AVFoundation, or an iOS SQLite file path.

## What an iOS pass must capture

1. Record the commit SHA, the device or simulator model, the iOS version, and the Flutter/Dart versions.
2. Confirm the app installs and reaches the calculator catalog with network access disabled.
3. Walk the `quickstart.md` scenarios and record pass/fail for each, calling out the ones this repository
   still lists as manual in `quickstart-evidence.md`.
4. Exercise the three permission prompts the app can raise, and their denial paths:
   - camera (`NSCameraUsageDescription`, live AR overlay),
   - location when in use (`NSLocationWhenInUseUsageDescription`, current-position action; also covers the
     CoreLocation heading used by the compass),
   - motion (`NSMotionUsageDescription`, camera pitch).
   Confirm each prompt appears only when the user starts the function that needs it (FR-017) and that the
   planners remain fully usable after a denial (FR-012, SC-006).
5. Confirm the iOS process-death path: save a plan, kill the app from the switcher, relaunch, and reopen the
   plan with its inputs, outputs, equipment values, and planning context unchanged (SC-005, SC-008).
6. Run the usability protocol in [usability.md](usability.md) on iOS if the participant sample allows it
   (SC-011).
7. Screenshot the live AR overlay, the compass fallback when the sensor is unavailable, and a reopened plan.

## Known open questions for the iOS pass

- The iOS merged plugin surface has not been inspected after the camera, compass, sensor, and location
  dependencies were added; `privacy.md` records the three usage strings that exist but only statically.
- The lunar and solar model tolerances are asserted against USNO/JPL fixtures in
  `test/unit/features/astronomy/solar_lunar_fixture_test.dart`; no iOS-specific numerical difference is
  expected because the domain layer is pure Dart, but that assumption has not been observed on a device.
