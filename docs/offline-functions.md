# Offline field functions

These additions follow the separately validated and pushed field-workbench UI
(commit `500eaac`). They reuse its controls and canonical calculation data rather
than introducing another backend or changing photography formulas.

## ND exposure countdown

- Open the exposure timer from the ND workflow, using the current **computed raw
  exposure**, not the rounded text shown on screen.
- The timer's target is frozen for that session. Start when ready; cancel or restart
  explicitly. Confirm closing an active countdown.
- Measure elapsed time from a clock, not by subtracting one unit per callback, so
  delayed frames do not accumulate timing drift.
- Support finite targets from one second through 24 hours. Shorter exposures belong
  to the camera's own timed shutter; longer valid calculations remain available
  even when the timer cannot handle them.
- This is a foreground field aid: **no camera control, background alarm or guaranteed
  shutter accuracy**. The user operates the camera and keeps the screen open.

## Saved-plan copying

- **Copy field brief** provides a readable shot reference from the saved record:
  answer and units, recorded settings, notes, equipment, planning context and
  relevant limitations.
- **Copy exact JSON** copies the supported snapshot's serialization, including its
  canonical values and version metadata. It is not a restore/import workflow or a
  promise to recover an unreadable record.
- Copy the original immutable saved data and display context, not current equipment
  values or temporary checklist edits. No physics is recalculated during export.
- Sharing can expose coordinates and private notes; the interface must say so.
  Clipboard success is shown only after the platform confirms the write.

## Acceptance checks

Deterministic timer tests cover elapsed-time behavior, fractional targets, bounds,
completion, cancellation/restart and disposal. Widget tests cover guarded closure
and the currently calculated duration. Saved-plan tests cover readable/unknown
metadata, exact JSON round trips, non-mutation, privacy hints and clipboard
success/failure without changing the real operating-system clipboard in tests.

Both features must retain the existing offline/privacy, canonical calculation,
SQLite and accessibility contracts. Final executed validation is recorded after the
implementation checks; this acceptance description alone is not a test result.

## Executed validation

Run on Flutter 3.47.5 through `./.tooling/flutterw` with `HOME`/`PUB_CACHE`
pinned inside `.tooling/`. Each command's transcript is in
`.tooling/functions-gate-*.log` and the final post-review
`.tooling/functions-final-*.log`, with explicit `EXIT=` markers.

| Check | Command | Result |
| --- | --- | --- |
| New feature tests | Five new files plus the final timer regression | **62 passed** (61 in Flash's feature run; 15 timer-widget tests rechecked after the extra case), `EXIT=0` |
| Full suite | `test --no-pub --concurrency=1 --timeout=30s` | **643 passed** (581 existing + 62 new), `EXIT=0` |
| Static analysis | `analyze --fatal-infos` | No issues found, `EXIT=0` |
| Formatting | `dart format --output=none --set-exit-if-changed lib test integration_test` | 177 files, 0 changed, `EXIT=0` |
| Linux release | `build linux --release --no-pub` | `build/linux/x64/release/bundle/photography_assistant`, `EXIT=0` |
| Integration journeys | `test --no-pub` on each of `integration_test/*_test.dart` | 8 files, all passed, `EXIT=0` each |

The 62 new tests are 20 timer-domain + 15 timer-widget + 14 saved-export unit +
10 saved-copy widget + 3 saved-library-scaling widget tests. No test is skipped
or suppressed, and every fixture unmounts the tree and pumps one frame before
`AppDatabase.close()`.

### Defect found and fixed by this validation

`LinearProgressIndicator(semanticsValue: '0 percent')` threw on every semantics
flush. On this SDK a determinate indicator is published with
`SemanticsRole.progressBar`, whose `value` must be a number or a percentage
(`_DebugSemanticsRoleChecks._semanticsProgressBar`); the worded value never
passed that check. The panel now leaves the value to the framework's own rounded
percentage, which carries the same information. One widget test also re-revealed
the screen action before tapping it, because revealing the note beneath it had
scrolled the button off the top of the viewport.

Sol's final source review found one additional state-transition edge case: if a
timer finished while the close-confirmation dialog was open, choosing **Keep timing**
overwrote the completed status with “Timer still running.” A deterministic regression
failed on that exact message before the fix; the announcement now respects the
completed state. All 15 timer-widget tests and the full 643-test suite passed after
the fix. Flash performed the major implementation, review and validation; Sol
performed UX acceptance, this small final fix/regression and the delivery checks.

### Presentation note, measured rather than assumed

At 320x568 with 200% text the timer dialog's content viewport is 448 px with a
124 px scroll extent, so the final "keep this screen open" line needs one scroll
gesture; the Close/Start actions stay pinned and hit-testable, and nothing
overflows. Measured with `.tooling/ui_capture/probe_timer_narrow_test.dart` and
visible in `04-timer-320w-200pct-ready.png` / `05-timer-320w-200pct-running.png`.

### Rendered captures

Reviewed examples: [Running timer](<screenshots/field-timer.png>) ·
[Saved-plan copy action](<screenshots/saved-copy.png>).

Real-font screenshots (Roboto + MaterialIcons from the pinned SDK) live in the
ignored `.tooling/ui_capture/functions/`, produced by
`.tooling/ui_capture/functions_capture_test.dart`:
`01-timer-ready.png`, `02-timer-running.png`, `03-timer-complete.png`,
`04-timer-320w-200pct-ready.png`, `05-timer-320w-200pct-running.png`,
`06-saved-detail-copy-actions.png`, `07-saved-detail-exact-json.png`,
`08-saved-detail-copy-confirmed.png`. Re-running the harness without
`--update-goldens` matches every one of them.
