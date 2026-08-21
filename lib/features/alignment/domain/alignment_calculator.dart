/// Planning-grade offline Sun/Moon positions and alignment search.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';

enum AlignmentBody { sun, moon }

final class SkyPosition {
  const SkyPosition({
    required this.azimuthDegrees,
    required this.altitudeDegrees,
  });
  final double azimuthDegrees;
  final double altitudeDegrees;
}

final class AlignmentSearchInput {
  const AlignmentSearchInput({
    required this.body,
    required this.observerLatitudeDegrees,
    required this.observerLongitudeDegrees,
    required this.observerElevationMetres,
    required this.targetElevationMetres,
    required this.targetDistanceMetres,
    required this.desiredBearingDegrees,
    required this.angularToleranceDegrees,
    required this.startUtc,
    required this.endUtc,
  });
  final AlignmentBody body;
  final double observerLatitudeDegrees;
  final double observerLongitudeDegrees;
  final double observerElevationMetres;
  final double targetElevationMetres;
  final double targetDistanceMetres;
  final double desiredBearingDegrees;
  final double angularToleranceDegrees;
  final DateTime startUtc;
  final DateTime endUtc;
}

final class AlignmentCandidate {
  const AlignmentCandidate({
    required this.instantUtc,
    required this.azimuthDegrees,
    required this.altitudeDegrees,
    required this.angularErrorDegrees,
    required this.aboveHorizon,
  });
  final DateTime instantUtc;
  final double azimuthDegrees;
  final double altitudeDegrees;
  final double angularErrorDegrees;
  final bool aboveHorizon;
}

final class AlignmentSearchOutput {
  const AlignmentSearchOutput({
    required this.desiredAltitudeDegrees,
    required this.candidates,
    required this.sampleMinutes,
  });
  final double desiredAltitudeDegrees;
  final List<AlignmentCandidate> candidates;
  final int sampleMinutes;
}

final class AlignmentCalculator {
  const AlignmentCalculator({this.ephemeris = const SolarLunarEphemeris()});
  static const id = 'sun_moon_alignment';
  static const version = 1;
  final SolarLunarEphemeris ephemeris;

  CalculationResult<AlignmentSearchOutput> search(AlignmentSearchInput input) {
    final validity = <String, bool>{
      'observerLatitudeDegrees': _between(
        input.observerLatitudeDegrees,
        -90,
        90,
      ),
      'observerLongitudeDegrees': _between(
        input.observerLongitudeDegrees,
        -180,
        180,
      ),
      'observerElevationMetres': input.observerElevationMetres.isFinite,
      'targetElevationMetres': input.targetElevationMetres.isFinite,
      'targetDistanceMetres': _positive(input.targetDistanceMetres),
      'desiredBearingDegrees': _between(
        input.desiredBearingDegrees,
        0,
        359.999999,
      ),
      'angularToleranceDegrees': _between(
        input.angularToleranceDegrees,
        0.01,
        180,
      ),
    };
    final errors = [
      for (final entry in validity.entries)
        if (!entry.value) _error(entry.key),
      if (!input.startUtc.isUtc ||
          !input.endUtc.isUtc ||
          input.endUtc.isBefore(input.startUtc) ||
          input.endUtc.difference(input.startUtc) > const Duration(days: 31))
        _error('dateRange'),
    ];
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final desiredAltitude = _degrees(
      math.atan2(
        input.targetElevationMetres - input.observerElevationMetres,
        input.targetDistanceMetres,
      ),
    );
    const step = Duration(minutes: 10);
    final samples = <AlignmentCandidate>[];
    for (
      var instant = input.startUtc;
      !instant.isAfter(input.endUtc);
      instant = instant.add(step)
    ) {
      final position = ephemeris.position(
        body: input.body,
        instantUtc: instant,
        latitudeDegrees: input.observerLatitudeDegrees,
        longitudeDegrees: input.observerLongitudeDegrees,
      );
      final azimuthError =
          _signed(position.azimuthDegrees - input.desiredBearingDegrees) *
          math.cos(_radians(desiredAltitude));
      final altitudeError = position.altitudeDegrees - desiredAltitude;
      final error = math.sqrt(
        azimuthError * azimuthError + altitudeError * altitudeError,
      );
      samples.add(
        AlignmentCandidate(
          instantUtc: instant,
          azimuthDegrees: position.azimuthDegrees,
          altitudeDegrees: position.altitudeDegrees,
          angularErrorDegrees: error,
          aboveHorizon: position.altitudeDegrees >= 0,
        ),
      );
    }
    final localMinima = <AlignmentCandidate>[];
    for (var index = 0; index < samples.length; index++) {
      final candidate = samples[index];
      final previous = index == 0
          ? double.infinity
          : samples[index - 1].angularErrorDegrees;
      final next = index == samples.length - 1
          ? double.infinity
          : samples[index + 1].angularErrorDegrees;
      if (candidate.angularErrorDegrees <= input.angularToleranceDegrees &&
          candidate.angularErrorDegrees <= previous &&
          candidate.angularErrorDegrees <= next) {
        localMinima.add(candidate);
      }
    }
    localMinima.sort(
      (a, b) => a.angularErrorDegrees.compareTo(b.angularErrorDegrees),
    );
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: AlignmentSearchOutput(
        desiredAltitudeDegrees: desiredAltitude,
        candidates: List.unmodifiable(localMinima.take(20)),
        sampleMinutes: step.inMinutes,
      ),
      assumptions: const [
        CalculationAssumption(
          key: 'terrain',
          value: 'unobstructed geometric horizon',
        ),
        CalculationAssumption(key: 'refraction', value: 'not applied'),
        CalculationAssumption(key: 'north', value: 'true north'),
      ],
      warnings: [
        const CalculationWarning(
          code: 'sampling',
          messageKey: 'alignment.warning.tenMinuteSampling',
        ),
        if (input.body == AlignmentBody.sun)
          const CalculationWarning(
            code: 'solarSafety',
            messageKey: 'alignment.warning.solarSafety',
          ),
      ],
    );
  }
}

final class SolarLunarEphemeris {
  const SolarLunarEphemeris();
  SkyPosition position({
    required AlignmentBody body,
    required DateTime instantUtc,
    required double latitudeDegrees,
    required double longitudeDegrees,
  }) {
    final equatorial = body == AlignmentBody.sun
        ? _sun(instantUtc)
        : _moon(instantUtc);
    final localSidereal = _normalize(_gmst(instantUtc) + longitudeDegrees);
    final hourAngle = _radians(_signed(localSidereal - equatorial.$1));
    final latitude = _radians(latitudeDegrees);
    final declination = _radians(equatorial.$2);
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
    return SkyPosition(
      azimuthDegrees: azimuth,
      altitudeDegrees: _degrees(altitude),
    );
  }

  (double, double) _sun(DateTime time) {
    final days = _julian(time) - 2451545;
    final anomaly = _radians(_normalize(357.529 + 0.98560028 * days));
    final longitude = _radians(
      _normalize(
        280.459 +
            0.98564736 * days +
            1.915 * math.sin(anomaly) +
            0.020 * math.sin(2 * anomaly),
      ),
    );
    final obliquity = _radians(23.439 - 0.00000036 * days);
    return (
      _normalize(
        _degrees(
          math.atan2(
            math.cos(obliquity) * math.sin(longitude),
            math.cos(longitude),
          ),
        ),
      ),
      _degrees(math.asin(math.sin(obliquity) * math.sin(longitude))),
    );
  }

  (double, double) _moon(DateTime time) {
    final days = _julian(time) - 2451543.5;
    final node = _radians(_normalize(125.1228 - 0.0529538083 * days));
    const inclination = 5.1454;
    final periapsis = _normalize(318.0634 + 0.1643573223 * days);
    const eccentricity = 0.0549;
    final anomalyDegrees = _normalize(115.3654 + 13.0649929509 * days);
    final anomaly = _radians(anomalyDegrees);
    final eccentricAnomaly =
        anomalyDegrees +
        _degrees(
          eccentricity *
              math.sin(anomaly) *
              (1 + eccentricity * math.cos(anomaly)),
        );
    final x = 60.2666 * (math.cos(_radians(eccentricAnomaly)) - eccentricity);
    final y =
        60.2666 *
        math.sqrt(1 - eccentricity * eccentricity) *
        math.sin(_radians(eccentricAnomaly));
    final trueAnomaly = _degrees(math.atan2(y, x));
    final radius = math.sqrt(x * x + y * y);
    final argument = _radians(trueAnomaly + periapsis);
    final inc = _radians(inclination);
    final xe =
        radius *
        (math.cos(node) * math.cos(argument) -
            math.sin(node) * math.sin(argument) * math.cos(inc));
    final ye =
        radius *
        (math.sin(node) * math.cos(argument) +
            math.cos(node) * math.sin(argument) * math.cos(inc));
    final ze = radius * math.sin(argument) * math.sin(inc);
    final obliquity = _radians(23.4393 - 3.563e-7 * days);
    final xeq = xe;
    final yeq = ye * math.cos(obliquity) - ze * math.sin(obliquity);
    final zeq = ye * math.sin(obliquity) + ze * math.cos(obliquity);
    return (
      _normalize(_degrees(math.atan2(yeq, xeq))),
      _degrees(math.atan2(zeq, math.sqrt(xeq * xeq + yeq * yeq))),
    );
  }
}

bool _positive(double value) => value.isFinite && value > 0;
bool _between(double value, double minimum, double maximum) =>
    value.isFinite && value >= minimum && value <= maximum;
ValidationError _error(String field) => ValidationError(
  field: field,
  code: 'range',
  messageKey: 'alignment.error.$field',
);
double _radians(double value) => value * math.pi / 180;
double _degrees(double value) => value * 180 / math.pi;
double _normalize(double value) => (value % 360 + 360) % 360;
double _signed(double value) {
  final n = _normalize(value);
  return n > 180 ? n - 360 : n;
}

double _julian(DateTime time) =>
    time.microsecondsSinceEpoch / Duration.microsecondsPerDay + 2440587.5;
double _gmst(DateTime time) {
  final jd = _julian(time);
  final t = (jd - 2451545) / 36525;
  return _normalize(
    280.46061837 +
        360.98564736629 * (jd - 2451545) +
        0.000387933 * t * t -
        t * t * t / 38710000,
  );
}
