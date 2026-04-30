import 'package:camera_assistant/domain/calculators/dof_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DOFCalculator', () {
    test('computes macro focus plane thickness from magnification', () {
      final thickness =
          DOFCalculator.computeFocusPlaneThicknessFromMagnification(
        5.6,
        0.00003,
        2.0,
      );

      expect(thickness, closeTo(0.000252, 0.0000001));
    });

    test('returns null when magnification is not positive', () {
      expect(
        DOFCalculator.computeFocusPlaneThicknessFromMagnification(
          5.6,
          0.00003,
          0,
        ),
        isNull,
      );
    });
  });
}
