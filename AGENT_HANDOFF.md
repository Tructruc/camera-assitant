# Agent handoff

Everything needed to resume this project from a fresh session. Read this first, then
`specs/001-photography-assistant/tasks.md` for the task ledger and
`specs/001-photography-assistant/validation/quickstart-evidence.md` for the acceptance evidence.

## Environment: the sandbox is read-only outside this directory

The Flutter SDK lives in `/home/tructruc00/git/flutter/flutter`, which is **read-only** here. The official
`flutter` launcher rewrites `bin/cache/engine.stamp` on every run, so it fails with
`Read-only file system`. A writable mirror is committed nowhere but is ignored by git:

```sh
./.tooling/flutterw --no-version-check test --no-pub --concurrency=1   # full suite
./.tooling/flutterw --no-version-check analyze --fatal-infos
./.tooling/flutterw --no-version-check test --no-pub integration_test/<file>_test.dart
```

`.tooling/` holds real copies of the SDK's small files, symlinks for `.git`, `packages/`, `artifacts`,
`dart-sdk`, and a fake `HOME` with `PUB_CACHE`. **It is gitignored.** If it is missing, rebuild it by
mirroring the SDK (see CONTRIBUTING.md, "Flutter SDK outside the writable tree").

Two traps found the hard way:

- **Never `export HOME=.../.tooling/home` in the same command as `git`.** Git then loses
  `~/.gitconfig` (author identity) and the credential helper, so `git commit` fails with "Author identity
  unknown" and `git push` with "could not read Username". Run git in its own command with the normal HOME.
- `/tmp` is a fresh tmpfs per command. Anything that must persist goes under the workspace.

No Android emulator is possible: there is no `/dev/kvm`, no writable Gradle cache, and no macOS. T058,
T059, T061, and T062 are therefore blocked here; everything else can be verified.

## Current state

At the time of writing the tree is clean and `origin/v2` is at the commit that adds this file.
The last full verification:

- `flutter test --no-pub --concurrency=1` → **293 passed**
- `flutter analyze --fatal-infos` → no issues; `dart format --set-exit-if-changed` → clean
- All **7 integration journeys** green three runs in a row:
  `calculator_flows`, `optics_flows`, `equipment_flow`, `planning_flow`, `preferences_flow`,
  `ar_fallback_flow`, `accessibility_flow`

## What is done

- **Phase 20 convergence (T121–T151)** is fully implemented, tested, and ticked: Sun/Moon planning with
  cited JPL/SIMBAD/USNO fixtures, capability detection feeding both planners, honest fallbacks
  (elevation, AR field of view, horizon state), permission and privacy records, warnings surfaced and
  persisted, archive/delete lifecycle, migration fixtures, performance budgets, and 200% text-scale
  coverage.
- **Post-Phase-20 work from three independent audits**, all closed: the equipment editor's legacy
  `bundled` source, the Sun's AR warning, a pure capability-mapping seam, one shared warning-text map,
  snapshot-provenance tests, parallax disclosure, the duplicate ephemeris name, doc drift, and stronger
  assertions.
- **Persistence error handling**: equipment, saved-location, and saved-calculation writes no longer throw
  unhandled or leak raw database errors; mutations report success and the screens show actionable recovery.
- **Device readings**: a missing altitude no longer becomes 0 m, a new saved location defaults to the
  device's real UTC offset instead of UTC, and the location dialog validates its fields.
- **Test infrastructure**: the integration journeys are deterministic (see below).

## Open work

1. **Device-only, blocked here** — T058, T059, T061, T062: live AR against real sensors, physical
   permission grants/denials, Android and iOS process death, and the representative-photographer usability
   sessions. `validation/ios.md` lists exactly what an iOS pass must capture.
2. **CI-only assertions** — the merged-manifest checks in `mobile-builds.yml` (audio/storage permissions
   removed, `camera.any` optional) only run where Gradle can build.
3. **Optional next steps** — a further convergence audit; more end-to-end journeys for the remaining
   quickstart scenarios; or the desktop/web targets FR-023 allows for later releases.

## Gotchas worth knowing before changing tests

- **Integration journeys must pin their viewport.** `flutter test integration_test/<file>` creates a host
  window whose logical size varies between runs (observed ~481x419 up to ~1000x1600). At the small size,
  controls below the fold are never built and taps fail for reasons unrelated to the product. Use
  `configureJourneyView(tester)` from `integration_test/support/journey.dart`, and always tap after a
  scroll through `tapVisible` (scroll → ensureVisible → settle → tap → settle). This was the cause of a
  long flaky-failure hunt: the same three files failed deterministically while a fourth alternated, and
  bisecting by reverting source files produced misleading "fixes" because stale builds were in play.
- **Drift leaves pending timers in widget tests.** Unmount the tree (`pumpWidget(SizedBox.shrink())` then
  `pumpAndSettle`) before a test that used database streams ends, or the binding fails with "A Timer is
  still pending".
- **`SemanticsHandle`s must be disposed inside the test body**, not in `addTearDown`, or the end-of-test
  verification trips first.
- **Name collisions**: `app_database.dart` exports drift classes named `CameraBody`, `NdFilter`,
  `OpticalAccessory`, and `SavedLocation`. Hide them when importing the domain types.
- **Forcing a controller error**: override the repository provider with a subclass. `DevicePlanningService`,
  `DriftEquipmentRepository`, and `SavedLocationRepository` are deliberately non-`final` so a test can
  substitute a failing or fake implementation.

## Verification recipe before committing

```sh
./.tooling/flutterw --no-version-check analyze --fatal-infos
./.tooling/flutterw --no-version-check test --no-pub --concurrency=1
for f in integration_test/*_test.dart; do
  ./.tooling/flutterw --no-version-check test --no-pub "$f" || break
done
dart format --output=none --set-exit-if-changed lib test integration_test
```

Then commit (scoped message, no `--global` git config needed) and `git push origin v2`.
