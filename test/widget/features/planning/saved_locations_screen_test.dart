import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/features/planning/presentation/saved_locations_screen.dart';

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
}
