import 'package:camera_assistant/domain/calculators/macro_calculator.dart';
import 'package:camera_assistant/features/macro/macro_state.dart';
import 'package:camera_assistant/features/macro/macro_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = MacroUseCase();

  group('MacroUseCase extension', () {
    test('returns error when values are invalid', () {
      final result = useCase.calculateExtension(
        const ExtensionMacroInput(
          focalLengthMm: 0,
          aperture: 2.8,
          minimumFocusDistanceM: 0.45,
          extensionLengthMm: 25,
          cocM: 0.00003,
        ),
      );

      expect(result, isA<MacroCalculationError>());
      expect(
        (result as MacroCalculationError).message,
        'Enter valid values. Tube length may be zero, all other values must be positive.',
      );
    });

    test('calculates extension result when values are valid', () {
      final result = useCase.calculateExtension(
        const ExtensionMacroInput(
          focalLengthMm: 50,
          aperture: 2.8,
          minimumFocusDistanceM: 0.45,
          extensionLengthMm: 25,
          cocM: 0.00003,
        ),
      );

      expect(result, isA<MacroCalculationSuccess>());
      final extension =
          (result as MacroCalculationSuccess<ExtensionTubeResult>).result;
      expect(extension.maximumMagnification, closeTo(0.6459, 0.0001));
    });
  });

  group('MacroUseCase reverse and dual', () {
    test('returns reverse error when mount is missing', () {
      final result = useCase.calculateReverse(
        const ReverseMacroInput(
          focalLengthMm: 28,
          aperture: 2.8,
          extraExtensionMm: 0,
          mountRegisterDistanceMm: null,
          cocM: 0.00003,
        ),
      );

      expect(result, isA<MacroCalculationError>());
    });

    test('calculates reverse result when values are valid', () {
      final result = useCase.calculateReverse(
        const ReverseMacroInput(
          focalLengthMm: 28,
          aperture: 2.8,
          extraExtensionMm: 0,
          mountRegisterDistanceMm: 44,
          cocM: 0.00003,
        ),
      );

      expect(result, isA<MacroCalculationSuccess>());
      final reverse =
          (result as MacroCalculationSuccess<ReverseLensResult>).result;
      expect(reverse.magnification, closeTo(1.5714, 0.0001));
    });

    test('calculates dual lens result when values are valid', () {
      final result = useCase.calculateDual(
        const DualMacroInput(
          takingLensFocalLengthMm: 100,
          takingLensAperture: 5.6,
          frontLensFocalLengthMm: 50,
          cocM: 0.00003,
        ),
      );

      expect(result, isA<MacroCalculationSuccess>());
      final dual =
          (result as MacroCalculationSuccess<DualLensMacroResult>).result;
      expect(dual.magnification, closeTo(2.0, 0.0001));
    });
  });
}
