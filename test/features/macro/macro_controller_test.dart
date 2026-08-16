import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/features/macro/macro_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const controller = MacroController();

  const lens = Lens(
    id: 1,
    name: '24-70',
    minApertureWide: 2.8,
    minApertureTele: 4.0,
    maxAperture: 22,
    variableAperture: true,
    minFocalLengthMm: 24,
    maxFocalLengthMm: 70,
    minFocusDistanceM: 0.38,
  );

  test('clamps and formats focal length for a lens', () {
    final formatted = controller.clampAndFormatFocalForLens(lens, 200);
    expect(formatted, '70');
  });

  test('clamps aperture for focal range and formats with one decimal', () {
    final formatted = controller.clampAndFormatApertureForLens(
      lens,
      focalMm: 70,
      aperture: 1.8,
    );
    expect(formatted, '4.0');
  });

  test('suggests bounded subject depth from focus plane thickness', () {
    expect(controller.suggestMacroSubjectDepth(0.0001), closeTo(0.001, 0.0));
    expect(controller.suggestMacroSubjectDepth(0.03), closeTo(0.05, 0.0));
  });
}
