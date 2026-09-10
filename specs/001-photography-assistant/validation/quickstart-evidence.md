# Quickstart execution record

Executed on 10 September 2026 from the agent sandbox on branch `v2`. This record covers the automated half
of the `quickstart.md` manual acceptance journey and states exactly which parts still need a physical
device, a simulator, or representative photographers.

It was first recorded at `c816578` (265 tests) and re-verified after the audit follow-up that added the
Sun/Moon scenarios and the warning-wording tests; the counts below are from that second run. Rows 21 and 28
are the only ones with device-only parts, and the sections after the table list the rest.

Commands and results:

```sh
./.tooling/flutterw --no-version-check test --no-pub --concurrency=1   # 277 passed
./.tooling/flutterw --no-version-check analyze --fatal-infos           # no issues
dart format --output=none --set-exit-if-changed lib test integration_test   # clean
./.tooling/flutterw --no-version-check test --no-pub integration_test/calculator_flows_test.dart  # 3 passed
./.tooling/flutterw --no-version-check test --no-pub integration_test/optics_flows_test.dart      # 1 passed
./.tooling/flutterw --no-version-check test --no-pub integration_test/equipment_flow_test.dart    # 1 passed
./.tooling/flutterw --no-version-check test --no-pub integration_test/planning_flow_test.dart     # 1 passed
./.tooling/flutterw --no-version-check test --no-pub integration_test/preferences_flow_test.dart  # 1 passed
./.tooling/flutterw --no-version-check test --no-pub integration_test/ar_fallback_flow_test.dart  # 1 passed
```

`flutter test integration_test/<file>` runs the journeys against the host Flutter engine (a Linux debug
bundle is built). Real SQLite files, permissions, sensors, and process death still require the emulator or
hardware run described in `quickstart.md`.

## Scenario coverage

| # | Scenario (abridged) | Automated evidence | Status |
|---|---------------------|--------------------|--------|
| 1 | Offline start, no sign-in | `test/widget/app/app_shell_test.dart`: starts offline with all primary navigation destinations; `test/privacy/no_network_test.dart`: primary journey never creates a Dart network client | Automated |
| 2 | Create custom camera and lens | `test/widget/features/equipment/equipment_screens_test.dart` (camera editor labels units; editor prefills an existing lens); `integration_test/equipment_flow_test.dart`: creates, restarts, archives, and restores equipment offline | Automated |
| 3 | Apply in depth of field, inspect assumptions | `test/unit/features/depth_of_field/depth_of_field_calculator_test.dart`: 50 mm at f/8 focused at 10 m, declares thin-lens assumptions and close-focus limitation; `calculator_screens_test.dart`: saved equipment applies values and identifies provenance | Automated |
| 4 | Unit change keeps physical equivalence (also end to end) | `depth_of_field_calculator_test.dart`: equivalent millimetre inputs produce identical physical results; `calculator_screens_test.dart`: expanded optics and macro honor imperial display preference | Automated |
| 5 | Swap exposures reverses the difference | `test/unit/features/exposure_comparison/exposure_calculator_test.dart`: swapping exposures negates stops and reciprocates the multiplier | Automated |
| 6 | 3-stop + 7-stop ND on 1/30 s | `test/unit/features/long_exposure/long_exposure_calculator_test.dart`: stacked three and seven stops multiply by 1024; `integration_test/calculator_flows_test.dart` | Automated |
| 7 | Save, edit/archive lens, restart, unchanged payloads | `integration_test/calculator_flows_test.dart`: calculates manually and from saved equipment offline; `snapshot_repository_test.dart`: metadata update never rewrites calculation payload columns | Automated; a real Android process restart is recorded separately in `android.md` |
| 8 | 200% text and screen reader | `test/widget/features/calculators/text_scale_test.dart` (all thirteen screens), `test/widget/core/calculator_components_test.dart`: result exposes the exact calculation inputs accessibly | Automated at widget level; a device screen-reader walkthrough remains manual |
| 9 | 36 × 24 mm at 50 mm field of view | `test/unit/features/optics/optics_calculators_test.dart`: field of view matches a 36 × 24 mm sensor with a 50 mm rectilinear lens; `expanded_calculators_reference_test.dart` | Automated |
| 10 | f/8, 550 nm, 4 µm Airy disk | `optics_calculators_test.dart`: diffraction uses the first Airy minimum diameter; `expanded_calculators_reference_test.dart` (10.736 µm, 2.684 px) | Automated |
| 11 | 0.5–1 m focus stack at 100 mm | `optics_calculators_test.dart`: focus stacking returns ordered positions covering the requested range | Automated |
| 12 | Guide number 40 at 5 m | `test/unit/features/flash_exposure/flash_exposure_calculator_test.dart`: guide number 40 at five metres recommends f/8 | Automated |
| 13 | One-hour ten-second timelapse | `test/unit/features/timelapse/timelapse_calculator_test.dart`: plans an inclusive one-hour ten-second sequence | Automated |
| 14 | 25 mm tube on 50 mm at 0.2x | `test/unit/features/macro/macro_calculator_test.dart`: extension adds extension divided by focal length magnification; `expanded_calculators_reference_test.dart` (0.70x, f/13.6, 51.4 mm) | Automated |
| 15 | Reversed versus coupled lenses | `macro_calculator_test.dart`: reversed lens uses flange distance as an explicit estimate; coupled lenses use primary divided by reversed focal length | Automated |
| 16 | 90° × 45° panorama at 30% overlap | `test/unit/features/panorama/panorama_calculator_test.dart`: plans a single horizontal row with minimum covering frames; `expanded_calculators_reference_test.dart` (3 × 2, six frames) | Automated |
| 17 | Sirius at Greenwich, 500/NPF rules | `test/unit/features/astronomy/astronomy_calculator_test.dart`: places Sirius for the documented Greenwich fixture; calculates 500, NPF, and star-trail guidance | Automated |
| 18 | One-year alignment range across DST | `test/unit/features/alignment/alignment_calculator_test.dart`; `planning_time_context_test.dart`: converts inclusive local date ranges across daylight saving; `release_budgets_test.dart`: one-year alignment search remains below five seconds | Automated |
| 19 | Views usable without permissions | `integration_test/ar_fallback_flow_test.dart` opens the AR view on a machine with no camera and proves it explains itself (`AR unavailable` or `Camera unavailable`) while the numeric plan still renders; `test/widget/features/planning/live_compass_view_test.dart`, `offline_planning_map_test.dart`, `planning_disclosure_test.dart` cover the widget layer | Automated (host has no camera, which is the unavailable case); physical permission denial remains manual |
| 20 | Saved location survives an offline restart | `integration_test/planning_flow_test.dart`: Milky Way plan survives closing and reopening its on-device database; `saved_locations_screen_test.dart` | Automated (real SQLite file on the host engine) |
| 21 | Live AR with real camera and compass | none | **Device only — pending T058/T059** |
| 22 | Stop increments and planner defaults | `test/unit/core/presentation/conventional_shutter_formatter_test.dart`; `calculator_screens_test.dart`: planner defaults come from preferences and remain overridable | Automated |
| 23 | Night-sky snapshot preserves planning context | `integration_test/preferences_flow_test.dart` asserts a saved plan keeps its `distanceUnit: metric` context after the display preference changes; `calculator_screens_test.dart`: night-sky plans preserve saved observer elevation; `saved_calculations_test.dart`: opens immutable details and edits metadata only; `solar_lunar_fixture_test.dart` for the astronomy tolerances | Automated |
| 24 | Milky Way projected orientation | `test/unit/features/astronomy/milky_way_orientation_test.dart` (eight orientation, wrap, and singularity cases) | Automated |
| 25 | Camera notes, delete, archive | `equipment_screens_test.dart`: archive action retires active equipment; referenced equipment is archived instead of deleted; editor preserves an existing teleconverter kind; `app_database_test.dart` v3 and v5 fixtures | Automated |
| 26 | Labelled input summary at 200% | `calculator_components_test.dart`: result exposes the exact calculation inputs accessibly; `text_scale_test.dart` | Automated |
| 27 | Editing invalidates until recalculation | `test/widget/features/calculators/calculation_invalidation_test.dart` (thirteen screens, cursor-only edits, provenance-only swap, save journey) | Automated |
| 28 | Sun and Moon night-sky targets | `test/widget/features/calculators/result_reporting_test.dart`: the night-sky planner warns about solar safety for the Sun; `test/unit/features/astronomy/solar_lunar_fixture_test.dart`; `test/widget/features/saved_calculations/saved_calculations_test.dart`: renders saved warnings with a readable calculator label | Automated; the in-preview AR banner needs a device |

## What remains manual

- Scenario 21 and every real sensor, camera, and permission transition (T058 Android, T059 iOS).
- A screen-reader walkthrough of the journeys on a device; the automated checks cover semantics labels,
  focus order, and 200% text scale, not assistive-technology behaviour.
- Android and iOS process death and cold start on real hardware; `android.md` records one force-stop check,
  and no iOS device evidence exists yet.
- Representative-photographer usability for SC-002 and SC-003 (T062).
- The merged release manifest assertions added to `mobile-builds` only run on CI, because no Gradle build is
  possible in this sandbox.

This record supersedes the informal "remaining release evidence" list for the automated half of the
journey; `android.md` remains the Android device record and `privacy.md` the privacy audit.
