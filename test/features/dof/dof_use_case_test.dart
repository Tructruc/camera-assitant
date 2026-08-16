import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/features/dof/dof_state.dart';
import 'package:camera_assistant/features/dof/dof_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sensor = SensorPreset(
    id: 'full_frame',
    label: 'Full Frame',
    cocMm: 0.030,
    widthMm: 36,
    heightMm: 24,
  );

  final lens = Lens(
    id: 1,
    name: 'Macro 100',
    minApertureWide: 2.8,
    minApertureTele: 2.8,
    maxAperture: 32,
    variableAperture: false,
    minFocalLengthMm: 100,
    maxFocalLengthMm: 100,
    minFocusDistanceM: 0.3,
  );

  const useCase = DofUseCase();

  test('returns hidden live error for incomplete positive inputs', () {
    final result = useCase.calculate(
      const DofInput(
        focalLengthMm: null,
        aperture: 2.8,
        subjectDistanceM: 3,
        sensor: sensor,
      ),
      live: true,
    );

    expect(result, isA<DofCalculationError>());
    expect((result as DofCalculationError).message, isNull);
  });

  test('validates lens minimum focus distance', () {
    final result = useCase.calculate(
      DofInput(
        focalLengthMm: 100,
        aperture: 5.6,
        subjectDistanceM: 0.2,
        sensor: sensor,
        lens: lens,
      ),
    );

    expect(result, isA<DofCalculationError>());
    expect(
      (result as DofCalculationError).message,
      contains('Subject distance must be at least 0.30 m'),
    );
  });

  test('validates lens aperture range at focal length', () {
    final result = useCase.calculate(
      DofInput(
        focalLengthMm: 100,
        aperture: 1.4,
        subjectDistanceM: 1,
        sensor: sensor,
        lens: lens,
      ),
    );

    expect(result, isA<DofCalculationError>());
    expect(
      (result as DofCalculationError).message,
      contains('Aperture must stay within f/2.8 and f/32.0'),
    );
  });

  test('calculates depth of field result from valid input', () {
    final result = useCase.calculate(
      const DofInput(
        focalLengthMm: 50,
        aperture: 2.8,
        subjectDistanceM: 3,
        sensor: sensor,
      ),
    );

    expect(result, isA<DofCalculationSuccess>());
    final dof = (result as DofCalculationSuccess).result;
    expect(dof.hyperfocalM, closeTo(29.81, 0.01));
    expect(dof.nearLimitM, closeTo(2.73, 0.01));
    expect(dof.farLimitM, closeTo(3.32, 0.01));
  });
}
