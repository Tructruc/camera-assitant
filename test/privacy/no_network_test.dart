import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

import '../fixtures/equipment_fixtures.dart';

void main() {
  Widget app(AppDatabase database) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      preferencesProvider.overrideWith(
        (ref) => Stream<AppPreferences>.value(const AppPreferences()),
      ),
      equipmentRepositoryProvider.overrideWithValue(
        DriftEquipmentRepository(database),
      ),
    ],
    child: const PhotographyAssistantApp(),
  );

  void rejectNetwork(WidgetTester tester) {
    final previous = HttpOverrides.current;
    HttpOverrides.global = _RejectNetworkOverrides();
    addTearDown(() => HttpOverrides.global = previous);
  }

  /// Opens the result's collapsed details so the exact values are built.
  Future<void> openDetails(WidgetTester tester, {double delta = 300}) async {
    final details = find.text('Details');
    await tester.scrollUntilVisible(
      details,
      delta,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(details.first);
    await tester.pumpAndSettle();
    await tester.tap(details.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('primary journey never creates a Dart network client', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    rejectNetwork(tester);

    await tester.pumpWidget(app(database));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Depth of field'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Depth of field'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    expect(find.text('Near limit'), findsOneWidget);
    expect(find.textContaining('network request attempted'), findsNothing);
  });

  testWidgets('inventory and saved plans never create a Dart network client', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    rejectNetwork(tester);
    await DriftEquipmentRepository(
      database,
    ).createCamera(fullFrameCameraFixture());
    await DriftSnapshotRepository(database).save(
      CalculationSnapshot(
        id: 'offline-snapshot',
        calculatorId: 'depth_of_field',
        formulaVersion: 1,
        createdAt: DateTime.utc(2026, 9, 10),
        title: 'Offline result',
        canonicalInputs: const <String, Object?>{'focalLengthMm': 50.0},
        canonicalOutputs: const <String, Object?>{'nearLimitMm': 4500.0},
        displayContext: const <String, Object?>{'distanceUnit': 'metric'},
      ),
    );

    await tester.pumpWidget(app(database));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Equipment').last);
    await tester.pumpAndSettle();
    expect(find.text('Full Frame Camera'), findsOneWidget);

    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offline result'));
    await tester.pumpAndSettle();
    expect(find.text('Original inputs'), findsOneWidget);

    expect(find.textContaining('network request attempted'), findsNothing);
    // Let Riverpod dispose the local database streams while the fake clock can
    // still drain Drift's cleanup timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('both planners never create a Dart network client', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    rejectNetwork(tester);

    await tester.pumpWidget(app(database));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sun & Moon alignment'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sun & Moon alignment'));
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('alignment-search'));
    await tester.scrollUntilVisible(
      search,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Best window'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Best window'), findsOneWidget);
    // The collapsed details still carry the search grid, and opening them must
    // not reach for the network either.
    await openDetails(tester);
    await tester.scrollUntilVisible(
      find.text('Search resolution'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Search resolution'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Night-sky planner'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Night-sky planner'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Plan night sky'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plan night sky'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // The full result is still rendered: the hero answer is visible and the
    // details section can be opened without any network client being created.
    expect(find.text('Save result'), findsOneWidget);
    await openDetails(tester, delta: -300);
    expect(find.text('Values used'), findsOneWidget);

    expect(find.textContaining('network request attempted'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

final class _RejectNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('network request attempted during offline journey');
  }
}
