# Tasks: Photography Assistant Foundation

**Input**: Design documents from `specs/001-photography-assistant/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Test-first development is mandatory under the constitution. Each behavior task begins with a
failing test or reference fixture and completes only after that test passes.

**Scope**: Complete active specification. The original mobile foundation is complete; remaining calculators
and planners are delivered as independently tested increments in story-priority order.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it changes different files and has no incomplete dependency
- **[Story]**: User story traceability from spec.md

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create a reproducible Flutter application and CI baseline.

- [X] T001 Create the Android/iOS Flutter application scaffold and package identity in `pubspec.yaml`, `lib/main.dart`, `android/`, and `ios/`
- [X] T002 Pin Flutter/Dart constraints and approved runtime/dev dependencies in `pubspec.yaml` and `pubspec.lock`
- [X] T003 [P] Configure strict analyzer and formatter policy in `analysis_options.yaml`
- [X] T004 [P] Create the feature-oriented directory skeleton with library documentation in `lib/app/`, `lib/core/`, and `lib/features/`
- [X] T005 [P] Add generated/build/IDE exclusions and repository metadata in `.gitignore` and `README.md`
- [X] T006 Configure pull-request CI for format, analysis, and unit/widget/data tests in `.github/workflows/ci.yml`
- [X] T007 Configure Android build validation on Linux and iOS simulator build validation on macOS in `.github/workflows/mobile-builds.yml`

**Checkpoint**: A clean scaffold resolves dependencies and CI can analyze, test, and build both targets.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement shared quantity, result, storage, theme, and navigation contracts required by all
first-release stories.

**⚠️ CRITICAL**: No user story implementation begins until this phase passes.

- [X] T008 [P] Write failing finite-value and unit-conversion tests in `test/unit/core/domain/quantities_test.dart`
- [X] T009 [P] Write failing calculator result/status contract tests in `test/unit/core/domain/calculation_result_test.dart`
- [X] T010 Implement immutable physical quantity value objects in `lib/core/domain/quantities/quantities.dart`
- [X] T011 Implement typed validation errors, warnings, assumptions, and calculation results in `lib/core/domain/validation/` and `lib/core/domain/calculation_result.dart`
- [X] T012 [P] Define equipment and snapshot repository interfaces in `lib/core/domain/repositories/`
- [X] T013 Define Drift tables, stable text enums, foreign keys, and schema version 1 in `lib/core/data/database/app_database.dart`
- [X] T014 [P] Write failing schema, constraint, transaction, and migration tests in `test/data/database/app_database_test.dart`
- [X] T015 Implement database initialization, migrations, and deterministic in-memory test factory in `lib/core/data/database/`
- [X] T016 [P] Implement local preferences model/repository and tests in `lib/core/data/repositories/preferences_repository.dart` and `test/data/repositories/preferences_repository_test.dart`
- [X] T017 [P] Implement accessible light, dark, and low-light themes in `lib/app/theme/app_theme.dart` and tests in `test/widget/app/theme_test.dart`
- [X] T018 Create the application shell, dependency providers, navigation destinations, and error boundary in `lib/app/app.dart`, `lib/app/navigation.dart`, and `lib/app/providers.dart`
- [X] T019 Add shell navigation, semantics, 200%-text-scale, and offline-start widget tests in `test/widget/app/app_shell_test.dart`

**Checkpoint**: Shared contracts, database, preferences, themes, and app shell pass tests without any
calculator-specific implementation.

---

## Phase 3: User Story 2 - Reuse Camera and Lens Equipment (Priority: P1) 🎯 First Increment

**Goal**: Users can create, edit, archive, restore, and select camera bodies, lenses, and ND filters offline.

**Independent Test**: Create custom equipment, restart offline, edit/archive/restore it, and select it from
an in-memory consumer while provenance and validation remain correct.

### Tests for User Story 2

- [X] T020 [P] [US2] Write failing camera, lens, and ND filter entity validation tests in `test/unit/features/equipment/domain/equipment_test.dart`
- [X] T021 [P] [US2] Write failing equipment repository CRUD/archive/reference tests in `test/data/features/equipment/equipment_repository_test.dart`
- [X] T022 [P] [US2] Write failing equipment list/editor semantics and 200%-text-scale tests in `test/widget/features/equipment/equipment_screens_test.dart`
- [X] T023 [US2] Write the failing offline equipment integration journey in `integration_test/equipment_flow_test.dart`

### Implementation for User Story 2

- [X] T024 [P] [US2] Implement camera, lens, filter, provenance, normalization, and lifecycle entities in `lib/features/equipment/domain/equipment.dart`
- [X] T025 [US2] Implement Drift equipment mapping and repository operations in `lib/features/equipment/data/drift_equipment_repository.dart`
- [X] T026 [US2] Implement equipment list/filter/archive/restore presentation state in `lib/features/equipment/presentation/equipment_controller.dart`
- [X] T027 [US2] Implement accessible equipment list and empty/error states in `lib/features/equipment/presentation/equipment_list_screen.dart`
- [X] T028 [US2] Implement validated camera, lens, and ND filter editors with provenance fields in `lib/features/equipment/presentation/equipment_editor_screen.dart`
- [X] T029 [US2] Implement reusable equipment picker and one-off override controls in `lib/features/equipment/presentation/equipment_picker.dart`
- [X] T030 [US2] Complete the offline integration journey and fixture seeding in `integration_test/equipment_flow_test.dart` and `test/fixtures/equipment_fixtures.dart`

**Checkpoint**: Equipment inventory is a complete independently usable offline increment.

---

## Phase 4: User Story 1 - Calculate a Photograph (Priority: P1) 🎯 MVP

**Goal**: Users can calculate depth of field/hyperfocal distance, compare exposures, and calculate
long-exposure/ND timing using manual or saved equipment inputs.

**Independent Test**: Run documented normal, boundary, invalid, inverse, symmetry, stacked-filter, and unit
conversion fixtures for each calculator and complete each screen offline with and without inventory.

### Tests for User Story 1

- [X] T031 [P] [US1] Document exact formulas, authoritative Zeiss fixture citations, input conventions, and tolerances, then add failing depth-of-field/hyperfocal tests in `test/fixtures/depth_of_field_fixtures.dart` and `test/unit/features/depth_of_field/depth_of_field_calculator_test.dart`
- [X] T032 [P] [US1] Add exposure symmetry/component fixtures and failing tests in `test/fixtures/exposure_fixtures.dart` and `test/unit/features/exposure_comparison/exposure_calculator_test.dart`
- [X] T033 [P] [US1] Add ND stop/filter-factor/optical-density fixtures and failing tests in `test/fixtures/long_exposure_fixtures.dart` and `test/unit/features/long_exposure/long_exposure_calculator_test.dart`
- [X] T034 [P] [US1] Write calculator input, validation, result, assumptions, and accessibility widget tests in `test/widget/features/calculators/calculator_screens_test.dart`
- [X] T035 [US1] Write the failing manual/equipment calculator integration journeys in `integration_test/calculator_flows_test.dart`

### Implementation for User Story 1

- [X] T036 [P] [US1] Implement versioned thin-lens depth-of-field and hyperfocal domain model in `lib/features/depth_of_field/domain/depth_of_field_calculator.dart`
- [X] T037 [P] [US1] Implement versioned exposure comparison stop model in `lib/features/exposure_comparison/domain/exposure_calculator.dart`
- [X] T038 [P] [US1] Implement versioned long-exposure/ND and inverse filter model in `lib/features/long_exposure/domain/long_exposure_calculator.dart`
- [X] T039 [US1] Implement shared calculator form/result/provenance components in `lib/core/presentation/calculator/`
- [X] T040 [P] [US1] Implement depth-of-field state and accessible screen in `lib/features/depth_of_field/presentation/`
- [X] T041 [P] [US1] Implement exposure-comparison state and accessible screen in `lib/features/exposure_comparison/presentation/`
- [X] T042 [P] [US1] Implement long-exposure/ND state and accessible screen in `lib/features/long_exposure/presentation/`
- [X] T043 [US1] Register calculator catalog metadata, favorites, and navigation in `lib/app/calculator_catalog.dart` and `lib/app/navigation.dart`
- [X] T044 [US1] Complete all calculator integration journeys and offline assertions in `integration_test/calculator_flows_test.dart`

**Checkpoint**: The approved calculators work independently with manual inputs and integrate with equipment.

---

## Phase 5: User Story 7 - Save and Reopen a Calculation (Priority: P3)

**Goal**: Users save immutable calculation snapshots with notes and reopen them offline after equipment or
preference changes.

**Independent Test**: Save one result from every calculator, edit/archive referenced equipment and change
units, restart offline, and verify every original canonical value, assumption, warning, and display context.

### Tests for User Story 7

- [X] T045 [P] [US7] Write failing snapshot serialization/versioning/immutability tests in `test/unit/core/domain/calculation_snapshot_test.dart`
- [X] T046 [P] [US7] Write failing snapshot persistence, corruption, and legacy-version tests in `test/data/repositories/snapshot_repository_test.dart`
- [X] T047 [P] [US7] Write failing saved-calculation list/detail semantics and recovery tests in `test/widget/features/saved_calculations/saved_calculations_test.dart`
- [X] T048 [US7] Extend the failing restart/offline integration journey in `integration_test/calculator_flows_test.dart`

### Implementation for User Story 7

- [X] T049 [P] [US7] Implement versioned immutable snapshot entity and codecs in `lib/core/domain/calculation_snapshot.dart`
- [X] T050 [US7] Implement transactional Drift snapshot repository and corruption recovery in `lib/core/data/repositories/drift_snapshot_repository.dart`
- [X] T051 [US7] Add snapshot save actions to shared results in `lib/core/presentation/calculator/calculation_result_view.dart`
- [X] T052 [US7] Implement saved-calculation list, detail, notes, and delete flows in `lib/features/saved_calculations/presentation/`
- [X] T053 [US7] Complete snapshot restart, equipment mutation, preference change, and recovery integration cases in `integration_test/calculator_flows_test.dart`

**Checkpoint**: Saved results remain explainable and unchanged across restarts and equipment edits.

---

## Phase 6: Polish & Cross-Cutting Release Gates

**Purpose**: Validate the complete first-release slice on both platforms and close quality risks.

- [X] T054 [P] Audit all user-visible strings, units, help, limitations, and recovery messages in `lib/` and add missing assertions in `test/widget/`
- [X] T055 [P] Add stable golden coverage for calculator and equipment states in `test/golden/`
- [X] T056 [P] Add database migration fixtures and backup/recovery documentation in `test/fixtures/database/` and `README.md`
- [X] T057 Profile calculation, launch, inventory, and scrolling budgets and record results in `specs/001-photography-assistant/performance-results.md`
- [ ] T058 Run the complete Android quickstart and record device/API evidence in `specs/001-photography-assistant/validation/android.md`
- [ ] T059 Run the complete iOS quickstart and record simulator/device evidence in `specs/001-photography-assistant/validation/ios.md`
- [X] T060 Verify CI branch protection requirements and document merge-request workflow in `CONTRIBUTING.md`
- [ ] T061 Execute every scenario in `specs/001-photography-assistant/quickstart.md` and resolve all failures
- [ ] T062 Conduct first-attempt usability validation for SC-002 and SC-003 with representative photographers and record anonymized protocol/results in `specs/001-photography-assistant/validation/usability.md`
- [X] T063 Audit the release dependency graph and Android/iOS network traffic to prove SC-010 local-only behavior, documenting evidence in `specs/001-photography-assistant/validation/privacy.md`

---

## Phase 7: User Story 1 - Complete the Core Calculator Catalog (Priority: P1)

**Goal**: Add field-of-view, diffraction, focus-stack, flash-exposure, and timelapse tools with the same
offline, saved-result, accessible contracts as the delivered calculators.

**Independent Test**: Run documented fixtures and invalid boundaries for every calculator, save each
result, restart offline, and confirm its inputs, outputs, assumptions, and limitations remain available.

- [X] T064 [P] [US1] Add field-of-view, diffraction, and focus-stack reference tests in `test/unit/features/optics/optics_calculators_test.dart`
- [X] T065 [P] [US1] Implement field-of-view and scene-coverage calculations in `lib/features/optics/domain/optics_calculators.dart`
- [X] T066 [P] [US1] Implement Airy-disk diffraction guidance in `lib/features/optics/domain/optics_calculators.dart`
- [X] T067 [P] [US1] Implement ordered thin-lens focus-stack planning in `lib/features/optics/domain/optics_calculators.dart`
- [X] T068 [US1] Add accessible inputs, guidance, validation, and saved snapshots in `lib/features/optics/presentation/optics_screens.dart`
- [X] T069 [US1] Register the optics tools and favorites in `lib/app/calculator_catalog.dart`
- [X] T070 [P] [US1] Add reference-tested guide-number and power-ratio flash calculations in `lib/features/flash_exposure/`
- [X] T071 [P] [US1] Add interval, duration, frame-count, playback, storage, and exposure-ramp timelapse planning in `lib/features/timelapse/`
- [X] T072 [US1] Extend calculator widget and offline integration journeys in `test/widget/features/calculators/` and `integration_test/calculator_flows_test.dart`

---

## Phase 8: User Story 3 - Plan Macro Magnification (Priority: P2)

**Independent Test**: Compare extension-tube, reversed-lens, and coupled-lens configurations against
documented fixtures using manual and saved equipment values.

- [X] T073 [P] [US3] Add extension tube and converter inventory entities and persistence in `lib/features/equipment/`
- [X] T074 [P] [US3] Add macro reference fixtures and domain tests in `test/unit/features/macro/`
- [X] T075 [US3] Implement extension, reversed-lens, and coupled-lens models in `lib/features/macro/domain/`
- [X] T076 [US3] Implement model-specific macro inputs, comparison results, guidance, and snapshots in `lib/features/macro/presentation/`

---

## Phase 9: User Story 6 - Plan Panoramas and Stacks (Priority: P3)

**Independent Test**: Verify horizontal, vertical, and multi-row grids cover reference bounds with the
requested overlap and correct orientation.

- [X] T077 [P] [US6] Add panorama geometry fixtures and tests in `test/unit/features/panorama/`
- [X] T078 [US6] Implement frame-grid, overlap, increment, and coverage planning in `lib/features/panorama/`

---

## Phase 10: User Stories 4 and 5 - Celestial and Alignment Planning (Priority: P2)

**Independent Test**: Compare positions, events, and alignment candidates for known coordinates and times,
then repeat offline and with every location/camera/sensor permission denied.

- [X] T079 [P] [US4] Select, license, document, and fixture-test astronomical algorithms and offline data in `specs/001-photography-assistant/research.md` and `test/fixtures/astronomy/`
- [X] T080 [US4] Implement target positions, events, Milky Way, star shutter, and star-trail numeric planning in `lib/features/astronomy/`
- [X] T081 [P] [US5] Implement Sun/Moon bearing and elevation alignment search with safety guidance in `lib/features/alignment/`
- [X] T082 [US4] Add saved locations/plans and map, compass, timeline, numeric, permission-fallback, and capability-gated AR views in `lib/features/planning/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** starts immediately.
- **Foundational (Phase 2)** depends on Setup and blocks every story.
- **US2 Equipment (Phase 3)** depends on Foundational and is delivered first because calculators reuse it.
- **US1 Calculators (Phase 4)** depends on Foundational; manual-input domain work can run alongside US2,
  but equipment integration tasks T039-T044 depend on T029-T030.
- **US7 Snapshots (Phase 5)** depends on completed calculator result contracts from US1.
- **Release Gates (Phase 6)** depend on US1, US2, and the first-release subset of US7.

### User Story Dependencies

```text
Setup -> Foundation -> US2 Equipment ----┐
                    -> US1 Domain -------+-> US1 Integrated Calculators -> US7 Snapshots -> Release
```

The delivered foundation enables Phase 7 immediately. Macro and panorama reuse optics and equipment;
astronomy/alignment may proceed after its algorithm, licensing, accuracy, and privacy research gate passes.

### Within Each User Story

- Write and observe failing tests before implementing behavior.
- Implement value/entity models before repositories and controllers.
- Implement pure calculator domains before presentation.
- Complete widget/semantics tests before integration journeys.
- Finish the story checkpoint before merging its branch.

### Parallel Opportunities

- T003-T005 and later T006-T007 touch independent setup files.
- T008-T009, T012, T014, T016-T017 can proceed in parallel within foundation dependency limits.
- US2 test files T020-T022 and domain task T024 are independent initially.
- Calculator fixtures/tests T031-T034 and calculators T036-T038 are isolated by feature.
- Calculator screens T040-T042 can proceed after shared components T039.
- Snapshot tests T045-T047 can proceed in parallel.
- Cross-cutting audit/golden/migration work T054-T056 can proceed in parallel.

## Parallel Example: User Story 1

```text
T031 depth-of-field fixtures/tests || T032 exposure fixtures/tests || T033 ND fixtures/tests
T036 depth-of-field domain         || T037 exposure domain         || T038 ND domain
T040 depth-of-field screen         || T041 exposure screen         || T042 ND screen
```

## Implementation Strategy

### Smallest Demonstrable Increment

1. Complete Setup and Foundation.
2. Complete US2 inventory because it exercises persistence and shared mobile UX.
3. Demonstrate offline create/edit/archive/restore on Android and iOS.

### First Public Release

1. Add US1 calculators using test-first reference fixtures.
2. Add the calculation-snapshot subset of US7.
3. Complete all release gates and device evidence.
4. Ship only after Android and iOS acceptance criteria both pass.

### Branch and Review Policy

- Complete initial scaffolding on `v2` while direct pushes are authorized.
- Once scaffolding and CI exist, create one short-lived branch per logical task group.
- Use merge requests with green CI and constitution review before merging.
- Commit after each independently verified logical group; never mix deferred product scope into foundation
  changes.

## Format Validation

All 82 tasks use the required checkbox, sequential task ID, optional `[P]`, required user-story label in
story phases, actionable description, and exact file path.

## Phase 11: Convergence

- [X] T083 [US1] Add searchable, purpose-grouped, favorites-filterable catalog discovery per FR-001 (partial)
- [X] T084 [US4] Expand the offline celestial catalog with planets and notable deep-sky targets plus searchable metadata per FR-009 (partial)
- [X] T085 [US4] Add target path samples and local-time event presentation with explicit time-zone, north-reference, horizon, freshness, and accuracy context per FR-009 and FR-013 (partial)
- [X] T086 [US4] Add a persisted true/magnetic north preference and surface reference/calibration state in compass and AR planning per FR-012 and FR-020 (partial)
- [X] T087 [US4] Add live device-orientation-aware AR positioning and permission/capability fallbacks per FR-011 and FR-012 (partial)
- [X] T088 [US7] Extend immutable observation-plan snapshots and editable field checklists across celestial planners per FR-014 (partial)

## Phase 12: Convergence

- [X] T089 [US4] Add numeric, timeline, compass, offline-map, and capability-gated AR views to the night-sky planner per FR-011 and US4/AC3 (partial)
- [X] T090 [US5] Add start/end date controls and multi-day candidate grouping to the Sun/Moon alignment UI per FR-010 and US5/AC1 (partial)
- [X] T091 [US4] Add selectable 500/NPF shutter rules and an explicit sharpness-tolerance choice preserved in saved plans per FR-005 and US4/AC2 (partial)
- [X] T092 [US4] Replace or calibrate the circular planet model against documented authoritative position/event fixtures and declare supported tolerances per SC-004 and FR-022 (partial)

## Phase 13: Convergence

- [X] T093 [US5] Accept a target coordinate and derive geodesic bearing/distance while preserving manual geometry overrides per FR-010 and US5 (partial)
- [X] T094 [US4] Apply user-supplied magnetic declination to compass/AR bearings with explicit reference and snapshot context per FR-012, FR-013, and FR-020 (partial)
- [X] T095 [US4] Resolve bundled IANA timezone/DST rules offline for saved planning locations per FR-013 and US4/AC1 (partial)
- [X] T096 [US4] Incorporate live device pitch into AR vertical target placement with unavailable-sensor fallback per FR-011 and FR-012 (partial)
- [X] T097 [US7] Render saved observation plans and field checklists as actionable plan details rather than generic payload rows per FR-014 and US7/AC2 (partial)

## Phase 14: Convergence

- [X] T098 [US2] Add prefilled equipment editing and duplication actions across every inventory type per US2 independent test (missing)
- [X] T099 [US2] Warn before editing or archiving referenced equipment while preserving immutable saved snapshots per US2/AC3 and FR-014 (partial)
- [X] T100 [US1] Apply compatible saved camera and lens values, one-off overrides, and snapshot provenance in optics tools per FR-008 (partial)
- [X] T101 [US4] Recompute moving-target ephemerides while solving planet events and expose the calibrated model with reference fixtures per FR-009 and SC-004 (partial)
- [X] T102 [US4] Preserve saved observer elevation and disclose it in night-sky results and immutable snapshots per FR-013 and US4/AC1 (partial)
- [X] T103 [US1] Apply the saved length-unit preference to expanded optics and macro result presentation without changing canonical values per FR-020 and US1/AC3 (partial)

## Phase 15: Convergence

- [X] T104 [US4] CRITICAL compare AR target and device headings in the same magnetic reference while preserving explicit true/magnetic labels per Constitution I and FR-012 (contradicts)
- [X] T105 [US4] Add reusable live compass views with calibration accuracy, declination, north preference, and unavailable-sensor fallback to both planners per FR-011 and FR-012 (partial)
- [X] T106 [US4] Replace textual map placeholders with accessible offline spatial schematics for celestial paths and alignment candidates per FR-011 and US4/AC3 (partial)
- [X] T107 [US4] Add direct local date/time selection with bundled timezone and daylight-saving conversion to the night-sky planner per US4 and Constitution V (partial)

## Phase 16: Alignment Range and Context Convergence

- [X] T108 [P] [US5] Add regression tests for a one-year alignment range, bounded ordered candidates, performance budget, and local civil-date conversion across daylight-saving transitions per SC-009 and Constitution II (contradicts)
- [X] T109 [US5] Replace the 31-day alignment cap with a memory-bounded one-year search and update its documented contract, limitations, and accuracy policy per SC-009 and Constitution I (contradicts)
- [X] T110 [US5] Replace UTC-only alignment day steppers with direct inclusive local civil-date range selection using saved-location timezone rules and canonical UTC search bounds per US5 and FR-013 (partial)
- [X] T111 [US5] Add accessible, locally grouped alignment timeline candidates and complete reproducibility context for location, timezone confidence, elevations, horizon/refraction, source freshness, north reference, and expected accuracy in results and saved snapshots per FR-011, FR-013, and SC-008 (partial)

## Phase 17: Preferences and Planning Metadata Convergence

- [X] T112 [US1] Apply the persisted whole/half/third-stop increment preference to conventional shutter presentation with pure formatter, widget, and snapshot regression coverage per FR-020 (contradicts)
- [X] T113 [US4] Persist user-selectable default star-sharpness and alignment angular tolerances through a tested schema migration, expose them accessibly in settings, and apply them as overridable planner defaults per the User Preferences entity and Constitution V (partial)
- [X] T114 [US4] Replace the generic night-sky context block with complete location source/accuracy/timestamp, local/UTC time, timezone confidence, north reference, elevation, horizon/refraction, source freshness, and explicit expected-accuracy context preserved in immutable snapshots per FR-013 and SC-008 (partial)
- [X] T115 [US4] Add versioned offline celestial-catalog metadata, provenance, supported epoch, maintenance policy, and explicit current/stale status to results and documentation per FR-009, FR-021, and plan: bundled dataset update policy (partial)

## Phase 18: Convergence

- [X] T116 [US1] Add a standardized, accessible input summary to every calculator result so users can interpret outputs without scrolling back through editable controls per US1/AC1 and FR-002 (partial)
- [X] T117 [US2] Permanently delete unreferenced equipment through a confirmed inventory action while retaining the archive-and-warning path for referenced equipment per US2 independent test and the Equipment state-transition contract (partial)
- [X] T118 [US2] Preserve optional camera notes through the domain model, schema migration, editor, duplication, and repository mapping with regression coverage per US2/AC2 (partial)
- [X] T119 [US4] Calculate, display, and snapshot the Milky Way core's projected orientation with declared convention and reference coverage per US4 independent test and Constitution I (missing)

Phase 18 validation (2026-09-07): 195 local tests pass, including independent Milky Way orientation
fixtures, 200% text-scale presentation, camera-note preservation and the frozen v5-to-v6 migration.
The Android planning integration test closes and reopens a real SQLite file and verifies the entire
saved plan is unchanged. See `validation/android.md` for device evidence and remaining release gates.

## Phase 19: Result Input Consistency

- [X] T120 [US1] Invalidate displayed and savable results when manual inputs or applied equipment change, including unchanged numeric values with changed equipment provenance; verify every calculator, cursor-only edits, recomputation, and an Android save journey per the Calculator state-transition contract and FR-002/FR-014.

Phase 19 validation (2026-09-10): `test/widget/features/calculators/calculation_invalidation_test.dart`
drives all twelve calculators plus the alignment planner through calculate, edit, invalidate, recompute,
and save against an in-memory database; it also proves that caret/selection-only edits keep the result and
that swapping to an optically identical saved lens invalidates through provenance alone. The offline
integration journey `editing an input blocks saving until the result is recalculated` executes the same
state transition on a host build of the app (`flutter test integration_test/calculator_flows_test.dart`,
3/3 journeys passed); physical Android/iOS execution stays with the open quickstart passes T058/T059
because the agent sandbox has no KVM device. Local suite (210 tests), analyzer, and formatter are clean.

## Phase 20: Convergence

Converge pass (2026-09-10) assessed the committed tree at `d6d16bf` against all 24 functional
requirements, 12 success criteria, and the seven user stories. Nothing violates a constitution MUST
principle, so the findings below are ordered by user impact rather than by blocker severity.

- [X] T121 [US4] Add Sun and Moon rise/set/transit events, visibility cycles, and path sampling to the celestial planner so the alignment planner is not the only Sun/Moon model per FR-009 (partial)
- [X] T122 [US4] Commit externally traceable reference fixtures for Sun, Moon, and Sirius positions plus one rise/set/transit event set, asserted at the declared tolerance per SC-004 and FR-022 (partial)
- [X] T123 [P] [US1] Add offline integration journeys with device evidence for macro, panorama, field of view, diffraction, and focus stacking per FR-022 and SC-012 (missing)
- [X] T124 [US4] Stop recording unapplied camera sensor values in night-sky snapshots by applying camera-derived crop factor and pixel pitch, or by recording only what the calculation used, per FR-008 (contradicts)
- [X] T125 [P] [US2] Bind the accessory-type editor to the edited item's kind so teleconverter edits and duplicates keep their type per US2/AC2 (contradicts)
- [X] T126 [US1] Show the ND filter value actually applied by the calculation rather than the inventory value after a one-off override per FR-008 (contradicts)
- [X] T127 [P] [US4] Remove the unused `RECORD_AUDIO` and legacy `WRITE_EXTERNAL_STORAGE` permissions that the camera plugin merges into the release manifest per FR-017 (contradicts)
- [X] T128 [P] [US1] Re-run and record the privacy audit at the current HEAD, including location, sensor, and camera SDKs and the iOS usage descriptions, per FR-016 and SC-010 (contradicts)
- [X] T129 [US4] Detect planning capability state and pass it to both planners so the documented AR-unavailable path is reachable per FR-012 (partial)
- [X] T130 [US3] Add a saved camera picker to the macro planner so the required sensor width carries provenance per FR-008 (partial)
- [X] T131 [US1] Show the applied equipment source and note, not just the name and values, in the provenance notice per FR-008 (partial)
- [X] T132 [US3] Surface and persist the focus-stack frame-limit limitation instead of dropping it before presentation per FR-002 and FR-021 (partial)
- [X] T133 [US1] Map the not-beyond-focal-length validation code to its corrective field message per US1/AC2 (partial)
- [X] T134 [US5] Render saved warning payloads, including solar safety guidance, on the saved plan detail per FR-018 and US5/AC3 (partial)
- [X] T135 [US4] Disclose the elevation fallback when a saved location has none instead of silently substituting or reusing a value per FR-021 and US5/AC2 (partial)
- [X] T136 [US4] Replace or explicitly disclose the fixed 60° field-of-view assumption used to place AR targets per FR-013 and FR-021 (partial)
- [X] T137 [P] [US1] Commit cited reference fixtures with boundary values for optics, macro, panorama, flash, and timelapse per SC-001 and FR-022 (partial)
- [X] T138 [P] [US1] Add parameterized 200%-text-scale and semantics coverage for every calculator and planner screen per FR-019 (partial)
- [X] T139 [P] [US1] Add fixtures covering the v0 creation and v3-to-v4 preference migration paths per FR-022 (partial)
- [X] T140 [US2] Add an Archive action for active equipment with the referenced-item warning and remove the unreachable archive branch per US2/AC3 and T099 (partial)
- [X] T141 [US3] Apply converter magnification in a compatible planner or document it as inventory-only per FR-007 and FR-008 (partial)
- [X] T142 [US7] Map all twelve calculator identifiers to readable labels in the saved-results list per FR-014 (partial)
- [X] T143 [US5] Show horizon state in the numeric alignment candidate list per FR-011 and US5/AC1 (partial)
- [X] T144 [US1] Add an explicit limitations line to the exposure-comparison result per FR-002 and US1/AC1 (partial)
- [X] T145 [US1] Display the front and rear depth around the focus plane per the depth-of-field contract (partial)
- [X] T146 [P] [US1] Extend the offline network guard to inventory, saved-plan reopening, and both planners per FR-015 and SC-010 (partial)
- [X] T147 [US2] Implement or narrow the equipment repository interface and provide a deterministic in-memory fake per the equipment repository contract (partial)
- [X] T148 [P] [US1] Extend release performance budgets beyond the three foundation calculators and state what remains device-only per SC-009 (partial)
- [X] T149 [US1] Resolve or justify the unrequested desktop release workflow, orphaned override control, unused domain helper, and planet constants that expose zero-valued positions per scope and FR-021 hygiene (unrequested)
- [X] T150 [US1] Extend equipment-provenance invalidation coverage beyond depth of field to the remaining equipment-consuming calculators per T120 and FR-008 (partial)
- [X] T151 [P] [US4] Keep camera-less devices installable by declaring the merged `android.hardware.camera.any` feature as not required, and assert in `mobile-builds` that the released manifest drops the audio and legacy storage permissions, per FR-012, FR-017, and FR-022 (contradicts)

Phase 20 validation (2026-09-10): the first convergence batch closed T124-T126, T130-T134, T142, T144, and
T145. Equipment provenance now names its source everywhere it is applied, the night-sky planner derives
and records the crop factor it actually consumes, the macro planner can apply a saved camera, the ND
notice follows one-off overrides, focus-stack and saved-plan warnings (including solar safety) reach the
user, validation messages are code-specific, and depth of field shows the depth on each side of focus.
Coverage: `test/widget/features/calculators/result_reporting_test.dart` plus additions to the saved
calculator and equipment widget suites; the depth-of-field golden was recaptured at 800x1400 so the whole
result card stays inside the frame. `flutter test` (219 passed), `flutter analyze --fatal-infos`, and
`dart format --set-exit-if-changed` are clean. The remaining Phase 20 tasks stay open, with T121 (Sun and
Moon events) and T122 (externally traceable fixtures) needing the most engineering.

Phase 20 validation, second batch (2026-09-10): T127-T129, T135, T136, T140, and T143 are closed. The
release manifest now removes the audio and legacy storage permissions the camera plugin merges in and
declares the merged camera feature as not required (T151 tracks asserting this on CI artifacts); the
planners disclose an unknown saved-location elevation and the AR reticle states its assumed field of view;
capability detection feeds both planners so the AR-unavailable path is reachable, and the numeric
alignment list states whether each candidate is above or below the horizon; the inventory offers Archive
for active equipment with the referenced-item warning. `validation/privacy.md` was rewritten and is true
at HEAD. Coverage: `test/widget/features/planning/planning_disclosure_test.dart`,
`test/unit/features/alignment/alignment_candidate_summary_test.dart`, and new equipment and service cases;
`flutter test` (224 passed), `flutter analyze --fatal-infos`, and `dart format` are clean.

Phase 20 validation, third batch (2026-09-10): T123, T137-T139, T141, and T146-T151 are closed.
`test/privacy/no_network_test.dart` now rejects a Dart HTTP client across the inventory, saved-plan reopen,
and both planners; `test/performance/release_budgets_test.dart` measures every released calculator;
`test/widget/features/calculators/text_scale_test.dart` drives all thirteen screens at 200% text scale with
semantics enabled; `test/fixtures/database/schema_v3.sql` covers the v3-to-v6 upgrade with its defaults;
`test/unit/features/expanded_calculators_reference_test.dart` carries cited formula fixtures with boundary
cases; `integration_test/optics_flows_test.dart` runs the field-of-view, diffraction, focus-stack, macro,
and panorama journeys offline; and the provenance-swap invalidation loop now covers a camera, an extension
tube, and an ND filter. The unused equipment override control, the unimplemented repository interface, the
claimable `bundled` source, and the misleading archived chip are gone, and `mobile-builds` now asserts the
merged release manifest drops the removed permissions and keeps `android.hardware.camera.any` optional.

Phase 20 validation, fourth batch (2026-09-10): T121 and T122 are closed, which completes every Phase 20
task; only the manual device and usability passes T058, T059, T061, and T062 remain open. The Sun and Moon
are now first-class night-sky targets backed by one shared `SolarLunarEphemeris` (extracted from the
alignment planner), so rise, transit, set, visibility cycles, and path sampling work for them exactly as
for the catalog targets, and selecting the Sun surfaces the certified-solar-filter guidance that is also
persisted in the snapshot. `test/unit/features/astronomy/solar_lunar_fixture_test.dart` asserts JPL
Horizons geocentric and topocentric Sun/Moon coordinates, the SIMBAD Sirius position, and USNO rise,
transit, and set tables within the declared tolerances, including circumpolar and never-rises boundaries
and the -0.8333 degree refraction-plus-semidiameter convention that explains the published solar times.
The 200% text-scale sweep also found and fixed a real defect: every dropdown now expands within its field,
so the macro configuration control no longer overflows on a narrow screen.

Post-completion audit (2026-09-10): an independent convergence pass over `c816578` found two regressions the
batch itself introduced, both fixed here. The equipment editor no longer crashes when it opens a row that
still carries the withdrawn `bundled` source, because the dropdown now offers the row's current value; and
the night-sky AR overlay passes `isSun` for the Sun target so the in-preview certified-solar-filter warning
is live again. The same pass asked for capability detection to be testable, so the raw platform
observations now map to `PlanningCapabilities` through a pure `planningCapabilitiesFrom` seam with unit
coverage of the available, permission-required, denied, and unsupported branches, and the AR-unavailable
cards name the specific missing capability instead of blaming the device. Warning wording moved into one
`calculationWarningText` map shared by live results and reopened saved plans, and warnings are now fed to
every result view rather than only optics and astronomy. Applied-camera snapshots are asserted for the
night-sky and macro planners, the alignment planner discloses that it does not apply lunar parallax, the
alignment-only ephemeris was renamed to `AlignmentSkyEphemeris` to avoid a duplicate class name, and the
quickstart, evidence record, and Android log were refreshed. `flutter test` is 272 passed, the analyzer and
formatter are clean, and all four host integration journeys pass.

T058/T061 progress (2026-09-10): the automated half of the quickstart journey is recorded scenario by
scenario in `validation/quickstart-evidence.md`, and seven host-runnable integration journeys now execute
it end to end — calculator flows, optics flows, equipment flow, planning flow, preferences and
saved-plan freezing, AR-unavailable fallback, and the 200% text-scale accessibility journey — for nine test
cases in total. The remaining work is genuinely device-bound: scenario 21 (live AR against real camera and
compass hardware), physical permission grants and denials, Android and iOS process death, and the T062
representative-photographer sessions. `validation/ios.md` records that no iOS evidence exists yet.

Post-audit hardening (2026-09-10): a third independent pass found persistence paths that could throw
unhandled or leak raw database errors, and the fixes are in place — equipment mutations report success
instead of throwing, every list/editor/saved-calculation/saved-location action recovers with an actionable
message, a device reading with no vertical fix no longer fabricates 0 m, a new saved location defaults to
the device's real UTC offset, and the location dialog validates its draft. Host verification at that point:
293 local tests, clean analyzer and formatter, and all seven integration journeys green three runs in a
row after `integration_test/support/journey.dart` pinned their viewport and settled every scroll before
tapping (the earlier flakiness was the varying host window size leaving controls unbuilt). Restart
instructions and test gotchas are recorded in `AGENT_HANDOFF.md`.

Convergence assessment (2026-09-11): a fourth pass found no missing requirements. Verified directly: every
one of the ten calculator and planner result views carries both a guidance line and persisted warnings
(FR-002's "explain its result and limitations"); both planners list location, local and UTC time, time zone
with confidence, north reference, elevation, horizon/refraction policy, source freshness, and expected
accuracy (FR-013); the catalog, planet positions, and moving-body events are all pinned to external
references; and the saved-location device path now reports the denied or unsupported capability state
before asking for a position (FR-017) instead of failing generically. The journey helpers are shared rather
than duplicated. Nothing new was appended because nothing remained unfixed.

Independent review (2026-09-11): a fifth pass over the app shell, preferences, and the most recently changed
files produced six findings, all closed. Two were in the duplicate-name pre-check added earlier: it ignored
archived rows (the unique index is partial, so a retired name must stay reusable) and normalized the typed
name differently from the domain, missing names that differ only by repeated spaces. One was a real
consistency gap: the length preference reached only three screens, so flash kept metres in its guide number
and range while both planners rendered elevations in metres (FR-020); all three now present through the
shared formatter and record the unit used. The remaining three removed dead code (the `core_domain.dart`
barrel and the `Sensitivity` and `CircleOfConfusion` value objects) and added the missing
unasked-but-grantable permission case. Verification at that point: 304 local tests, all eight host journeys,
and a Linux release build.

## Phase 21: Result-first interface redesign

The user rejected the delivered interface as "way too cluttered... wall of numbers everywhere": every
calculator was a long form followed by a result card that echoed its own inputs and listed every
intermediate value, assumption and checklist at the same visual weight as the answer.

The redesign keeps every requirement (FR-002 still renders units, assumptions, limitations, input summary
and a practical interpretation; FR-013 still renders the full planning context) but changes the
presentation: one hero answer carries the decision, two to four tiles carry the numbers a photographer
compares, and inputs, exact intermediates and assumptions move into collapsed sections. Secondary inputs
move behind "More settings"; no control, calculation, snapshot field or warning is removed.

- [x] T152 Add the result-first primitives (`CalculationResultView` hero/tiles/details, `CalculatorAdvancedSection`) and convert `depth_of_field_screen` as the reference
- [x] T153 Convert `exposure_comparison`, `long_exposure`, `flash_exposure` and `timelapse` to the hero/tiles/details shape
- [x] T154 Convert `macro`, the three optics tools, and `panorama` (collapsing the focus-distance list and the panorama frame grid)
- [x] T155 Convert `astronomy`, `alignment` (collapsing the candidate table and the sky-path samples) and give `saved_locations` scannable rows
- [x] T156 Update the widget, privacy and integration tests to assert the hero, the visible tiles and the expanded details, and re-pin the affected journeys
- [x] T157 Regenerate the host-rendered screenshots and verify the redesigned screens visually at phone width and at 200% text scale
- [x] T158 Extend the same presentation to the equipment, saved-calculation and settings screens

Redesign completed (2026-09-11) across two commits (`594b53f`, `74a3053`). Every calculator, planner and
saved plan now leads with its answer: a hero value with a plain-language caption, two-to-four comparison
tiles, and one Details expander holding the values used, the exact values and the model assumptions.
Secondary inputs sit behind "More settings". The focus-stack distance list, the panorama capture grid, the
alignment candidate table, the astronomy sky-path samples and the saved-plan provenance maps no longer
print at rest. Warnings stay visible above the hero everywhere. Equipment, saved-calculation list and
settings screens needed no change — their rows were already name-plus-provenance. Two defects surfaced and
were fixed on the way: the alignment `sampling` warning showed the diffraction sentence, and applying saved
equipment collapsed the open "More settings" section (the inserted notice shifted the expander's position,
so every section now carries a stable key). Verified at that point: clean analyzer and formatter, 286 local
tests, all eight host journeys, and a screenshot pass over every screen rendered from the real app at phone
width.

## Phase 22: Post-redesign convergence and recovery hardening

- [x] T159 Replace generic loading spinners with accessible skeletons shaped like each destination
- [x] T160 Keep saved-location drafts open and preserve device provenance when validation or persistence fails
- [x] T161 Report preference and favorite write failures without changing the visible stored state
- [x] T162 Keep saved-calculation edits and deletes recoverable after local database failures
- [x] T163 Remove missed-hit allowances and make scroll journeys tap complete interactive controls
- [x] T164 Serialize preference transforms so rapid settings and favorite actions cannot lose updates
- [x] T165 Release and recreate the live AR camera across app lifecycle interruptions

Convergence completed (2026-09-11) across `cc2c8a2`, `b62b3e8`, `739549f`, `c389eb0`, `5fcf480`,
`5defdd2`, and `d6fa5e7`. The audit rechecked all 24 functional requirements, 12 success criteria, seven
user stories, and the edge-case list. Automated coverage is complete for the repository-verifiable scope;
T058, T059, T061, and T062 remain device- or participant-bound. Verification at `d6fa5e7`: 337 local
tests, clean analyzer and formatter, and all eight host integration journeys green when run in isolated
processes.

## Phase 23: Release hardening

Dependency, CI and presentation maintenance on top of the completed feature set; no requirement changed.

- `timezone` 0.10.1 → 0.11.1. The 0.11 line makes `Location.offset` a `Duration` and moves the library's
  default location to `Etc/UTC`. The planner never relies on that default — it resolves `UTC`, fixed UTC
  offsets and named IANA zones explicitly — so the bump needed re-verification rather than a code change:
  `planning_time_context_test.dart` (both DST transitions, leap day, antimeridian, inclusive local-date
  ranges, unsupported identifiers) stays green, and the Linux release build still compiles.
- Workflow action majors refreshed to the Node 24 lines (`actions/checkout@v7`,
  `actions/upload-artifact@v7`, `actions/download-artifact@v8`); the input surface these workflows use is
  unchanged, and the merge exercised the publish jobs that only run on `v2` — both rolling prereleases
  were rebuilt afterwards.
- A Flutter 3.47.x trial on CI passed 335 of 337 tests and failed only the two committed goldens (0.02%
  and 0.01% pixel differences, i.e. toolchain font and antialiasing rasterization). The pin therefore
  stays at 3.44.x, and a future move must regenerate the goldens with the new SDK in the same change.
- The night-sky planning card printed its instant twice: once on the value line and again, verbatim, in
  front of the time-zone confidence note. That collapse is the default state, because `_timeZoneId`
  starts at `UTC` and a saved location with a zero or unresolvable offset renders `UTC` as well. The
  canonical instant is now printed only when the zone makes it different information, the confidence note
  is kept in every case (FR-013), and the result's input summary names a requested identifier only when it
  could not be resolved offline.

Verification: 339 local tests (three added: the duplication case, which fails against the previous card,
the night-sky plan's twelve FR-013 context rows, which nothing asserted before, and the alignment
planner's zone and confidence), clean analyzer and formatter, all eight host integration journeys green,
and a Linux release build.
