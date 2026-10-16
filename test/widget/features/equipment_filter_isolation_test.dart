import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody;
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart'
    as domain;
import 'package:photography_assistant/features/equipment/presentation/equipment_controller.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_list_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';

/// The inventory's Kit kind filter, and its Include archived toggle, describe
/// the *inventory*. Neither may reach into a calculator: the kept-alive shell
/// holds one equipment controller for the whole session, so once the Kit shelf
/// is parked on one category a picker that read the filtered list would silently
/// lose the rest of the kit — including the saved lens or ND filter a
/// photographer already applied to a calculation.
void main() {
  late AppDatabase database;
  late DriftEquipmentRepository repository;

  final timestamp = DateTime.utc(2026, 8, 19);

  const provenance = domain.EquipmentProvenance(
    source: domain.EquipmentSource.user,
  );

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftEquipmentRepository(database, now: () => timestamp);
  });

  tearDown(() => database.close());

  Future<void> seedKit() async {
    await repository.createLens(
      domain.Lens(
        id: 'lens-saved',
        name: 'Saved 85 mm',
        minimumFocalLengthMm: 85,
        maximumFocalLengthMm: 85,
        minimumAperture: 1.8,
        provenance: provenance,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await repository.createCamera(
      domain.CameraBody(
        id: 'camera-saved',
        name: 'Saved Camera',
        sensorWidthMm: 36,
        sensorHeightMm: 24,
        provenance: provenance,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await repository.createFilter(
      domain.NdFilter(
        id: 'filter-active',
        name: 'ND 6-Stop',
        strengthStops: 6,
        filterFactor: 64,
        provenance: provenance,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  /// One ProviderScope for every screen in the tree, exactly as the shell gives
  /// them: the controller is shared, so a filter set by the inventory is still
  /// in place when a calculator is looked at.
  ///
  /// Each screen is a page body, and the shell gives it a [Scaffold]; the
  /// harness does the same, because a calculator's chip rail needs the Material
  /// ancestor a Scaffold provides.
  Widget app({required Widget child, Key? key, double textScale = 1}) =>
      ProviderScope(
        key: key,
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          equipmentRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: child),
          ),
        ),
      );

  /// A stand-in for the shell's destination stack (an [IndexedStack], see
  /// `lib/app/app.dart`): the calculator and the Kit inventory are both
  /// mounted, exactly as a visited destination is kept alive, and
  /// [showCalculator] picks which one the photographer is looking at. The one
  /// [ProviderScope] is the shell's container, so what the inventory filters
  /// the calculator still sees.
  Widget shell({required bool showCalculator}) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      equipmentRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(),
        child: Scaffold(
          body: IndexedStack(
            sizing: StackFit.expand,
            index: showCalculator ? 0 : 1,
            children: const <Widget>[
              DepthOfFieldScreen(),
              EquipmentListScreen(),
            ],
          ),
        ),
      ),
    ),
  );

  ProviderContainer sharedContainer() {
    final container = ProviderContainer(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        equipmentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    // The kept-alive shell holds the controller for the whole session. Keeping
    // that listener open is what stops Riverpod from scheduling an auto-dispose
    // the way a mounted screen would, so the test never leaves a timer behind.
    container.listen(equipmentControllerProvider, (_, _) {});
    // Backstop only: the owning test disposes the container through [finish]
    // while the fake clock can still be advanced, and a second dispose is a
    // no-op.
    addTearDown(container.dispose);
    return container;
  }

  /// Ends a test while the fake clock can still move.
  ///
  /// Unmounting the scope is what disposes the database's query streams, and
  /// Drift schedules that cleanup with `Timer.run` — a zero-duration timer.
  /// Left to the framework's own post-test unmount, the timer is still pending
  /// when the framework asserts ("A Timer is still pending even after the
  /// widget tree was disposed"), and `database.close()` waits on the same
  /// completers: the tear-down would then await a timer the fake clock never
  /// fires and the test hangs until the runner's ten-minute timeout. Unmounting
  /// here and advancing the clock by one millisecond drains it.
  Future<void> finish(
    WidgetTester tester, {
    ProviderContainer? container,
  }) async {
    container?.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// The optional-equipment field whose label is [label].
  Finder pickerFor(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField,
    ),
  );

  /// Brings [label]'s field clear of the viewport edge and taps it open.
  ///
  /// `ensureVisible` aligns the field's top edge with the top of the viewport,
  /// but a [DropdownButtonFormField] paints its floating label across that
  /// edge: the label's centre can sit a few pixels above the viewport, where a
  /// tap on it silently misses. Nudge the form down so the whole field is
  /// inside the viewport, then tap the field itself — its button spans the
  /// decorator, so the tap lands even where the label is clipped.
  Future<void> openPicker(WidgetTester tester, String label) async {
    final field = pickerFor(label);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    final top = tester.getTopLeft(field).dy;
    if (top < 24) {
      final position = Scrollable.maybeOf(tester.element(field))?.position;
      if (position != null) {
        position.jumpTo(
          (position.pixels - (24 - top)).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(field);
    await tester.pumpAndSettle();
  }

  /// Opens the optional equipment picker [label] and returns every string its
  /// menu actually offers — the user-visible list, so a missing item is caught
  /// the way a photographer would notice it.
  Future<Set<String>> offeredByPicker(WidgetTester tester, String label) async {
    // scrollUntilVisible only walks one way, so start from the top of the form:
    // a picker above the current position would otherwise never be reached.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(label),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await openPicker(tester, label);
    final offered = <String>{
      for (final text in tester.widgetList<Text>(find.byType(Text)))
        if (text.data != null && text.data != label) text.data!,
    };
    // Close the menu the way a tap outside does, so a caller can open another.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    return offered;
  }

  testWidgets(
    'a persisted Kit kind filter leaves the shared controller filtered for '
    'the inventory only',
    (tester) async {
      await seedKit();
      final container = sharedContainer();
      final controller = container.read(equipmentControllerProvider.notifier);
      await controller.load();

      expect(
        container.read(equipmentControllerProvider).allItems,
        hasLength(3),
      );
      expect(
        container.read(equipmentControllerProvider).activeItems,
        hasLength(3),
      );

      await controller.setKind(EquipmentKind.camera);
      final filtered = container.read(equipmentControllerProvider);

      // The inventory's own question stays filtered: Kit > Cameras shows
      // cameras, and its truthful count is still the whole shelf.
      expect(filtered.items.map((entry) => entry.kind).toSet(), <EquipmentKind>{
        EquipmentKind.camera,
      });
      expect(filtered.allItems, hasLength(3));
      expect(filtered.activeItems, hasLength(3));
      expect(
        filtered.activeItems
            .where((entry) => entry.kind == EquipmentKind.lens)
            .map((entry) => entry.item.name),
        contains('Saved 85 mm'),
      );
      expect(
        filtered.activeItems
            .where((entry) => entry.kind == EquipmentKind.filter)
            .map((entry) => entry.item.name),
        contains('ND 6-Stop'),
      );

      await finish(tester, container: container);
    },
  );

  testWidgets(
    'DOF keeps its saved lens and camera while the Kit shelf sits on another '
    'category',
    (tester) async {
      await seedKit();
      // The shell keeps visited screens alive; the calculator stays mounted
      // behind the inventory, watching the same controller the inventory
      // filtered.
      await tester.pumpWidget(shell(showCalculator: true));
      await tester.pumpAndSettle();

      expect(
        await offeredByPicker(tester, 'Saved lens (optional)'),
        contains('Saved 85 mm'),
      );
      await openPicker(tester, 'Saved lens (optional)');
      await tester.tap(find.text('Saved 85 mm').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('From Saved 85 mm'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dof-focal')))
            .controller!
            .text,
        '85.0',
      );
      await openPicker(tester, 'Saved camera (optional)');
      await tester.tap(find.text('Saved Camera').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('From Saved Camera'), findsOneWidget);

      // The photographer parks the inventory on Kit > Cameras. The calculator
      // is still mounted behind it, so the applied snapshots survive the
      // switch and the lens is still offered.
      await tester.pumpWidget(shell(showCalculator: false));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Cameras (1)'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(shell(showCalculator: true));
      await tester.pumpAndSettle();

      // The calculator is a lazy list and keeps the scroll position it had when
      // the inventory took over (the camera picker was the last thing opened).
      // Scroll back to the top, the way the photographer would to read the
      // applied values, so the pickers and their notices are built and on
      // screen for the assertions below.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
      await tester.pumpAndSettle();

      expect(find.text('Saved lens (optional)'), findsOneWidget);
      expect(find.text('Saved camera (optional)'), findsOneWidget);
      expect(find.textContaining('From Saved 85 mm'), findsOneWidget);
      expect(find.textContaining('From Saved Camera'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dof-focal')))
            .controller!
            .text,
        '85.0',
      );
      expect(
        await offeredByPicker(tester, 'Saved lens (optional)'),
        contains('Saved 85 mm'),
      );

      await finish(tester);
    },
  );

  testWidgets('ND filter picker survives a Kit shelf parked on lenses', (
    tester,
  ) async {
    await seedKit();
    final container = sharedContainer();
    final controller = container.read(equipmentControllerProvider.notifier);
    await controller.load();
    await controller.setKind(EquipmentKind.lens);

    await tester.pumpWidget(
      app(child: const LongExposureScreen(), key: const ValueKey('nd-picker')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved ND filter (optional)'), findsOneWidget);
    expect(
      await offeredByPicker(tester, 'Saved ND filter (optional)'),
      contains('ND 6-Stop'),
    );

    await finish(tester, container: container);
  });

  testWidgets(
    'an archived item leaves the pickers even while the inventory is showing '
    'archived entries',
    (tester) async {
      await seedKit();
      await repository.createFilter(
        domain.NdFilter(
          id: 'filter-retired',
          name: 'ND 3-Stop',
          strengthStops: 3,
          filterFactor: 8,
          provenance: provenance,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
      await repository.archiveFilter('filter-retired');

      await tester.pumpWidget(
        app(
          child: const LongExposureScreen(),
          key: const ValueKey('archived-nd'),
        ),
      );
      await tester.pumpAndSettle();

      // The retired filter is already out of the picker while the active one is
      // still offered, so the assertion below is about the archive rather than
      // about the seed.
      var offered = await offeredByPicker(tester, 'Saved ND filter (optional)');
      expect(offered, isNot(contains('ND 3-Stop')));
      expect(offered, contains('ND 6-Stop'));

      // Turning archived entries on is a housekeeping view. The archived filter
      // becomes visible in the inventory's list, and stays out of the picker.
      await tester.pumpWidget(
        app(
          child: const EquipmentListScreen(),
          key: const ValueKey<String>('include-archived'),
        ),
      );
      await tester.pumpAndSettle();
      final archivedChip = find.widgetWithText(FilterChip, 'Include archived');
      await tester.ensureVisible(archivedChip);
      await tester.pumpAndSettle();
      await tester.tap(archivedChip);
      await tester.pumpAndSettle();
      expect(find.text('ND 3-Stop'), findsOneWidget);

      await tester.pumpWidget(
        app(
          child: const LongExposureScreen(),
          key: const ValueKey<String>('nd-after-toggle'),
        ),
      );
      await tester.pumpAndSettle();

      offered = await offeredByPicker(tester, 'Saved ND filter (optional)');
      expect(offered, isNot(contains('ND 3-Stop')));
      expect(offered, contains('ND 6-Stop'));

      await finish(tester);
    },
  );

  testWidgets('the duplicate-name check is not restricted to the Kit kind '
      'filter', (tester) async {
    await repository.createCamera(
      domain.CameraBody(
        id: 'camera-taken',
        name: 'Field Camera',
        sensorWidthMm: 36,
        sensorHeightMm: 24,
        provenance: provenance,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    await tester.pumpWidget(
      app(child: const EquipmentListScreen(), key: const ValueKey('dup-check')),
    );
    await tester.pumpAndSettle();

    // Kit is parked on Lenses, so the filtered inventory no longer shows the
    // camera whose name is about to be reused.
    await tester.tap(find.widgetWithText(FilterChip, 'Lenses (0)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add camera'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Camera name'),
      'field camera',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor width (mm)'),
      '36',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor height (mm)'),
      '24',
    );
    await tester.scrollUntilVisible(
      find.text('Save camera'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save camera'));
    await tester.pumpAndSettle();

    // The clash is named on the field: the check reads the active inventory,
    // not the category the shelf happens to be showing.
    expect(
      find.text('Another active item already uses this name.'),
      findsOneWidget,
    );
    // Nothing was written, so the generic failure was never reached.
    expect(await repository.listCameras(), hasLength(1));
    expect(find.text('Camera name'), findsOneWidget);

    await finish(tester);
  });
}
