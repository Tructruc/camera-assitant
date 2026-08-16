import 'package:camera_assistant/domain/models/lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lens', () {
    test('formats labels from optical fields', () {
      final lens = Lens(
        name: 'Travel Zoom',
        brand: 'Canon',
        model: '24-70',
        minApertureWide: 2.8,
        minApertureTele: 4.0,
        maxAperture: 22.0,
        variableAperture: true,
        minFocalLengthMm: 24.0,
        maxFocalLengthMm: 70.0,
        minFocusDistanceM: 0.38,
      );

      expect(lens.isZoom, isTrue);
      expect(lens.focalLabel, '24-70mm');
      expect(lens.apertureLabel, 'f/2.8-4.0 to f/22.0');
      expect(lens.displayLabel, 'Travel Zoom (24-70mm, f/2.8-4.0 to f/22.0)');
      expect(lens.identityLabel, 'Canon 24-70');
    });

    test('interpolates variable aperture by focal length', () {
      final lens = Lens(
        name: 'Travel Zoom',
        minApertureWide: 3.5,
        minApertureTele: 5.6,
        maxAperture: 22.0,
        variableAperture: true,
        minFocalLengthMm: 24.0,
        maxFocalLengthMm: 70.0,
        minFocusDistanceM: 0.38,
      );

      expect(lens.minApertureAtFocal(24), closeTo(3.5, 0.001));
      expect(lens.minApertureAtFocal(70), closeTo(5.6, 0.001));
      expect(lens.minApertureAtFocal(47), closeTo(4.55, 0.001));
    });
  });
}
