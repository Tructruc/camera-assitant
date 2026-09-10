/// Shared planning-grade Sun and Moon geocentric equatorial coordinates.
///
/// Extracted from the alignment planner so the Sun/Moon model exists once and
/// the night-sky planner can resolve the same bodies. The formulas are the
/// USNO-style truncated series: geocentric, mean equinox of date, without
/// nutation, aberration, or the lunar perturbations omitted by the simplified
/// Keplerian lunar elements. This is planning-grade, never observatory-grade,
/// and reads no clock, locale, or platform service.
library;

import 'dart:math' as math;

/// Bodies resolved by [SolarLunarEphemeris].
enum SolarLunarBody { sun, moon }

/// Deterministic Sun and Moon ephemeris shared by the night-sky and alignment
/// planners.
final class SolarLunarEphemeris {
  const SolarLunarEphemeris();

  /// One astronomical unit in Earth equatorial radii (IAU 2015 nominal values).
  static const astronomicalUnitEarthRadii = 23455.0;

  /// Geocentric right ascension and declination in degrees for [body] at
  /// [instantUtc].
  (double rightAscensionDegrees, double declinationDegrees) equatorial(
    SolarLunarBody body,
    DateTime instantUtc,
  ) {
    final geocentric = coordinates(body, instantUtc);
    return (geocentric.$1, geocentric.$2);
  }

  /// Geocentric right ascension and declination in degrees plus the distance in
  /// Earth equatorial radii, which observer parallax needs.
  (
    double rightAscensionDegrees,
    double declinationDegrees,
    double distanceEarthRadii,
  )
  coordinates(SolarLunarBody body, DateTime instantUtc) => switch (body) {
    SolarLunarBody.sun => _sun(instantUtc),
    SolarLunarBody.moon => _moon(instantUtc),
  };

  (double, double, double) _sun(DateTime time) {
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
    final distanceAu =
        1.00014 - 0.01671 * math.cos(anomaly) - 0.00014 * math.cos(2 * anomaly);
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
      distanceAu * astronomicalUnitEarthRadii,
    );
  }

  (double, double, double) _moon(DateTime time) {
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
      radius,
    );
  }
}

double _radians(double value) => value * math.pi / 180;
double _degrees(double value) => value * 180 / math.pi;
double _normalize(double value) => (value % 360 + 360) % 360;
double _julian(DateTime time) =>
    time.microsecondsSinceEpoch / Duration.microsecondsPerDay + 2440587.5;
