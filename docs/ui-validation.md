# Field-workbench validation

## Verified environment

Flutter 3.47.5 / Dart 3.13.4 through `./.tooling/flutterw --no-version-check`.
All Flutter commands were serialized. Tests used local in-memory SQLite fixtures;
Linux integration journeys exercised the actual desktop app. No dependencies,
physical calculation models, repository interfaces or SQLite migrations changed.

## Final gates

| Check | Actual result |
|---|---|
| `flutter analyze --fatal-infos` | No issues, exit 0 |
| `dart format --output=none --set-exit-if-changed .` | 169 files, 0 changed, exit 0 |
| `flutter test --no-pub --concurrency=1 --timeout=30s` | **581 passed; 0 failed; 0 skipped**, exit 0 |
| Regenerate both intentional UI goldens, then full test run without `--update-goldens` | Both stable, exit 0 |
| Eight Linux integration journey files | **10 tests passed across 8 journeys**, exit 0 for each file |
| `flutter build linux --release --no-pub` | Release bundle built, exit 0 |
| Real-font screen captures | 18 main screens + 7 populated/theme/accessibility captures, exit 0 |

The journeys cover calculators, optics, equipment, planning, preferences, AR
fallback, accessibility and astronomy. The suite retains domain/reference,
hostile-input, database, privacy, performance, 320px, 200% text, bold-text and
landscape checks. Live-result tests verify the edited canonical values and applied
equipment are what actually get saved, rather than just checking that a card exists.
Additional regressions cover exact-unit adapters, full double precision, scientific
notation, keyboard focus during invalid edits, disclosure retention and inventory
filter isolation.

## Visual review

Sol reviewed actual rendered screens, including the launchpad, tool discovery,
calculator families, sky planning, populated Kit/editor and Saved/detail, low-light
and 200% text. The review prompted smaller preset rails, pinned live answers and
explicit search actions, less repetitive site setup, primary camera/extension
controls, and stable focus/disclosures. Flash generated the renders and ran all
major command-based validation.

Representative captures (real bundled fonts; synthetic local data):

- [Plan launchpad](<screenshots/workbench-plan.png>)
- [ND workflow and persistent answer](<screenshots/workbench-nd.png>)
- [Low-light depth of field](<screenshots/workbench-lowlight.png>)

The two committed test goldens intentionally use the stand-in test font; the
screenshots above document the readable real-font appearance.

## Limitations and observed tooling defects

- Android/iOS builds and physical-device sensors/camera were **not verified** in
  this environment: the mobile SDKs were unavailable. Linux exercises permission
  and unsupported-device fallbacks, not mobile sensor accuracy.
- The pinned Flutter SDK has a reproduced sliver/keep-alive visibility-bookkeeping
  defect after a preceding list child grows. A minimal vanilla-Flutter probe
  reproduced stale offsets/NaN transforms in finder visibility; rendered pictures
  were checked separately and remained correct. The UI tests settle and explicitly
  re-scroll the intended field before editing it. No exceptions, assertions or
  keep-alive behavior were suppressed. Recheck the probe when changing the SDK.
- Drift stream disposal schedules a zero-duration timer. Database-backed widget
  fixtures must unmount and advance fake time before closing the database;
  otherwise a failed test can hang in teardown. These fixtures were repaired and
  the equipment isolation cases also passed randomized order.

Diagnostic logs and temporary capture/probe harnesses are under gitignored
`.tooling/`; the published gate results above are the final successful runs,
not the intermediate failing runs used to find the issues.

## Work division

**Sol:** UX strategy, interaction architecture, implementation boundaries,
coordination, source/visual acceptance review, small precision/focus/hierarchy
fixes, and final Git delivery.

**Flash:** repository and Git-history investigation, baseline checks, all major
widget/screen implementation, test creation and migration, focused debugging,
render capture, analysis/tests/integration/build execution.
