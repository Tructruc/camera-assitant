import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';

/// The numeric planning view must stay scannable: only the best windows are
/// listed inline and the remainder is named by a count line that also points at
/// the collapsed table, so no match can be silently hidden.
void main() {
  AlignmentCandidate candidate(int index) => AlignmentCandidate(
    instantUtc: DateTime.utc(2026, 3, 20, 6 + index),
    azimuthDegrees: 170.0 + index,
    altitudeDegrees: 20.0 + index,
    angularErrorDegrees: 0.5 + index,
    aboveHorizon: true,
  );

  String format(AlignmentCandidate candidate) =>
      '2026-03-20 ${candidate.instantUtc.hour.toString().padLeft(2, '0')}:00';

  test('more windows than the preview limit add a count line', () {
    final candidates = [
      for (var index = 0; index < 8; index++) candidate(index),
    ];

    final lines = alignmentWindowLines(candidates, format);

    expect(lines, hasLength(numericWindowPreviewLimit + 1));
    expect(
      lines.take(numericWindowPreviewLimit),
      // Only the best three, in the calculator's own best-first order.
      [
        for (var index = 0; index < numericWindowPreviewLimit; index++)
          alignmentCandidateSummary(candidate(index), format(candidate(index))),
      ],
    );
    expect(
      lines.last,
      '3 of 8 windows shown · open Details for the full list.',
    );
  });

  test('exactly the preview limit adds no count line', () {
    final candidates = [
      for (var index = 0; index < numericWindowPreviewLimit; index++)
        candidate(index),
    ];

    final lines = alignmentWindowLines(candidates, format);

    expect(lines, hasLength(numericWindowPreviewLimit));
    expect(lines.every((line) => line.contains('— az ')), isTrue);
  });

  test('fewer windows and no windows list every match and no count', () {
    expect(alignmentWindowLines([candidate(0)], format), hasLength(1));
    expect(alignmentWindowLines(const [], format), isEmpty);
  });
}
