import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/settings/presentation/settings_screen.dart';

void main() {
  late AppDatabase database;
  late PreferencesRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = PreferencesRepository(database);
  });
  tearDown(() => database.close());

  testWidgets('persists display and field-theme choices locally', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metric (m and mm)'), findsOneWidget);
    expect(find.textContaining('Canonical calculation values'), findsOneWidget);
    await tester.tap(find.text('Imperial (ft and in)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Conventional shutter'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Conventional shutter'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Magnetic north'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Magnetic north'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Low-light red'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low-light red'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('no account, advertising, or telemetry'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('no account, advertising, or telemetry'),
      findsOneWidget,
    );

    final saved = await repository.load();
    expect(saved.lengthDisplay, LengthDisplay.imperial);
    expect(saved.shutterDisplay, ShutterDisplay.conventional);
    expect(saved.themeMode, AppThemeMode.lowLight);
    expect(saved.northReference, NorthReference.magneticNorth);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
