import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart'
    as domain;
import 'package:photography_assistant/features/equipment/presentation/equipment_controller.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_editor_screen.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_list_screen.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_picker.dart';
import 'package:photography_assistant/features/saved_calculations/presentation/saved_calculations_screen.dart';
import 'package:photography_assistant/features/settings/presentation/settings_screen.dart';

/// The library surfaces: a kit that reads like an inventory, a saved workspace
/// that can be searched, and settings whose choices fit on one line each.
///
/// The finders below avoid words the user has typed into a field, because
/// `find.text` also matches the text inside an editable control.
void main() {
  late AppDatabase database;
  late DriftEquipmentRepository equipment;
  late DriftSnapshotRepository snapshots;
  late PreferencesRepository preferences;
  final timestamp = DateTime.utc(2026, 8, 20);

  setUp(() {
    database = AppDatabase.inMemory();
    equipment = DriftEquipmentRepository(database);
    snapshots = DriftSnapshotRepository(database);
    preferences = PreferencesRepository(database);
  });
  tearDown(() => database.close());

  Widget host(Widget child) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      equipmentRepositoryProvider.overrideWithValue(equipment),
      snapshotRepositoryProvider.overrideWithValue(snapshots),
      preferencesRepositoryProvider.overrideWithValue(preferences),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );

  /// A screen that watches a database stream keeps a zero-duration timer
  /// pending when the last subscription is cancelled, so the tree is unmounted
  /// (and the timer flushed) before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  domain.CameraBody camera(String id, String name) => domain.CameraBody(
    id: id,
    name: name,
    sensorWidthMm: 36,
    sensorHeightMm: 24,
    provenance: const domain.EquipmentProvenance(
      source: domain.EquipmentSource.user,
    ),
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  domain.Lens lens(String id, String name) => domain.Lens(
    id: id,
    name: name,
    minimumFocalLengthMm: 24,
    maximumFocalLengthMm: 70,
    minimumAperture: 2.8,
    provenance: const domain.EquipmentProvenance(
      source: domain.EquipmentSource.user,
    ),
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  Future<void> savePlan({
    required String id,
    required String calculatorId,
    required String title,
    String? notes,
    int day = 20,
  }) => snapshots.save(
    CalculationSnapshot(
      id: id,
      calculatorId: calculatorId,
      formulaVersion: 1,
      createdAt: DateTime.utc(2026, 8, day),
      title: title,
      notes: notes,
      canonicalInputs: const <String, Object?>{'focalLengthMm': 50.0},
      canonicalOutputs: const <String, Object?>{'nearLimitMm': 4500.0},
      displayContext: const <String, Object?>{'distanceUnit': 'metric'},
    ),
  );

  testWidgets('the kit counts each category and summarizes what it holds', (
    tester,
  ) async {
    await equipment.createCamera(camera('camera-1', 'Field Camera'));
    await equipment.createLens(lens('lens-1', 'Zoom Lens'));

    await tester.pumpWidget(host(const EquipmentListScreen()));
    await tester.pumpAndSettle();

    // Every category carries the number of items it would show.
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Cameras (1)'), findsOneWidget);
    expect(find.text('Lenses (1)'), findsOneWidget);
    expect(find.text('ND filters (0)'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);

    // A recognizable specification, not just a name and a source.
    expect(find.textContaining('Full frame'), findsOneWidget);
    expect(find.textContaining('f/2.8'), findsOneWidget);

    // The edit action is labelled on the row instead of hidden in the menu.
    expect(find.text('Edit'), findsNWidgets(2));
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit camera'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Sensor width (mm)'),
          )
          .controller!
          .text,
      '36.0',
    );
    await unmount(tester);
  });

  testWidgets('a category filter narrows the shelf without claiming it is '
      'empty', (tester) async {
    await equipment.createCamera(camera('camera-1', 'Field Camera'));
    await equipment.createLens(lens('lens-1', 'Zoom Lens'));

    await tester.pumpWidget(host(const EquipmentListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lenses (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Field Camera'), findsNothing);
    expect(find.text('Zoom Lens'), findsOneWidget);

    // A category with nothing in it says so, and offers the way back, instead
    // of claiming the whole shelf is empty.
    await tester.ensureVisible(find.text('ND filters (0)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ND filters (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing in ND filters'), findsOneWidget);
    expect(find.text('No equipment yet'), findsNothing);

    await tester.tap(find.text('Show all equipment'));
    await tester.pumpAndSettle();
    expect(find.text('Field Camera'), findsOneWidget);
    expect(find.text('Zoom Lens'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a standard format preset fills both sensor dimensions', (
    tester,
  ) async {
    domain.EquipmentItem? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: EquipmentEditorScreen(
          kind: EquipmentKind.camera,
          onSave: (item) async => saved = item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Full frame'));
    await tester.pumpAndSettle();

    String valueOf(String label) => tester
        .widget<TextFormField>(find.widgetWithText(TextFormField, label))
        .controller!
        .text;
    expect(valueOf('Sensor width (mm)'), '36');
    expect(valueOf('Sensor height (mm)'), '24');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Camera name'),
      'Preset Camera',
    );
    // Let the text field's own scroll-into-view settle before scrolling to the
    // disclosure: a pending reveal would move it out of the viewport again.
    await tester.pumpAndSettle();
    // The rare model assumption is one deliberate disclosure away, and its
    // value still saves exactly.
    await tester.scrollUntilVisible(
      find.text('Advanced'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // The disclosure only taps reliably once it is fully inside the viewport:
    // a partly clipped tile swallows the tap.
    await tester.ensureVisible(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Default circle of confusion (mm)'),
      '0.03',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save camera'));
    await tester.pumpAndSettle();

    expect(saved, isA<domain.CameraBody>());
    final body = saved! as domain.CameraBody;
    expect(body.name, 'Preset Camera');
    expect(body.sensorWidthMm, 36);
    expect(body.sensorHeightMm, 24);
    expect(body.defaultCircleOfConfusionMm, 0.03);
    await unmount(tester);
  });

  testWidgets('an ND strength preset writes the raw stops value', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: EquipmentEditorScreen(
          kind: EquipmentKind.filter,
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, '10 stops'));
    await tester.pumpAndSettle();

    final stops = tester
        .widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Filter strength (stops)'),
        )
        .controller!
        .text;
    expect(stops, '10');
    await unmount(tester);
  });

  testWidgets('an optional picker with nothing to pick takes no row', (
    tester,
  ) async {
    const label = 'Saved camera (optional)';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EquipmentPicker<domain.CameraBody>(
            label: label,
            items: const <domain.CameraBody>[],
            itemLabel: (item) => item.name,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(label), findsNothing);

    domain.CameraBody? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EquipmentPicker<domain.CameraBody>(
            label: label,
            items: <domain.CameraBody>[camera('camera-1', 'Field Camera')],
            itemLabel: (item) => item.name,
            onSelected: (item) => selected = item,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(label), findsOneWidget);

    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Field Camera').last);
    await tester.pumpAndSettle();
    expect(selected?.id, 'camera-1');
    await unmount(tester);
  });

  testWidgets('the saved workspace searches titles, notes and tools', (
    tester,
  ) async {
    await savePlan(
      id: 'plan-dof',
      calculatorId: 'depth_of_field',
      title: 'Field depth',
      notes: 'Tripod and cable release',
    );
    await savePlan(
      id: 'plan-timelapse',
      calculatorId: 'timelapse',
      title: 'Sunset timelapse',
      day: 22,
    );

    await tester.pumpWidget(host(const SavedCalculationsScreen()));
    await tester.pumpAndSettle();

    // Two tools are stored, so the visible tool filter lists both.
    expect(find.text('Depth of field (1)'), findsOneWidget);
    expect(find.text('Timelapse planner (1)'), findsOneWidget);
    expect(find.text('Field depth'), findsOneWidget);
    expect(find.text('Sunset timelapse'), findsOneWidget);

    // A tool filter narrows to that tool alone.
    await tester.tap(find.text('Timelapse planner (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Field depth'), findsNothing);
    expect(find.text('Sunset timelapse'), findsOneWidget);

    // Releasing the filter, then searching a note, finds the other plan by
    // the words the photographer wrote for it.
    await tester.tap(find.text('All tools'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search saved results'),
      'tripod',
    );
    await tester.pumpAndSettle();
    expect(find.text('Field depth'), findsOneWidget);
    expect(find.text('Sunset timelapse'), findsNothing);

    // A query that matches nothing explains itself and can be cleared.
    await tester.enterText(
      find.widgetWithText(TextField, 'Search saved results'),
      'zzqq',
    );
    await tester.pumpAndSettle();
    expect(find.text('No saved results match this search'), findsOneWidget);
    await tester.tap(find.text('Clear search and filters'));
    await tester.pumpAndSettle();
    expect(find.text('Field depth'), findsOneWidget);
    expect(find.text('Sunset timelapse'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('settings choices are chips that persist the same preference', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          preferencesRepositoryProvider.overrideWithValue(preferences),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metric (m and mm)'), findsOneWidget);
    expect(find.text('Imperial (ft and in)'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, 'Metric (m and mm)'),
          )
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Imperial (ft and in)'));
    await tester.pumpAndSettle();

    expect((await preferences.load()).lengthDisplay, LengthDisplay.imperial);
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, 'Imperial (ft and in)'),
          )
          .selected,
      isTrue,
    );
    await unmount(tester);
  });
}
