/// Offline fixed-target sky position, event, and star-exposure planning.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';

enum CelestialTarget {
  milkyWayCore('Milky Way core', TargetCategory.milkyWay, 266.41683, -29.00781),
  polaris('Polaris', TargetCategory.star, 37.95456, 89.26411),
  sirius('Sirius', TargetCategory.star, 101.28716, -16.71612),
  orionNebula('Orion Nebula (M42)', TargetCategory.nebula, 83.82208, -5.39111),
  lagoonNebula('Lagoon Nebula (M8)', TargetCategory.nebula, 270.925, -24.375),
  eagleNebula('Eagle Nebula (M16)', TargetCategory.nebula, 274.7, -13.807),
  andromedaGalaxy(
    'Andromeda Galaxy (M31)',
    TargetCategory.galaxy,
    10.68471,
    41.26875,
  ),
  triangulumGalaxy(
    'Triangulum Galaxy (M33)',
    TargetCategory.galaxy,
    23.4621,
    30.6599,
  ),
  bodeGalaxy('Bode’s Galaxy (M81)', TargetCategory.galaxy, 148.8882, 69.0653),
  pleiades('Pleiades (M45)', TargetCategory.cluster, 56.75, 24.1167),
  herculesCluster(
    'Hercules Cluster (M13)',
    TargetCategory.cluster,
    250.4235,
    36.4613,
  ),
  omegaCentauri('Omega Centauri', TargetCategory.cluster, 201.697, -47.4795);

  const CelestialTarget(
    this.label,
    this.category,
    this.rightAscensionDegrees,
    this.declinationDegrees,
  );
  final String label;
  final TargetCategory category;
  final double rightAscensionDegrees;
  final double declinationDegrees;
}

enum TargetCategory { milkyWay, star, nebula, galaxy, cluster }

enum CelestialEventType { rise, transit, set }

enum VisibilityCycle { risesAndSets, circumpolar, neverRises }

final class CelestialEvent {
  const CelestialEvent({required this.type, required this.instantUtc});
  final CelestialEventType type;
  final DateTime instantUtc;
}

final class AstronomyInput {
  AstronomyInput({
    required this.observerLatitudeDegrees,
    required this.observerLongitudeDegrees,
    required this.instantUtc,
    required this.target,
    required this.focalLengthMm,
    required this.cropFactor,
    required this.aperture,
    required this.pixelPitchMicrometres,
    required this.desiredTrailDegrees,
  }) : assert(instantUtc.isUtc);
  final double observerLatitudeDegrees;
  final double observerLongitudeDegrees;
  final DateTime instantUtc;
  final CelestialTarget target;
  final double focalLengthMm;
  final double cropFactor;
  final double aperture;
  final double pixelPitchMicrometres;
  final double desiredTrailDegrees;
}

final class AstronomyOutput {
  const AstronomyOutput({
    required this.altitudeDegrees,
    required this.azimuthDegrees,
    required this.isAboveHorizon,
    required this.visibilityCycle,
    required this.events,
    required this.path,
    required this.rule500Seconds,
    required this.npfSeconds,
    required this.trailDurationSeconds,
    required this.trailRotationDegreesPerHour,
  });
  final double altitudeDegrees;
  final double azimuthDegrees;
  final bool isAboveHorizon;
  final VisibilityCycle visibilityCycle;
  final List<CelestialEvent> events;
  final List<SkyPositionSample> path;
  final double rule500Seconds;
  final double npfSeconds;
  final double trailDurationSeconds;
  final double trailRotationDegreesPerHour;
}

final class SkyPositionSample {
  const SkyPositionSample({
    required this.instantUtc,
    required this.altitudeDegrees,
    required this.azimuthDegrees,
  });
  final DateTime instantUtc;
  final double altitudeDegrees;
  final double azimuthDegrees;
}

final class AstronomyCalculator {
  const AstronomyCalculator();
  static const id = 'astronomy';
  static const version = 1;
  static const _siderealDaySeconds = 86164.0905;

  CalculationResult<AstronomyOutput> calculate(AstronomyInput input) {
    final values = <String, bool>{
      'observerLatitudeDegrees':
          input.observerLatitudeDegrees.isFinite &&
          input.observerLatitudeDegrees >= -90 &&
          input.observerLatitudeDegrees <= 90,
      'observerLongitudeDegrees':
          input.observerLongitudeDegrees.isFinite &&
          input.observerLongitudeDegrees >= -180 &&
          input.observerLongitudeDegrees <= 180,
      'focalLengthMm': _positive(input.focalLengthMm),
      'cropFactor': _positive(input.cropFactor),
      'aperture': _positive(input.aperture),
      'pixelPitchMicrometres': _positive(input.pixelPitchMicrometres),
      'desiredTrailDegrees':
          input.desiredTrailDegrees.isFinite &&
          input.desiredTrailDegrees > 0 &&
          input.desiredTrailDegrees <= 360,
    };
    final errors = [
      for (final entry in values.entries)
        if (!entry.value)
          ValidationError(
            field: entry.key,
            code: 'range',
            messageKey: 'astronomy.error.${entry.key}',
          ),
    ];
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final latitude = _radians(input.observerLatitudeDegrees);
    final declination = _radians(input.target.declinationDegrees);
    final localSidereal = _normalize(
      _greenwichSiderealDegrees(input.instantUtc) +
          input.observerLongitudeDegrees,
    );
    final hourAngleDegrees = _signed(
      localSidereal - input.target.rightAscensionDegrees,
    );
    final hourAngle = _radians(hourAngleDegrees);
    final altitude = math.asin(
      math.sin(latitude) * math.sin(declination) +
          math.cos(latitude) * math.cos(declination) * math.cos(hourAngle),
    );
    final azimuth = _normalize(
      _degrees(
            math.atan2(
              math.sin(hourAngle),
              math.cos(hourAngle) * math.sin(latitude) -
                  math.tan(declination) * math.cos(latitude),
            ),
          ) +
          180,
    );
    final eventPlan = _events(input, localSidereal, latitude, declination);
    final path = <SkyPositionSample>[
      for (var offset = -6; offset <= 6; offset += 2)
        _positionSample(input, input.instantUtc.add(Duration(hours: offset))),
    ];

    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: AstronomyOutput(
        altitudeDegrees: _degrees(altitude),
        azimuthDegrees: azimuth,
        isAboveHorizon: altitude > 0,
        visibilityCycle: eventPlan.$1,
        events: eventPlan.$2,
        path: List.unmodifiable(path),
        rule500Seconds: 500 / (input.focalLengthMm * input.cropFactor),
        npfSeconds:
            (35 * input.aperture + 30 * input.pixelPitchMicrometres) /
            input.focalLengthMm,
        trailDurationSeconds:
            _siderealDaySeconds * input.desiredTrailDegrees / 360,
        trailRotationDegreesPerHour: 360 * 3600 / _siderealDaySeconds,
      ),
      assumptions: const [
        CalculationAssumption(
          key: 'coordinates',
          value: 'ICRS/J2000 fixed target',
        ),
        CalculationAssumption(
          key: 'horizon',
          value: 'airless geometric zero degrees',
        ),
        CalculationAssumption(
          key: 'earthRotation',
          value: 'USNO approximate mean sidereal time',
        ),
      ],
      warnings: const [
        CalculationWarning(
          code: 'planningAccuracy',
          messageKey: 'astronomy.warning.planningOnly',
        ),
      ],
    );
  }

  SkyPositionSample _positionSample(AstronomyInput input, DateTime instantUtc) {
    final latitude = _radians(input.observerLatitudeDegrees);
    final declination = _radians(input.target.declinationDegrees);
    final hourAngle = _radians(
      _signed(
        _greenwichSiderealDegrees(instantUtc) +
            input.observerLongitudeDegrees -
            input.target.rightAscensionDegrees,
      ),
    );
    final altitude = math.asin(
      math.sin(latitude) * math.sin(declination) +
          math.cos(latitude) * math.cos(declination) * math.cos(hourAngle),
    );
    final azimuth = _normalize(
      _degrees(
            math.atan2(
              math.sin(hourAngle),
              math.cos(hourAngle) * math.sin(latitude) -
                  math.tan(declination) * math.cos(latitude),
            ),
          ) +
          180,
    );
    return SkyPositionSample(
      instantUtc: instantUtc,
      altitudeDegrees: _degrees(altitude),
      azimuthDegrees: azimuth,
    );
  }

  (VisibilityCycle, List<CelestialEvent>) _events(
    AstronomyInput input,
    double localSidereal,
    double latitude,
    double declination,
  ) {
    final transit = _event(input, localSidereal, 0, CelestialEventType.transit);
    final cosHourAngle = -math.tan(latitude) * math.tan(declination);
    if (cosHourAngle < -1) return (VisibilityCycle.circumpolar, [transit]);
    if (cosHourAngle > 1) return (VisibilityCycle.neverRises, [transit]);
    final horizonHourAngle = _degrees(math.acos(cosHourAngle));
    final events = [
      _event(input, localSidereal, -horizonHourAngle, CelestialEventType.rise),
      transit,
      _event(input, localSidereal, horizonHourAngle, CelestialEventType.set),
    ]..sort((a, b) => a.instantUtc.compareTo(b.instantUtc));
    return (VisibilityCycle.risesAndSets, List.unmodifiable(events));
  }

  CelestialEvent _event(
    AstronomyInput input,
    double localSidereal,
    double targetHourAngle,
    CelestialEventType type,
  ) {
    final currentHourAngle = _signed(
      localSidereal - input.target.rightAscensionDegrees,
    );
    final siderealDegreesAhead = _normalize(targetHourAngle - currentHourAngle);
    final seconds = (_siderealDaySeconds * siderealDegreesAhead / 360).round();
    return CelestialEvent(
      type: type,
      instantUtc: input.instantUtc.add(Duration(seconds: seconds)),
    );
  }
}

bool _positive(double value) => value.isFinite && value > 0;
double _radians(double value) => value * math.pi / 180;
double _degrees(double value) => value * 180 / math.pi;
double _normalize(double value) => (value % 360 + 360) % 360;
double _signed(double value) {
  final normalized = _normalize(value);
  return normalized > 180 ? normalized - 360 : normalized;
}

double _greenwichSiderealDegrees(DateTime instantUtc) {
  final julianDate =
      instantUtc.microsecondsSinceEpoch / Duration.microsecondsPerDay +
      2440587.5;
  final centuries = (julianDate - 2451545.0) / 36525;
  return _normalize(
    280.46061837 +
        360.98564736629 * (julianDate - 2451545.0) +
        0.000387933 * centuries * centuries -
        centuries * centuries * centuries / 38710000,
  );
}
