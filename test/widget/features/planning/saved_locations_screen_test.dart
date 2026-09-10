import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/features/planning/data/device_planning_service.dart';
import 'package:photography_assistant/features/planning/data/saved_location_repository.dart';
import 'package:photography_assistant/features/planning/domain/saved_location.dart';
import 'package:photography_assistant/features/planning/presentation/saved_locations_screen.dart';

/// Substitutes the two device paths the widget test cannot exercise.
final class _FakePlanningService extends DevicePlanningService {
  _FakePlanningService({this.reading, this.failure});

  final DeviceLocationReading? reading;
  final Object? failure;

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
    expect(find.textContaining('45.00000, 5.00000'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Dark site'));
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
}
