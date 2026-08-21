import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';

final greenwichSiriusFixture = AstronomyInput(
  observerLatitudeDegrees: 51.4779,
  observerLongitudeDegrees: 0,
  instantUtc: DateTime.utc(2026, 1, 15, 22),
  target: CelestialTarget.sirius,
  focalLengthMm: 24,
  cropFactor: 1,
  aperture: 2.8,
  pixelPitchMicrometres: 5,
  desiredTrailDegrees: 30,
);
