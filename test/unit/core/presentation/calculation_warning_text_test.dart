import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/presentation/calculator/calculation_warning_text.dart';

void main() {
  // Every code a calculator can persist into a snapshot warning list. Keeping
  // the list here means a new code cannot silently reach users as the generic
  // fallback sentence.
  const persistedCodes = <String>[
    'aperture_outside_typical_range',
    'close_focus',
    'configuration_estimate',
    'distortion',
    'exposure_exceeds_interval',
    'frame_limit',
    'greater_than_near',
    'milkyWayOrientationUndefined',
    'not_beyond_focal_length',
    'planningAccuracy',
    'positive_finite_required',
    'power_range',
    'range',
    'sampling',
    'sampling_visible',
    'solarSafety',
  ];

  test('every persisted warning code has specific wording', () {
    for (final code in persistedCodes) {
      final text = calculationWarningText(code);
      expect(text, isNotEmpty, reason: '$code must render');
      expect(
        text,
        isNot(contains('reported a limitation')),
        reason: '$code fell through to the generic sentence',
      );
      if (code.contains('_')) {
        // Underscored identifiers are internal; single-word codes such as
        // "range" or "sampling" can legitimately appear in prose.
        expect(
          text,
          isNot(contains(code)),
          reason: '$code leaked its internal code into user-facing text',
        );
      }
    }
  });

  test('safety-critical wording cannot regress', () {
    expect(
      calculationWarningText('solarSafety'),
      contains('certified solar filter'),
    );
    expect(calculationWarningText('frame_limit'), contains('1,000-frame'));
    expect(calculationWarningText('sampling_visible'), contains('Airy disk'));
    expect(
      calculationWarningText('milkyWayOrientationUndefined'),
      contains('zenith'),
    );
  });

  test('an unknown code still names itself instead of staying silent', () {
    final text = calculationWarningText('some_future_code');
    expect(text, contains('some_future_code'));
  });
}
