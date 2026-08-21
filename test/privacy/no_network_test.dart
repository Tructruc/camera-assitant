import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

void main() {
  testWidgets('primary journey never creates a Dart network client', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final previous = HttpOverrides.current;
    HttpOverrides.global = _RejectNetworkOverrides();
    addTearDown(() => HttpOverrides.global = previous);

    await tester.pumpWidget(
      ProviderScope(
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
      ),
    );
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
}

final class _RejectNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('network request attempted during offline journey');
  }
}
