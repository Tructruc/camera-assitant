import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/quantities/quantities.dart';

void main() {
  group('Length', () {
    test('normalizes supported units to millimetres', () {
      expect(Length.metres(1).millimetres, 1000);
      expect(Length.centimetres(2.5).millimetres, 25);
      expect(Length.inches(1).millimetres, closeTo(25.4, 1e-12));
      expect(Length.feet(1).millimetres, closeTo(304.8, 1e-12));
    });

    test('converts without changing the canonical value', () {
      final length = Length.metres(1.25);

      expect(length.metres, 1.25);
      expect(length.inches, closeTo(49.2125984252, 1e-9));
      expect(length, Length.millimetres(1250));
    });

    test('rejects non-positive and non-finite values', () {
      for (final value in <double>[0, -1, double.nan, double.infinity]) {
        expect(() => Length.millimetres(value), throwsArgumentError);
      }
    });
  });

  test('positive photographic quantities reject invalid values', () {
    final constructors = <Object? Function(double)>[
      Aperture.new,
      ExposureTime.seconds,
      Sensitivity.iso,
      CircleOfConfusion.millimetres,
    ];

    for (final constructor in constructors) {
      for (final value in <double>[0, -1, double.nan, double.infinity]) {
        expect(() => constructor(value), throwsArgumentError);
      }
    }
  });

  test('stops may be signed while filter strength is non-negative', () {
    expect(StopDifference(-1.5).stops, -1.5);
    expect(StopDifference(0).stops, 0);
    expect(() => StopDifference(double.nan), throwsArgumentError);
    expect(FilterStrength(0).stops, 0);
    expect(() => FilterStrength(-0.1), throwsArgumentError);
  });

  test('focus distance represents finite distance or explicit infinity', () {
    expect(FocusDistance.millimetres(1500).isInfinite, isFalse);
    expect(FocusDistance.infinity.isInfinite, isTrue);
    expect(FocusDistance.infinity.millimetres, double.infinity);
  });
}
