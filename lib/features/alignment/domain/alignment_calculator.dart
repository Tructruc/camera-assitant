/// Planning-grade offline Sun/Moon positions and alignment search.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';
import '../../astronomy/domain/solar_lunar_ephemeris.dart' as solar;

enum AlignmentBody { sun, moon }

final class SkyPosition {
  const SkyPosition({
    required this.azimuthDegrees,
    required this.altitudeDegrees,
  });
  final double azimuthDegrees;
  final double altitudeDegrees;
}

final class TargetGeometry {
  const TargetGeometry({
    required this.bearingDegrees,
    required this.distanceMetres,
  });
  final double bearingDegrees;
  final double distanceMetres;

  static TargetGeometry fromCoordinates({
    required double observerLatitudeDegrees,
    required double observerLongitudeDegrees,
    required double targetLatitudeDegrees,
    required double targetLongitudeDegrees,
  }) {
    if (!_between(observerLatitudeDegrees, -90, 90) ||
        !_between(targetLatitudeDegrees, -90, 90) ||
        !_between(observerLongitudeDegrees, -180, 180) ||
        !_between(targetLongitudeDegrees, -180, 180)) {
      throw const FormatException('Coordinates must be valid degrees.');
    }
    final lat1 = _radians(observerLatitudeDegrees);
    final lat2 = _radians(targetLatitudeDegrees);
    final dLat = lat2 - lat1;
    final dLon = _radians(targetLongitudeDegrees - observerLongitudeDegrees);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final distance = 6371008.8 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final bearing = _normalize(
      _degrees(
        math.atan2(
          math.sin(dLon) * math.cos(lat2),
          math.cos(lat1) * math.sin(lat2) -
              math.sin(lat1) * math.cos(lat2) * math.cos(dLon),
        ),
      ),
    );
    return TargetGeometry(bearingDegrees: bearing, distanceMetres: distance);
  }
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
  const AlignmentCalculator({this.ephemeris = const AlignmentSkyEphemeris()});
  static const id = 'sun_moon_alignment';
  static const version = 2;
  static const maximumRange = Duration(days: 366);
  final AlignmentSkyEphemeris ephemeris;

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
          input.endUtc.difference(input.startUtc) > maximumRange)
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
    AlignmentCandidate candidateAt(DateTime instant) {
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
      return AlignmentCandidate(
        instantUtc: instant,
        azimuthDegrees: position.azimuthDegrees,
        altitudeDegrees: position.altitudeDegrees,
        angularErrorDegrees: error,
        aboveHorizon: position.altitudeDegrees >= 0,
      );
    }

    final bestCandidates = <AlignmentCandidate>[];
    void retainIfLocalMinimum(
      AlignmentCandidate candidate,
      double previousError,
      double nextError,
    ) {
      if (candidate.angularErrorDegrees <= input.angularToleranceDegrees &&
          candidate.angularErrorDegrees <= previousError &&
          candidate.angularErrorDegrees <= nextError) {
        bestCandidates.add(candidate);
        bestCandidates.sort(
          (a, b) => a.angularErrorDegrees.compareTo(b.angularErrorDegrees),
        );
        if (bestCandidates.length > 20) bestCandidates.removeLast();
      }
    }

    var previousError = double.infinity;
    var current = candidateAt(input.startUtc);
    for (
      var instant = input.startUtc.add(step);
      !instant.isAfter(input.endUtc);
      instant = instant.add(step)
    ) {
      final next = candidateAt(instant);
      retainIfLocalMinimum(current, previousError, next.angularErrorDegrees);
      previousError = current.angularErrorDegrees;
      current = next;
    }
    retainIfLocalMinimum(current, previousError, double.infinity);

    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: AlignmentSearchOutput(
        desiredAltitudeDegrees: desiredAltitude,
        candidates: List.unmodifiable(bestCandidates),
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

/// Observer-relative Sun and Moon positions for alignment searches.
/// Named apart from the astronomy [solar.SolarLunarEphemeris] it delegates to,
/// so a file importing both planners is unambiguous.
final class AlignmentSkyEphemeris {
  const AlignmentSkyEphemeris();

  /// Observer-relative position, resolved from the shared astronomy ephemeris
  /// so both planners use one Sun/Moon model.
  SkyPosition position({
    required AlignmentBody body,
    required DateTime instantUtc,
    required double latitudeDegrees,
    required double longitudeDegrees,
  }) {
    final equatorial = const solar.SolarLunarEphemeris().equatorial(
      body == AlignmentBody.sun
          ? solar.SolarLunarBody.sun
          : solar.SolarLunarBody.moon,
      instantUtc,
    );
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
