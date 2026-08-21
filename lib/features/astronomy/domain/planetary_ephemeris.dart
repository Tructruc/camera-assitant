import 'dart:math' as math;

enum PlanetId { mercury, venus, mars, jupiter, saturn }

/// JPL's 1800-2050 approximate Keplerian-elements model.
final class PlanetaryEphemeris {
  const PlanetaryEphemeris();

  (double, double) equatorial(PlanetId planet, DateTime utc) {
    final centuries = (_julian(utc.toUtc()) - 2451545.0) / 36525;
    final earth = _vector(_earth, centuries);
    final body = _vector(_planets[planet]!, centuries);
    final x = body.$1 - earth.$1;
    final y = body.$2 - earth.$2;
    final z = body.$3 - earth.$3;
    const epsilon = 23.43928 * math.pi / 180;
    final yeq = y * math.cos(epsilon) - z * math.sin(epsilon);
    final zeq = y * math.sin(epsilon) + z * math.cos(epsilon);
    return (
      _normalize(_degrees(math.atan2(yeq, x))),
      _degrees(math.atan2(zeq, math.sqrt(x * x + yeq * yeq))),
    );
  }

  (double, double, double) _vector(_Elements e, double t) {
    final a = e.a0 + e.a1 * t;
    final eccentricity = e.e0 + e.e1 * t;
    final inclination = _radians(e.i0 + e.i1 * t);
    final perihelion = e.p0 + e.p1 * t;
    final node = _radians(e.n0 + e.n1 * t);
    final mean = _radians(_signed(e.l0 + e.l1 * t - perihelion));
    var eccentricAnomaly = mean;
    for (var iteration = 0; iteration < 12; iteration++) {
      eccentricAnomaly -=
          (eccentricAnomaly -
              eccentricity * math.sin(eccentricAnomaly) -
              mean) /
          (1 - eccentricity * math.cos(eccentricAnomaly));
    }
    final xp = a * (math.cos(eccentricAnomaly) - eccentricity);
    final yp =
        a *
        math.sqrt(1 - eccentricity * eccentricity) *
        math.sin(eccentricAnomaly);
    final omega = _radians(perihelion) - node;
    final x =
        (math.cos(omega) * math.cos(node) -
                math.sin(omega) * math.sin(node) * math.cos(inclination)) *
            xp +
        (-math.sin(omega) * math.cos(node) -
                math.cos(omega) * math.sin(node) * math.cos(inclination)) *
            yp;
    final y =
        (math.cos(omega) * math.sin(node) +
                math.sin(omega) * math.cos(node) * math.cos(inclination)) *
            xp +
        (-math.sin(omega) * math.sin(node) +
                math.cos(omega) * math.cos(node) * math.cos(inclination)) *
            yp;
    final z =
        math.sin(omega) * math.sin(inclination) * xp +
        math.cos(omega) * math.sin(inclination) * yp;
    return (x, y, z);
  }
}

final class _Elements {
  const _Elements(
    this.a0,
    this.a1,
    this.e0,
    this.e1,
    this.i0,
    this.i1,
    this.l0,
    this.l1,
    this.p0,
    this.p1,
    this.n0,
    this.n1,
  );
  final double a0, a1, e0, e1, i0, i1, l0, l1, p0, p1, n0, n1;
}

const _earth = _Elements(
  1.00000261,
  .00000562,
  .01671123,
  -.00004392,
  -.00001531,
  -.01294668,
  100.46457166,
  35999.37244981,
  102.93768193,
  .32327364,
  0,
  0,
);
const _planets = <PlanetId, _Elements>{
  PlanetId.mercury: _Elements(
    .38709927,
    .00000037,
    .20563593,
    .00001906,
    7.00497902,
    -.00594749,
    252.2503235,
    149472.67411175,
    77.45779628,
    .16047689,
    48.33076593,
    -.12534081,
  ),
  PlanetId.venus: _Elements(
    .72333566,
    .0000039,
    .00677672,
    -.00004107,
    3.39467605,
    -.0007889,
    181.9790995,
    58517.81538729,
    131.60246718,
    .00268329,
    76.67984255,
    -.27769418,
  ),
  PlanetId.mars: _Elements(
    1.52371034,
    .00001847,
    .0933941,
    .00007882,
    1.84969142,
    -.00813131,
    -4.55343205,
    19140.30268499,
    -23.94362959,
    .44441088,
    49.55953891,
    -.29257343,
  ),
  PlanetId.jupiter: _Elements(
    5.202887,
    -.00011607,
    .04838624,
    -.00013253,
    1.30439695,
    -.00183714,
    34.39644051,
    3034.74612775,
    14.72847983,
    .21252668,
    100.47390909,
    .20469106,
  ),
  PlanetId.saturn: _Elements(
    9.53667594,
    -.0012506,
    .05386179,
    -.00050991,
    2.48599187,
    .00193609,
    49.95424423,
    1222.49362201,
    92.59887831,
    -.41897216,
    113.66242448,
    -.28867794,
  ),
};

double _julian(DateTime t) =>
    t.microsecondsSinceEpoch / Duration.microsecondsPerDay + 2440587.5;
double _radians(double value) => value * math.pi / 180;
double _degrees(double value) => value * 180 / math.pi;
double _normalize(double value) => (value % 360 + 360) % 360;
double _signed(double value) {
  final n = _normalize(value);
  return n > 180 ? n - 360 : n;
}
