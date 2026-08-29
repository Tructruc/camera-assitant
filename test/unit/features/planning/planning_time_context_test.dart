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

  test('converts inclusive local date ranges across daylight saving', () {
    final context = PlanningTimeContext.parse('Europe/Paris');
    final springRange = context.inclusiveLocalDateRange(
      startDate: DateTime(2026, 3, 28),
      endDate: DateTime(2026, 3, 29),
    );

    expect(springRange.startUtc, DateTime.utc(2026, 3, 27, 23));
    expect(
      springRange.endUtc.add(const Duration(microseconds: 1)),
      DateTime.utc(2026, 3, 29, 22),
    );
    expect(
      springRange.endUtc.difference(springRange.startUtc),
      lessThan(const Duration(days: 2)),
    );

    final autumnRange = context.inclusiveLocalDateRange(
      startDate: DateTime(2026, 10, 24),
      endDate: DateTime(2026, 10, 25),
    );
    expect(autumnRange.startUtc, DateTime.utc(2026, 10, 23, 22));
    expect(
      autumnRange.endUtc.add(const Duration(microseconds: 1)),
      DateTime.utc(2026, 10, 25, 23),
    );
    expect(
      autumnRange.endUtc.difference(autumnRange.startUtc),
      greaterThan(const Duration(days: 2)),
    );
  });

  test('rejects reversed and longer-than-one-year local date ranges', () {
    final context = PlanningTimeContext.parse('UTC');

    expect(
      () => context.inclusiveLocalDateRange(
        startDate: DateTime(2026, 2),
        endDate: DateTime(2026, 1),
      ),
      throwsArgumentError,
    );
    expect(
      () => context.inclusiveLocalDateRange(
        startDate: DateTime(2026),
        endDate: DateTime(2027, 1, 2),
      ),
      throwsArgumentError,
    );
  });

  test('retains UTC and identifies unknown timezone identifiers', () {
    final context = PlanningTimeContext.parse('Mars/Olympus');
    expect(context.canConvertOffline, isFalse);
    expect(context.format(DateTime.utc(2026, 8, 21, 20, 30)), contains('UTC'));
    expect(context.confidenceLabel, contains('unsupported'));
  });
}
