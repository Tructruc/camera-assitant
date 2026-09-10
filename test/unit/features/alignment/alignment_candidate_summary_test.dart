import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';

void main() {
  AlignmentCandidate candidate({required bool aboveHorizon}) =>
      AlignmentCandidate(
        instantUtc: DateTime.utc(2026, 3, 20, 12),
        azimuthDegrees: 180.04,
        altitudeDegrees: 38.9,
        angularErrorDegrees: 0.04,
        aboveHorizon: aboveHorizon,
      );

  test('numeric candidate summary states horizon visibility', () {
    final above = alignmentCandidateSummary(
      candidate(aboveHorizon: true),
      '2026-03-20 12:00',
    );
    expect(above, contains('2026-03-20 12:00'));
    expect(above, contains('az 180.0°'));
    expect(above, contains('alt 38.9°'));
    expect(above, contains('error 0.04°'));
    expect(above, endsWith('above horizon'));

    final below = alignmentCandidateSummary(
      candidate(aboveHorizon: false),
      '2026-03-20 03:00',
    );
    expect(below, endsWith('below horizon'));
    expect(below, isNot(contains('above horizon')));
  });
}
