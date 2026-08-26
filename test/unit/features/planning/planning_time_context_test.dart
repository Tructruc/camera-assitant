import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/domain/planning_time_context.dart';

void main() {
  test('formats UTC and fixed offsets without network data', () {
    final instant = DateTime.utc(2026, 8, 21, 20, 30);
    expect(
      PlanningTimeContext.parse('UTC+02:00').format(instant),
      '2026-08-21 22:30 UTC+02:00',
    );
    expect(
      PlanningTimeContext.parse('UTC-0530').format(instant),
      '2026-08-21 15:00 UTC-0530',
    );
  });

  test('applies bundled IANA daylight-saving rules offline', () {
    final context = PlanningTimeContext.parse('Europe/Paris');
    expect(context.canConvertOffline, isTrue);
    expect(
      context.format(DateTime.utc(2026, 1, 21, 20, 30)),
      '2026-01-21 21:30 Europe/Paris',
    );
    expect(
      context.format(DateTime.utc(2026, 8, 21, 20, 30)),
      '2026-08-21 22:30 Europe/Paris',
    );
    expect(context.confidenceLabel, contains('daylight-saving'));
  });

  test('converts local civil fields through IANA daylight-saving rules', () {
    final context = PlanningTimeContext.parse('Europe/Paris');
    expect(
      context.toUtc(DateTime(2026, 1, 21, 21, 30)),
      DateTime.utc(2026, 1, 21, 20, 30),
    );
    expect(
      context.toUtc(DateTime(2026, 8, 21, 22, 30)),
      DateTime.utc(2026, 8, 21, 20, 30),
    );
    expect(
      context.localCivilTime(DateTime.utc(2026, 8, 21, 20, 30)),
      DateTime(2026, 8, 21, 22, 30),
    );
  });

  test('converts local civil fields with fixed offsets offline', () {
    final context = PlanningTimeContext.parse('UTC-0530');
    expect(
      context.toUtc(DateTime(2026, 8, 21, 15)),
      DateTime.utc(2026, 8, 21, 20, 30),
    );
    expect(
      context.localCivilTime(DateTime.utc(2026, 8, 21, 20, 30)),
      DateTime(2026, 8, 21, 15),
    );
  });

  test('retains UTC and identifies unknown timezone identifiers', () {
    final context = PlanningTimeContext.parse('Mars/Olympus');
    expect(context.canConvertOffline, isFalse);
    expect(context.format(DateTime.utc(2026, 8, 21, 20, 30)), contains('UTC'));
    expect(context.confidenceLabel, contains('unsupported'));
  });
}
