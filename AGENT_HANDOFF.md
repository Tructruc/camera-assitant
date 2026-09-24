# Agent handoff

Everything needed to resume this project from a fresh session. Read this first, then
`specs/001-photography-assistant/tasks.md` for the task ledger and
`specs/001-photography-assistant/validation/quickstart-evidence.md` for the acceptance evidence.

**To resume, tell the agent:** "Read AGENT_HANDOFF.md, then continue with the next action it lists."

## Environment: the sandbox is read-only outside this directory

**Use `./.tooling/flutterw` for everything** — it is the toolchain CI pins (Flutter 3.47.5 / Dart 3.13.4),
a writable copy of the SDK under `.tooling/sdk-3.47.5/`, with `HOME` and `PUB_CACHE` inside `.tooling/`:

```sh
./.tooling/flutterw --no-version-check test --no-pub --concurrency=1   # full suite
./.tooling/flutterw --no-version-check analyze --fatal-infos
./.tooling/flutterw --no-version-check test --no-pub integration_test/<file>_test.dart
```

`.tooling/` is **gitignored**. Two things live in it for historical reasons:

- `.tooling/sdk-3.47.5/` is a full SDK download (1.5 GB tarball, extracted) — writable, so no mirror
  tricks are needed. The 1.5 GB tarball can be deleted once extracted.
- `.tooling/flutter` + `.tooling/home` are the older mirror of `/home/tructruc00/git/flutter/flutter`
  (3.41.6, **read-only**): `flutter` rewrites `bin/cache/engine.stamp` on every run there, so that SDK
  only works behind real copies of its small files, symlinks for `.git`, `packages/`, `artifacts`,
  `dart-sdk`, and `FLUTTER_PREBUILT_ENGINE_VERSION` (see CONTRIBUTING.md, "Flutter SDK outside the
  writable tree"). Nothing needs it now, but the `.tooling/ui_capture` harnesses still read the Material
  fonts from its `bin/cache/artifacts/material_fonts`; point them at the 3.47.5 SDK if that mirror goes
  away.

Two traps found the hard way:

- **Never `export HOME=.../.tooling/home` in the same command as `git`.** Git then loses
  `~/.gitconfig` (author identity) and the credential helper, so `git commit` fails with "Author identity
  unknown" and `git push` with "could not read Username". Run git in its own command with the normal HOME.
- `/tmp` is a fresh tmpfs per command. Anything that must persist goes under the workspace.

No Android emulator is possible: there is no `/dev/kvm`, no writable Gradle cache, and no macOS. T058,
T059, T061, and T062 are therefore blocked here; everything else can be verified.

## Current state

The tree is clean and `origin/v2` carries the post-redesign convergence fixes, the release-hardening
round, the Flutter 3.47.5 toolchain move, and the saved-plan time-formatting fix (check
`git log --oneline -1` and `git status --short` rather than trusting this line). The last full
verification, on `.tooling/flutterw` (Flutter 3.47.5):

- `flutter test --no-pub --concurrency=1` → **346 passed** on Flutter 3.47.5
- `flutter analyze --fatal-infos` → no issues; `dart format --set-exit-if-changed` → clean
- All **8 integration journeys** green: `calculator_flows`, `optics_flows`, `equipment_flow`,
  `planning_flow`, `preferences_flow`, `ar_fallback_flow`, `accessibility_flow`, `astronomy_flow`
- `flutter build linux --release` → built after the `timezone` 0.11.1 bump (release-compilation gate)

## Result-first UI redesign (complete)

The user's verdict on the old interface was "way too cluttered... wall of numbers everywhere": every
calculator was a 6–10 field form followed by a result card that echoed the inputs and listed every
intermediate number, assumption, warning and checklist. The interface is now result-first with progressive
disclosure, committed in `594b53f` and `74a3053` (tasks T152–T158).

- `CalculationResultView` (in `lib/core/presentation/calculator/calculator_components.dart`) takes
  `highlight: (label, value)` — the single answer the calculator exists to produce — plus an optional
  `highlightCaption`, half-width `tiles` for the two to four numbers a photographer compares,
  `details` for exact intermediates, and collapses `inputs` ("Values used"), `details` ("Exact values")
  and `assumptions` ("Model assumptions") behind one "Details" expander. Warnings stay visible above the
  hero; the semantics label announces `'<title> calculation result: <label> <value>'` plus warnings.
- `CalculatorAdvancedSection` hides secondary inputs behind "More settings"; no control is ever removed.
  It carries a stable `ValueKey('advanced')`, and the result Details section `ValueKey('details')`,
  because an inserted sibling (an applied-equipment notice) otherwise shifts the column position and
  collapses the section the user just opened.
- `depth_of_field_screen.dart` remains the reference conversion; the saved-plan screen
  (`saved_calculations_screen.dart`) mirrors the same hero per calculator id and collapses its provenance
  maps into "Values used / Exact values / Display context / Applied equipment / Model assumptions".
- The biggest walls are gone: the focus-stack distance list, the panorama capture grid, the alignment
  candidate table, the astronomy sky-path samples and the saved-plan maps no longer print at rest. The
  alignment numeric view shows the three closest windows plus `3 of N windows shown · open Details…`.
- Do not change calculations, snapshot payload keys, field labels or `AppliedEquipmentNotice` when
  touching these screens.
- Regression tests must be updated with the screens: assertions on `'Input summary'`/`'Results'`/
  `'Assumptions'` become `'Details'` + hero-value assertions, and tests that need a hidden control must
  expand "More settings" or "Details" first.

### Seeing the UI without a device

`.tooling/ui_capture/` (gitignored) renders real pixels through widget tests with the SDK's Roboto and
Material icon fonts loaded:

```sh
./.tooling/flutterw --no-version-check test --no-pub --update-goldens .tooling/ui_capture/capture_test.dart
# PNGs land in .tooling/ui_capture/ui/ and can be opened with an image reader
./.tooling/flutterw --no-version-check test --no-pub --update-goldens \
  .tooling/ui_capture/scale_capture_test.dart
# the same screens at 200% text scale in a 390x2600 viewport, into ui_capture/scale/
```

`label_gap_probe_test.dart` measures widget rectangles instead of eyeballing PNGs — use it before
reporting a spacing or overlap defect, because an 8 px clearance at 1x still looks like a collision in a
downscaled screenshot.

### UI notes worth keeping

- The result tiles go two-up above 240 logical px; below that they stack.
- The long-exposure base shutter accepts `1/30`, `1/125` or `0.008`; the exact seconds live in Details.
- `flutter_tester` occasionally dies with a segmentation fault when several heavy suites run at once and
  the remaining tests report "did not complete". Re-run the file (or the single test by name) before
  believing a failure.

## CI toolchain, actions, and goldens

The workflow action majors are current (`actions/checkout@v7`, `actions/upload-artifact@v7`,
`actions/download-artifact@v8`). The Flutter pin is **3.47.x**, matching `.tooling/flutterw`.

**Goldens are toolchain-bound.** `test/golden/goldens/*.png` were regenerated with Flutter 3.47.5 when the
pin moved; a 3.44.x run against them fails by ~0.02% of pixels, and the earlier 3.41/3.44-generated
files failed the same way on 3.47. A pin move therefore always needs
`flutter test --no-pub --update-goldens test/golden` with the new SDK **in the same change**, followed by
a run without `--update-goldens` to prove they match, and a look at the regenerated PNGs (they render with
the test font, so compare layout, not glyphs). Two other things move with the pin: `pubspec.lock` gains
the SDK-pinned dev dependencies (matcher, meta, test_api, vector_math) and `flutter pub get` appends the
generated-directory exclusions to `analysis_options.yaml`.

## Next action when work resumes

All repository-verifiable requirements and the queued convergence audit are complete, and the
release-hardening round (dependency refresh, current CI action majors, the planning-card duplication fix)
is in `v2`. Continue with the open device and usability work below when the required hardware and
participants are available. In a sandbox-only session the remaining useful hardening is:

1. A Flutter-pin move, which must carry a golden regeneration with the same SDK (see above).
2. The nightly emulator jobs run the journeys but are `continue-on-error`, and no push gates on them. A
   host-engine journey job (`xvfb-run -a flutter test integration_test/<file>`) would catch journey
   regressions per push, but the repository deliberately traded that gate away for push latency, so add it
   only if the owner asks.
3. The packaging names still differ between workflows: `mobile-builds` publishes `camera-assistant-*`
   assets for the `continuous-v2` prerelease while `nightly-release` uses `photography-assistant-*`
   (the product name the app chrome uses). Cosmetic, but it is a rename of published assets.

Then keep the two habits that have caught every real defect here: render the screens and look at them
(`.tooling/ui_capture`), and measure any suspected spacing or overlap defect instead of judging it from a
downscaled PNG.

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
- **Post-redesign convergence**: loading states mirror their destination layouts; failed location and
  snapshot writes keep drafts recoverable; failed settings and favorite writes are reported; integration
  taps target complete controls; concurrent preference changes are serialized without lost updates; and
  live AR releases and recreates its camera across app lifecycle interruptions.
- **Release hardening (2026-09-24)**: `timezone` 0.11.1 with the DST fixtures re-verified, the workflow
  action majors moved to Node 24 (`checkout@v7`, `upload-artifact@v7`, `download-artifact@v8`), and the
  night-sky planning card no longer prints the same instant on two lines.

## Open work

1. **Device-only, blocked here** — T058, T059, T061, T062: live AR against real sensors, physical
   permission grants/denials, Android and iOS process death, and the representative-photographer usability
   sessions. `validation/ios.md` lists exactly what an iOS pass must capture.
2. **CI-only assertions** — the merged-manifest checks in `mobile-builds.yml` (audio/storage permissions
   removed, `camera.any` optional) only run where Gradle can build.
3. **Optional next steps** — more end-to-end journeys for the remaining quickstart scenarios, dependency
   and CI maintenance, or the desktop/web targets FR-023 allows for later releases.

## Gotchas worth knowing before changing tests

- **Never run two Flutter test commands at once.** They share `build/`, and the loser of the race can report
  `No tests were found.` for a file that is perfectly healthy (seen on `preferences_flow_test.dart` while a
  second `flutter test` was running in the same checkout). Re-run the file alone before believing a
  "no tests" result.
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
# No path: `test/unit test/widget` misses test/data, test/privacy,
# test/performance and test/golden — a stale golden is how the redesign first
# broke CI.
./.tooling/flutterw --no-version-check test --no-pub --concurrency=1
for f in integration_test/*_test.dart; do
  ./.tooling/flutterw --no-version-check test --no-pub "$f" || break
done
HOME=$PWD/.tooling/home ./.tooling/flutter/bin/cache/dart-sdk/bin/dart \
  format --output=none --set-exit-if-changed lib test integration_test
```

Intentional UI changes must regenerate the committed goldens:
`./.tooling/flutterw --no-version-check test --no-pub --update-goldens test/golden`
(then re-run without `--update-goldens` to prove they match).

Two CI traps already fixed once, do not reintroduce them:

- `aapt2 dump badging` prints `uses-feature-not-required: name='…'` on current
  build-tools and `uses-feature-not-required:'…'` on older ones; the manifest
  check normalises spaces and accepts both.
- `reactivecircus/android-emulator-runner` hands each *line* of `script` to
  `sh -c`, so a multi-line `for … done` loop fails immediately; keep it one line.

Then commit (scoped message, no `--global` git config needed) and `git push origin v2`.
