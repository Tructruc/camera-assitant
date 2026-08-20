import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

void main() {
  testWidgets('interactive launch and large-inventory scrolling meet budgets', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 8, 21).millisecondsSinceEpoch;
    await database.batch((batch) {
      for (var index = 0; index < 1000; index++) {
        batch.customStatement(
          '''INSERT INTO camera_bodies
             (id, name, normalized_name, sensor_width_mm, sensor_height_mm,
              source_type, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
          <Object>[
            'scroll-camera-$index',
            'Camera ${index.toString().padLeft(4, '0')}',
            'camera ${index.toString().padLeft(4, '0')}',
            36.0,
            24.0,
            'user',
            now,
            now,
          ],
        );
      }
    });

    final launch = Stopwatch()..start();
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
    launch.stop();
    expect(find.text('Choose a calculator'), findsOneWidget);
    expect(launch.elapsedMilliseconds, lessThan(2000));

    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    expect(find.text('Camera 0000'), findsOneWidget);
    final samples = <int>[];
    for (var index = 0; index < 20; index++) {
      final watch = Stopwatch()..start();
      await tester.drag(find.byType(ListView).last, const Offset(0, -240));
      await tester.pump();
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
    }
    samples.sort();
    final p95Microseconds = samples[(samples.length * 0.95).floor()];
    expect(p95Microseconds, lessThan(100000));
    // ignore: avoid_print
    print('interactive_launch_ms=${launch.elapsedMilliseconds}');
    // ignore: avoid_print
    print('inventory_scroll_step_p95_us=$p95Microseconds');
  });
}
