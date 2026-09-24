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
      find.text('Strict'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Strict'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('5°'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('5°'));
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
    expect(saved.defaultStarSharpness, DefaultStarSharpness.strict);
    expect(saved.defaultAlignmentToleranceDegrees, 5);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a failed setting write is reported and remains unchanged', (
    tester,
  ) async {
    final failingRepository = _FailingPreferencesRepository(database);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          preferencesRepositoryProvider.overrideWithValue(failingRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Imperial (ft and in)'));
    await tester.pumpAndSettle();

    expect(find.text('Setting could not be saved.'), findsOneWidget);
    expect((await repository.load()).lengthDisplay, LengthDisplay.metric);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('every setting stays reachable at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: SettingsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('.+')), findsAtLeastNWidgets(2));

    // The last choice and the privacy statement are still reachable when the
    // type is twice as large: nothing is dropped to make the list fit.
    final lastChoice = find.text('Low-light red');
    await tester.scrollUntilVisible(
      lastChoice,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(lastChoice, findsOneWidget);

    final privacy = find.textContaining(
      'no account, advertising, or telemetry',
    );
    await tester.scrollUntilVisible(
      privacy,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(privacy, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    semantics.dispose();
  });
}

final class _FailingPreferencesRepository extends PreferencesRepository {
  _FailingPreferencesRepository(super.database);

  @override
  Future<AppPreferences> update(
    AppPreferences Function(AppPreferences current) transform,
  ) async => throw StateError('write failed');
}
