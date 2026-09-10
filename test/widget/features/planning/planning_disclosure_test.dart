import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide SavedLocation;
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/planning/domain/planning_capabilities.dart';
import 'package:photography_assistant/features/planning/domain/saved_location.dart';

/// Covers the Phase 20 planning disclosures: honest elevation fallbacks,
/// horizon state in the numeric alignment list, and detected AR capability.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  final siteWithoutElevation = SavedLocation(
    id: 'loc-sea-level',
    name: 'Sea level site',
    latitudeDegrees: 51.4779,
    longitudeDegrees: 0,
    timeZoneId: 'Europe/London',
    source: LocationSource.manual,
    createdAt: DateTime.utc(2026, 9, 10),
    updatedAt: DateTime.utc(2026, 9, 10),
  );

  Widget app(
    Widget child, {
    List<SavedLocation> locations = const <SavedLocation>[],
    List<Override> overrides = const <Override>[],
  }) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      savedLocationsProvider.overrideWith(
        (ref) => Stream<List<SavedLocation>>.value(locations),
      ),
      ...overrides,
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 300,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> selectSiteWithoutElevation(WidgetTester tester) async {
    final picker = find.text('Saved location (optional)');
    await reveal(tester, picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sea level site').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'night-sky planner discloses a saved location without elevation',
    (tester) async {
      await tester.pumpWidget(
        app(const AstronomyScreen(), locations: [siteWithoutElevation]),
      );
      await tester.pumpAndSettle();
      await selectSiteWithoutElevation(tester);

      final note = find.textContaining('has no elevation');
      await reveal(tester, note);
      expect(note, findsOneWidget);
      expect(find.textContaining('Verify it before relying'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'alignment planner discloses a saved location without elevation',
    (tester) async {
      await tester.pumpWidget(
        app(const AlignmentScreen(), locations: [siteWithoutElevation]),
      );
      await tester.pumpAndSettle();
      await selectSiteWithoutElevation(tester);

      final note = find.textContaining('has no elevation');
      await reveal(tester, note);
      expect(note, findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('the AR view respects detected device capabilities', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const AstronomyScreen(),
        overrides: <Override>[
          planningCapabilitiesProvider.overrideWith(
            (ref) async => const PlanningCapabilities.fallback(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final calculate = find.widgetWithText(FilledButton, 'Plan night sky');
    await reveal(tester, calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    final ar = find.text('AR');
    await reveal(tester, ar);
    await tester.tap(ar);
    await tester.pumpAndSettle();

    expect(find.textContaining('AR unavailable'), findsOneWidget);
    expect(find.textContaining('remain usable'), findsOneWidget);
    await unmount(tester);
  });
}
