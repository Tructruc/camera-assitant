# Camera Assistant Architecture Remodeling Plan

This document turns the architecture review into a step-by-step remodeling plan. The goal is not to rewrite the app. The goal is to move the codebase gradually from a prototype-shaped Flutter app into a maintainable feature-based architecture.

The current project already has a useful foundation:

- pure calculator classes under `lib/domain/calculators`,
- domain and widget tests,
- shared UI widgets,
- a simple app/data/domain/screens folder split.

The main issue is that screens have become the application layer. Large widgets currently own UI, form state, validation, persistence access, calculation orchestration, formatting, dialogs, and navigation. This plan separates those responsibilities incrementally.

## Target Architecture

The end state should look roughly like this:

```text
lib/
  app/
    app.dart
    app_dependencies.dart
    app_theme.dart
    routes.dart
    tools/
      tool_catalog.dart

  core/
    formatting/
    parsing/
    units/
    validation/

  domain/
    optics/
      calculators/
      models/
    planning/
      calculators/
      models/

  data/
    database/
      app_database.dart
      migrations.dart
    lenses/
      lens_dao.dart
      lens_mapper.dart
      lens_repository.dart
      sqlite_lens_repository.dart
    settings/
      settings_repository.dart
      sqlite_settings_repository.dart
    backup/
      lens_library_transfer.dart

  features/
    home/
    settings/
    lenses/
    dof/
      dof_screen.dart
      dof_controller.dart
      dof_state.dart
      dof_use_case.dart
      widgets/
    macro/
    focus_stacking/
    panorama/
    astro/
    exposure/
    long_exposure/
    sun_planner/

  shared/
    widgets/
    lenses/
    sensors/
```

The dependency direction should be:

```text
Flutter widgets
  -> controllers / view models
    -> use cases / app services
      -> domain calculators
      -> repositories
        -> data sources / SQLite
```

## Remodeling Principles

Use these rules throughout the refactor:

1. Keep the app working after every step.
2. Move one responsibility at a time.
3. Start with low-risk centralization before touching complex feature screens.
4. Preserve the existing calculator tests.
5. Add tests around extracted behavior before deleting old logic.
6. Avoid redesigning UI while remodeling architecture.
7. Prefer wrappers around current code before splitting internals deeply.

## Phase 1: Centralize Tool Metadata

### Problem

Tool metadata is duplicated in the home screen and settings screen. IDs, labels, subtitles, icons, and builders are not defined in one place.

### Goal

Create one source of truth for app tools.

### Steps

1. Create:

```text
lib/app/tools/tool_definition.dart
lib/app/tools/tool_catalog.dart
```

2. Add a `ToolDefinition` model:

```dart
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}
```

3. Move the tool list from `HomeScreen` into `ToolCatalog`.

4. Make `HomeScreen` read from `ToolCatalog`.

5. Make `SettingsScreen` read from the same catalog for home organization.

6. Keep `AppSettings.defaultHomeToolOrder` aligned with the catalog IDs.

### Acceptance Criteria

- Tool titles and subtitles exist in only one place.
- Home screen still renders all tools.
- Settings organizer still sees all tools.
- Existing widget tests still pass.

## Phase 2: Extract App Theme

### Problem

`app.dart` currently owns app bootstrapping, settings loading, dependency access, and theme construction.

### Goal

Move theme construction out of the app root.

### Steps

1. Create:

```text
lib/app/app_theme.dart
```

2. Move `_buildTheme` from `CameraAssistantApp` into a dedicated class or function:

```dart
class AppTheme {
  static ThemeData build({required bool isDark}) {
    ...
  }
}
```

3. Update `CameraAssistantApp` to use:

```dart
theme: AppTheme.build(isDark: false),
darkTheme: AppTheme.build(isDark: true),
```

### Acceptance Criteria

- `app.dart` is smaller.
- Theme behavior is unchanged.
- `flutter analyze` passes.

## Phase 3: Introduce Repository Interfaces

### Problem

Screens depend directly on `LensDatabase.instance`, which couples Flutter widgets to SQLite.

### Goal

Introduce repository interfaces without changing database internals yet.

### Steps

1. Create:

```text
lib/data/lenses/lens_repository.dart
lib/data/settings/settings_repository.dart
```

2. Define repository interfaces:

```dart
abstract class LensRepository {
  Future<List<Lens>> getLenses();
  Future<Lens> insertLens(Lens lens);
  Future<void> updateLens(Lens lens);
  Future<void> deleteLens(int id);
  Future<String> exportLensLibrary();
  Future<int> importLensLibrary(String raw, {bool replaceExisting});
}
```

```dart
abstract class SettingsRepository {
  Future<AppSettings> getAppSettings();
  Future<void> saveAppSettings(AppSettings settings);
}
```

3. Create adapter implementations that wrap the current `LensDatabase`:

```text
lib/data/lenses/sqlite_lens_repository.dart
lib/data/settings/sqlite_settings_repository.dart
```

4. Do not split `LensDatabase` yet. Treat it as the legacy data source behind repository adapters.

### Acceptance Criteria

- Repository interfaces exist.
- SQLite repository adapters delegate to the existing database class.
- No feature behavior changes yet.
- Tests and analyzer pass.

## Phase 4: Add App-Level Dependency Injection

### Problem

The database singleton is pulled directly from app and screen classes.

### Goal

Provide dependencies from the app root.

### Steps

1. Create:

```text
lib/app/app_dependencies.dart
```

2. Add:

```dart
class AppDependencies {
  const AppDependencies({
    required this.lenses,
    required this.settings,
  });

  final LensRepository lenses;
  final SettingsRepository settings;
}
```

3. Add an `InheritedWidget` or use an existing dependency-injection/state-management package if the project chooses one later.

4. Initialize dependencies once in `main` or `CameraAssistantApp`.

5. Replace direct `LensDatabase.instance` use in `app.dart` with `SettingsRepository`.

### Acceptance Criteria

- `CameraAssistantApp` loads settings through `SettingsRepository`.
- The database singleton is no longer referenced directly from `app.dart`.
- Dependency access has one clear pattern.

## Phase 5: Move Lens Access Out Of Feature Screens

### Problem

Calculator screens repeatedly load saved lenses and handle selected lens state.

### Goal

Create reusable lens-selection application logic.

### Steps

1. Create:

```text
lib/shared/lenses/lens_selection_state.dart
lib/shared/lenses/lens_selection_controller.dart
```

2. Move common behavior into the controller:

- load lenses,
- keep selected lens ID,
- clear selected lens,
- resolve selected lens,
- clamp focal length to lens range,
- get minimum aperture at selected focal length.

3. Replace duplicate lens-loading logic in one feature first, preferably DOF.

4. After DOF is stable, reuse the controller in:

- macro,
- focus stacking,
- panorama,
- astro.

### Acceptance Criteria

- DOF no longer directly loads lenses from the database.
- Common lens-selection rules are tested once.
- Other features can adopt the same controller gradually.

## Phase 6: Refactor DOF As The Reference Feature

### Problem

`DofCalculatorScreen` mixes UI, form state, validation, lens access, calculation, and navigation.

### Goal

Use DOF as the template for future feature refactors.

### Steps

1. Create a feature folder:

```text
lib/features/dof/
  dof_screen.dart
  dof_state.dart
  dof_controller.dart
  dof_use_case.dart
  widgets/
    dof_input_form.dart
    dof_result_panel.dart
```

2. Define `DofState`:

```dart
class DofState {
  const DofState({
    required this.availableLenses,
    required this.selectedLensId,
    required this.selectedSensor,
    required this.focalLengthText,
    required this.apertureText,
    required this.subjectDistanceText,
    required this.errorMessage,
    required this.result,
  });
}
```

3. Define `DofInput` as a typed request object:

```dart
class DofInput {
  const DofInput({
    required this.focalLengthMm,
    required this.aperture,
    required this.subjectDistanceM,
    required this.sensor,
    this.lens,
  });
}
```

4. Move validation from the widget into `DofUseCase`.

5. Keep `DOFCalculator` pure and unchanged.

6. Move rendering into smaller widgets:

- input form,
- lens selector area,
- sensor selector,
- result metrics,
- action buttons.

7. Keep route behavior compatible with the old screen.

### Acceptance Criteria

- DOF screen behavior is unchanged.
- DOF validation can be tested without widget tests.
- `DofCalculatorScreen` is either replaced or reduced to a thin compatibility wrapper.
- The new DOF feature becomes the pattern for other calculators.

## Phase 7: Extract Shared Parsing, Formatting, And Units

### Problem

Screens parse numeric fields and format values in slightly different ways.

### Goal

Centralize common input and output behavior.

### Steps

1. Create:

```text
lib/core/parsing/
lib/core/formatting/
lib/core/units/
```

2. Move existing formatting helpers from `shared/utils/formatters.dart` into the appropriate core folder.

3. Add common parse result objects if needed:

```dart
sealed class ParseResult<T> {
  const ParseResult();
}

class ParseSuccess<T> extends ParseResult<T> {
  const ParseSuccess(this.value);
  final T value;
}

class ParseFailure<T> extends ParseResult<T> {
  const ParseFailure(this.message);
  final String message;
}
```

4. Replace ad hoc parse checks in feature controllers gradually.

### Acceptance Criteria

- Parsing behavior is consistent across features.
- Formatting helpers are not duplicated inside screens.
- Calculator screens become easier to read.

## Phase 8: Move Domain Models Away From Storage Mapping

### Problem

`Lens` includes `fromMap` and `toMap`, which know SQLite column names. That couples the domain model to the database schema.

### Goal

Move storage mapping into the data layer.

### Steps

1. Create:

```text
lib/data/lenses/lens_mapper.dart
```

2. Move `Lens.fromMap` logic into:

```dart
class LensMapper {
  static Lens fromRow(Map<String, Object?> row) { ... }
  static Map<String, Object?> toRow(Lens lens) { ... }
}
```

3. Update database/repository code to use `LensMapper`.

4. Keep temporary compatibility methods on `Lens` only if needed during migration.

5. Once all data code uses `LensMapper`, remove `fromMap` and `toMap` from the domain model.

6. Move display labels into presentation formatters later:

```text
lib/features/lenses/lens_display_formatter.dart
```

### Acceptance Criteria

- SQLite column names are isolated in the data layer.
- Domain models no longer need to know storage field names.
- Lens model tests are updated to target either domain behavior or mapper behavior separately.

## Phase 9: Split `LensDatabase`

### Problem

`LensDatabase` owns connection setup, migrations, lens CRUD, import/export, and settings persistence.

### Goal

Split database infrastructure from data operations.

### Steps

1. Create:

```text
lib/data/database/app_database.dart
lib/data/database/migrations.dart
```

2. Move database opening and platform-independent connection logic into `AppDatabase`.

3. Move schema creation and upgrade logic into `migrations.dart`.

4. Create:

```text
lib/data/lenses/lens_dao.dart
lib/data/settings/settings_dao.dart
```

5. Move raw SQL/table access into DAOs.

6. Keep repositories as the public API for the rest of the app.

7. Move `lens_library_transfer.dart` to:

```text
lib/data/backup/lens_library_transfer.dart
```

### Acceptance Criteria

- No screen imports `sqflite`.
- No screen imports database internals.
- Repositories are the only data dependency used by controllers/features.
- Database migration tests can be added around `AppDatabase`.

## Phase 10: Centralize Routing

### Problem

Navigation is scattered across screens through direct `Navigator.of(context).push(...)` calls.

### Goal

Create one place for routes and page construction.

### Steps

1. Create:

```text
lib/app/routes.dart
```

2. Define route names:

```dart
class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const lenses = '/lenses';
  static const dof = '/tools/dof';
}
```

3. Move shared tool scaffold behavior into route/page construction.

4. Replace direct pushes from home/settings with named route helpers.

5. Decide later whether to keep Flutter's built-in `Navigator` or introduce `go_router`.

### Acceptance Criteria

- Home tool navigation goes through one route mechanism.
- Settings/lens manager navigation is no longer hand-built in multiple places.
- Tool routes are easier to test and inspect.

## Phase 11: Refactor Remaining Feature Screens

### Problem

Macro, focus stacking, astro, panorama, exposure, long exposure, and sun planner still follow the old large-screen pattern.

### Goal

Apply the DOF feature pattern gradually.

### Suggested Order

1. Panorama
2. Astro
3. Macro
4. Focus stacking
5. Exposure
6. Long exposure
7. Sun planner
8. Settings
9. Lenses

### Per-Feature Steps

For each feature:

1. Create a `features/<name>` folder.
2. Add state, controller, use case, and screen files.
3. Move validation into the use case.
4. Move form behavior into the controller.
5. Keep calculators pure.
6. Split result rendering into widgets.
7. Add controller tests.
8. Keep or update widget tests for the main user flow.

### Acceptance Criteria

- Each feature screen is mostly presentation.
- Each feature has testable application logic.
- No feature widget directly accesses SQLite.
- Large files shrink into focused modules.

## Phase 12: Improve Settings Architecture

### Problem

Settings are persisted as key-value strings with JSON-encoded lists, and settings UI contains complex home-organization behavior.

### Goal

Separate settings persistence, settings state, and settings UI.

### Steps

1. Keep `AppSettings` as the domain/app settings model.

2. Create a settings controller:

```text
lib/features/settings/settings_controller.dart
lib/features/settings/settings_state.dart
```

3. Move home organization logic into:

```text
lib/features/settings/home_organization/
```

4. Consider changing persistence to a single JSON settings blob behind `SettingsRepository`:

```text
settings
  id INTEGER PRIMARY KEY CHECK (id = 1)
  json TEXT NOT NULL
```

5. Keep repository API stable so the UI does not care how settings are stored.

### Acceptance Criteria

- Settings screen no longer directly owns all organizer behavior.
- Settings persistence can change without touching settings UI.
- Home organization logic has focused tests.

## Phase 13: Improve Lens Manager Architecture

### Problem

The lens manager screen owns list display, CRUD, import/export, dialogs, editor form state, validation, and clipboard behavior.

### Goal

Split lens management into list, editor, import/export, and controller logic.

### Steps

1. Create:

```text
lib/features/lenses/
  lens_manager_screen.dart
  lens_manager_controller.dart
  lens_manager_state.dart
  lens_editor/
    lens_editor_screen.dart
    lens_editor_controller.dart
    lens_editor_state.dart
  transfer/
    lens_import_dialog.dart
    lens_export_dialog.dart
```

2. Move CRUD operations into `LensManagerController`.

3. Move editor validation into `LensEditorController`.

4. Keep clipboard behavior at the presentation boundary, but keep transfer encoding/decoding in data backup code.

### Acceptance Criteria

- Lens editor validation can be tested without widget tests.
- Lens manager list behavior can be tested with a fake repository.
- Import/export remains compatible with existing backup JSON.

## Phase 14: Update Tests To Match The New Architecture

### Goal

Add tests at the correct layer instead of relying mainly on widget tests.

### Test Types

#### Domain Tests

Keep and expand calculator tests:

```text
test/domain/calculators/
```

These should verify formulas and edge cases.

#### Mapper Tests

Add tests for data mappers:

```text
test/data/lenses/lens_mapper_test.dart
```

These should verify SQLite rows map correctly to domain objects and back.

#### Repository Tests

Add tests for repositories:

```text
test/data/lenses/sqlite_lens_repository_test.dart
test/data/settings/sqlite_settings_repository_test.dart
```

These can use SQLite FFI or fake databases.

#### Controller Tests

Add tests for feature behavior:

```text
test/features/dof/dof_controller_test.dart
test/features/lenses/lens_editor_controller_test.dart
```

These should verify validation and state transitions without rendering widgets.

#### Widget Tests

Keep widget tests for UI flows:

- home tool rendering,
- settings organizer,
- lens editor screen,
- representative calculator flows.

### Acceptance Criteria

- Business validation is tested outside widgets.
- Widget tests focus on rendering and interaction.
- Every refactored feature has controller or use-case coverage.

## Phase 15: Cleanup And Enforce Boundaries

### Goal

Prevent the old architecture from slowly returning.

### Steps

1. Search for forbidden dependencies:

```text
screens/features -> sqflite
screens/features -> LensDatabase
domain -> data
domain -> Flutter
```

2. Remove old compatibility wrappers after migrated features no longer need them.

3. Add README architecture notes.

4. Consider adding import-lint rules later if the project grows.

5. Keep files small enough that each file has one clear reason to change.

### Acceptance Criteria

- Domain code imports no Flutter or data-layer code.
- Feature controllers depend on repositories, not SQLite.
- Widgets do not contain major business validation.
- Tool metadata is centralized.
- App dependencies are explicit.

## Suggested Commit Plan

Use small commits so each architectural change is easy to review:

1. `Add shared tool catalog`
2. `Extract app theme`
3. `Introduce repository interfaces`
4. `Add app dependency container`
5. `Extract lens selection controller`
6. `Refactor DOF feature architecture`
7. `Move shared parsing and formatting helpers`
8. `Move lens storage mapping to data layer`
9. `Split database infrastructure and DAOs`
10. `Centralize app routes`
11. `Refactor panorama feature architecture`
12. `Refactor astro feature architecture`
13. `Refactor macro feature architecture`
14. `Refactor focus stacking feature architecture`
15. `Refactor settings and lens manager architecture`

## Done Definition

The remodeling is successful when:

- calculators remain pure and well tested,
- screens mostly render state,
- controllers handle user intent and form state,
- use cases coordinate validation and calculations,
- repositories hide persistence,
- data mappers hide storage schema details,
- routing and tool metadata are centralized,
- new features have an obvious place to live,
- changing a formula, UI layout, database schema, or route does not require editing the same large file.

The project does not need enterprise complexity. It needs a modest application layer, explicit dependencies, and feature boundaries. Those changes will make the app easier to test, easier to extend, and less risky to modify.
