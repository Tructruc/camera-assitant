import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates, restarts, archives, and restores equipment offline', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftEquipmentRepository(database);

    Widget app() => ProviderScope(
      overrides: <Override>[
        preferencesProvider.overrideWith(
          (ref) => Stream<AppPreferences>.value(const AppPreferences()),
        ),
        equipmentRepositoryProvider.overrideWithValue(repository),
      ],
      child: const PhotographyAssistantApp(),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add camera'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Camera name'),
      'Integration Camera',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor width (mm)'),
      '36',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor height (mm)'),
      '24',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Source note'),
      'Offline integration test',
    );
    await tester.tap(find.text('Save camera'));
    await tester.pumpAndSettle();

    expect(find.text('Integration Camera'), findsOneWidget);
    expect(find.text('Offline integration test'), findsOneWidget);

    // Rebuild the whole provider tree against the same on-device store.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsOneWidget);

    await tester.tap(find.byTooltip('Actions for Integration Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsNothing);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsOneWidget);
    expect(find.text('Archived'), findsWidgets);

    await tester.tap(find.byTooltip('Actions for Integration Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore').last);
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsOneWidget);
  });
}
