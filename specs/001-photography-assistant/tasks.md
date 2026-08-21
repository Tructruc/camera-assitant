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
