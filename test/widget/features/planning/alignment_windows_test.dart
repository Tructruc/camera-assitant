import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, SavedLocation;
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';

/// Wiring check for the numeric planning view: the inline list is capped at
/// [numericWindowPreviewLimit] and the hidden remainder is both counted and
/// present in the result card's collapsed candidate table.
void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Future<void> search(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          // A wide tolerance keeps a real search from returning nothing.
          preferencesProvider.overrideWith(
            (ref) => Stream<AppPreferences>.value(
              const AppPreferences(defaultAlignmentToleranceDegrees: 180),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AlignmentScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final searchButton = find.byKey(const Key('alignment-search'));
    await tester.scrollUntilVisible(
      searchButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(searchButton);
    await tester.pumpAndSettle();
  }

  testWidgets('the inline window list is capped and the total stays visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await search(tester);

    // The full candidate table lives in the collapsed Details section.
    await tester.scrollUntilVisible(
      find.text('Details'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    final tableRows = find.textContaining(RegExp(r'^az \d'));
    final total = tableRows.evaluate().length;
    expect(total, greaterThan(0), reason: 'the search found no windows');

    await tester.scrollUntilVisible(
      find.text('Numeric'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Numeric'));
    await tester.pumpAndSettle();

    final summaries = find.textContaining('— az ');
    final shown = summaries.evaluate().length;
    expect(shown, lessThanOrEqualTo(numericWindowPreviewLimit));

    final countLine = find.textContaining('windows shown');
    if (total > numericWindowPreviewLimit) {
      expect(shown, numericWindowPreviewLimit);
      expect(
        countLine,
        findsOneWidget,
        reason: 'hidden matches must be counted',
      );
      expect(find.textContaining('3 of $total windows shown'), findsOneWidget);
    } else {
      expect(shown, total, reason: 'every match fits inline');
      expect(countLine, findsNothing);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
