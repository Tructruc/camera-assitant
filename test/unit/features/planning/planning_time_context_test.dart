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

  test('retains UTC and identifies unsupported IANA conversion', () {
    final context = PlanningTimeContext.parse('Europe/Paris');
    expect(context.canConvertOffline, isFalse);
    expect(context.format(DateTime.utc(2026, 8, 21, 20, 30)), contains('UTC'));
    expect(context.confidenceLabel, contains('unavailable'));
  });
}
