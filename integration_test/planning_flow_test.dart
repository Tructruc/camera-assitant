import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'support/journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Milky Way plan survives closing and reopening its on-device database',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'camera-planning-',
      );
      final file = File('${directory.path}/planning.sqlite');
      var database = AppDatabase(NativeDatabase(file));
      addTearDown(() async {
        configureJourneyView(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await database.close();
        await directory.delete(recursive: true);
      });

      Widget app() => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const PhotographyAssistantApp(),
      );

      Future<void> reveal(String text) async {
        await tester.scrollUntilVisible(
          find.text(text),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await reveal('Night-sky planner');
      await tester.tap(find.text('Night-sky planner'));
      await tester.pumpAndSettle();
      await reveal('Plan night sky');
      await tester.tap(find.text('Plan night sky'));
      await tester.pumpAndSettle();
      // The orientation row lives in the result card's collapsed Details.
      await openSection(tester, 'Details');
      await reveal('Milky Way orientation');
      expect(find.textContaining('relative to horizon'), findsOneWidget);
      await reveal('Save result');
      final save = find.widgetWithText(FilledButton, 'Save result');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      final original = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      expect(
        original.canonicalOutputs['milkyWayOrientationDegrees'],
        inInclusiveRange(0, 180),
      );
      expect(
        original.displayContext['milkyWayOrientationConvention'],
        AstronomyCalculator.milkyWayOrientationConvention,
      );

      configureJourneyView(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      final reopened = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      expect(reopened.toJson(), original.toJson());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milky Way core night-sky plan'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('milkyWayOrientationDegrees:'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('milkyWayOrientationDegrees:'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
