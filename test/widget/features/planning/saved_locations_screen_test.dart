import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide SavedLocation;
import 'package:photography_assistant/features/planning/data/device_planning_service.dart';
import 'package:photography_assistant/features/planning/data/saved_location_repository.dart';
import 'package:photography_assistant/features/planning/domain/planning_capabilities.dart';
import 'package:photography_assistant/features/planning/domain/saved_location.dart';
import 'package:photography_assistant/features/planning/presentation/saved_locations_screen.dart';

/// Substitutes the two device paths the widget test cannot exercise.
final class _FakePlanningService extends DevicePlanningService {
  _FakePlanningService({
    this.reading,
    this.failure,
    this.status = CapabilityStatus.available,
  });

  final DeviceLocationReading? reading;
  final Object? failure;
  final CapabilityStatus status;

  @override
  Future<CapabilityStatus> locationStatus() async => status;

  @override
  Future<DeviceLocationReading> requestCurrentLocation() async {
    if (failure case final error?) throw error;
    return reading!;
  }
}

void main() {
  testWidgets('manually creates and deletes an offline saved location', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No saved locations yet. Add coordinates manually or request the current position.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Dark site');
    await tester.enterText(fields.at(1), '45');
    await tester.enterText(fields.at(2), '5');
    await tester.enterText(fields.at(3), '1200');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Dark site'), findsOneWidget);
    expect(find.textContaining('45.00°N, 5.00°E'), findsOneWidget);
    // Deleting is now a deliberate step behind the row's overflow menu.
    await tester.tap(find.byTooltip('Actions for Dark site'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Dark site'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('the device location prefills and saves a device-sourced site', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          devicePlanningServiceProvider.overrideWithValue(
            _FakePlanningService(
              reading: const DeviceLocationReading(
                latitude: 51.4779,
                longitude: 0,
                elevationMetres: 46,
                accuracyMetres: 8,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(
      tester.widget<TextField>(fields.at(0)).controller!.text,
      'Current location',
    );
    expect(tester.widget<TextField>(fields.at(1)).controller!.text, '51.4779');
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, '0.0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Current location'), findsWidgets);
    final stored = await SavedLocationRepository(database).listAll();
    expect(stored.single.source, LocationSource.device);
    expect(stored.single.latitudeDegrees, 51.4779);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a failing device lookup explains the manual fallback', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          devicePlanningServiceProvider.overrideWithValue(
            _FakePlanningService(
              failure: StateError('Location services are disabled.'),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Current location is unavailable'),
      findsOneWidget,
    );
    expect(find.textContaining('add the coordinates manually'), findsOneWidget);
    // The raw platform exception must not be shown to the user.
    expect(
      find.textContaining('Location services are disabled.'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('an unasked permission still opens the dialog', (tester) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          devicePlanningServiceProvider.overrideWithValue(
            _FakePlanningService(
              status: CapabilityStatus.permissionRequired,
              reading: const DeviceLocationReading(
                latitude: 51.4779,
                longitude: 0,
                accuracyMetres: 8,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use current location'));
    await tester.pumpAndSettle();
    // The status only says the permission has not been granted yet, so the
    // request proceeds and the dialog prefills.
    expect(find.text('Add saved location'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Latitude'))
          .controller!
          .text,
      '51.4779',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('invalid coordinates are rejected inline, not by exception', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Bad site');
    await tester.enterText(fields.at(1), '91');
    await tester.enterText(fields.at(2), 'not a number');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Latitude must be between -90 and 90.'), findsOneWidget);
    expect(find.text('Enter a number.'), findsOneWidget);
    expect(find.text('Bad site'), findsOneWidget); // still in the dialog
    expect(await SavedLocationRepository(database).listAll(), isEmpty);

    // Correcting the values saves without leaving the dialog open.
    await tester.enterText(fields.at(1), '45');
    await tester.enterText(fields.at(2), '5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(await SavedLocationRepository(database).listAll(), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a duplicate name is named in the dialog', (tester) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = SavedLocationRepository(database);
    final now = DateTime.utc(2026, 9, 10);
    await repository.save(
      SavedLocation(
        id: 'existing',
        name: 'Dark site',
        latitudeDegrees: 45,
        longitudeDegrees: 5,
        timeZoneId: 'UTC',
        source: LocationSource.manual,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'dark site');
    await tester.enterText(fields.at(1), '10');
    await tester.enterText(fields.at(2), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('A saved location with this name exists.'),
      findsOneWidget,
    );
    expect(await repository.listAll(), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'a missing altitude stays blank and a failed delete is reported',
    (tester) async {
      final database = AppDatabase.inMemory();
      addTearDown(database.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            savedLocationRepositoryProvider.overrideWithValue(
              _FailingDeleteSavedLocationRepository(database),
            ),
            devicePlanningServiceProvider.overrideWithValue(
              _FakePlanningService(
                reading: const DeviceLocationReading(
                  latitude: 51.4779,
                  longitude: 0,
                  accuracyMetres: 8,
                  // No vertical fix: the platform would report 0 here.
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SavedLocationsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use current location'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      // The elevation must not be fabricated as 0 m.
      expect(tester.widget<TextField>(fields.at(3)).controller!.text, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // The delete path fails, and says so instead of throwing.
      await tester.tap(find.byTooltip('Actions for Current location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be deleted'), findsOneWidget);
      expect(find.text('Current location'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('a failed duplicate check keeps the location draft open', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          savedLocationRepositoryProvider.overrideWithValue(
            _FailingListSavedLocationRepository(database),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Unsent dark site');
    await tester.enterText(fields.at(1), '45');
    await tester.enterText(fields.at(2), '5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Saved locations could not be checked. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Add saved location'), findsOneWidget);
    expect(
      tester.widget<TextField>(fields.at(0)).controller!.text,
      'Unsent dark site',
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a failed save keeps the location values available to retry', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          savedLocationRepositoryProvider.overrideWithValue(
            _FailingSaveSavedLocationRepository(database),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Retry dark site');
    await tester.enterText(fields.at(1), '45');
    await tester.enterText(fields.at(2), '5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Your values are still here'), findsOneWidget);
    expect(find.text('Add saved location'), findsOneWidget);
    expect(
      tester.widget<TextField>(fields.at(0)).controller!.text,
      'Retry dark site',
    );
    expect(await SavedLocationRepository(database).listAll(), isEmpty);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('editing a device location preserves its source and accuracy', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = SavedLocationRepository(database);
    await repository.save(
      SavedLocation(
        id: 'device-site',
        name: 'Device site',
        latitudeDegrees: 45,
        longitudeDegrees: 5,
        timeZoneId: 'Europe/Paris',
        source: LocationSource.device,
        accuracyMetres: 8,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: Scaffold(body: SavedLocationsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Device site'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Edited device site');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final stored = (await repository.listAll()).single;
    expect(stored.name, 'Edited device site');
    expect(stored.source, LocationSource.device);
    expect(stored.accuracyMetres, 8);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a denied or absent location service explains the fallback', (
    tester,
  ) async {
    for (final (status, expected, fallback)
        in <(CapabilityStatus, String, String)>[
          (
            CapabilityStatus.denied,
            'Location permission is denied for this app',
            'Enable it in system settings, or add the coordinates manually.',
          ),
          (
            CapabilityStatus.unsupported,
            'Location services are unavailable on this device',
            'Add the coordinates manually.',
          ),
        ]) {
      // Closed inside the loop: drift warns when two in-memory databases are
      // alive at once, and each iteration needs its own instance.
      final database = AppDatabase.inMemory();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            devicePlanningServiceProvider.overrideWithValue(
              _FakePlanningService(status: status),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SavedLocationsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use current location'));
      await tester.pumpAndSettle();
      expect(find.textContaining(expected), findsOneWidget);
      expect(find.textContaining(fallback), findsOneWidget);
      // Nothing is prefilled, because no location could be read.
      expect(find.text('Add saved location'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
    }
  });

  testWidgets('a populated location list stays usable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = SavedLocationRepository(database);
    final now = DateTime.utc(2026, 9, 24);
    for (var index = 0; index < 4; index++) {
      await repository.save(
        SavedLocation(
          id: 'location-scale-$index',
          name: 'Dark sky reserve with a long name $index',
          latitudeDegrees: 45.0 + index,
          longitudeDegrees: 5,
          timeZoneId: 'Europe/London',
          elevationMetres: 1200,
          source: LocationSource.manual,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: SavedLocationsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The create action stays reachable at 2x text while the list is at rest.
    expect(find.text('Add location'), findsWidgets);

    // Every stored site stays reachable at 2x text: a location the photographer
    // cannot scroll to is one they cannot plan from, and the row that proves it
    // is the last one, not the first.
    final last = find.text('Dark sky reserve with a long name 3');
    await tester.scrollUntilVisible(
      last,
      300,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.pumpAndSettle();
    expect(last, findsOneWidget);
    expect(tester.takeException(), isNull);

    // drift's query streams schedule a zero-duration timer when the last
    // subscription is cancelled, so the tree has to be disposed and that timer
    // given a frame before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

/// Fails deletes, standing in for a locked or full database.
final class _FailingDeleteSavedLocationRepository
    extends SavedLocationRepository {
  _FailingDeleteSavedLocationRepository(super.database);

  @override
  Future<void> delete(String id) async => throw StateError('write failed');
}

final class _FailingListSavedLocationRepository
    extends SavedLocationRepository {
  _FailingListSavedLocationRepository(super.database);

  @override
  Future<List<SavedLocation>> listAll() async =>
      throw StateError('read failed');
}

final class _FailingSaveSavedLocationRepository
    extends SavedLocationRepository {
  _FailingSaveSavedLocationRepository(super.database);

  @override
  Future<void> save(SavedLocation location) async =>
      throw StateError('write failed');
}
