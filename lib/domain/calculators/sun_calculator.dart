import 'dart:math' as math;

class SolarPosition {
  const SolarPosition({
    required this.azimuthDeg,
    required this.altitudeDeg,
  });

  final double azimuthDeg;
  final double altitudeDeg;
}

class SunCalculator {
  // Normalize degrees to 0..360 range
  static double normalizeDegrees(double deg) {
    double out = deg;
    while (out < 0) {
      out += 360;
    }
    while (out >= 360) {
      out -= 360;
    }
    return out;
  }

  static double _sinDeg(double deg) => math.sin(_degToRad(deg));
  static double _cosDeg(double deg) => math.cos(_degToRad(deg));
  static double _tanDeg(double deg) => math.tan(_degToRad(deg));
  static double _degToRad(double deg) => deg * math.pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / math.pi;

  // Calculate sun event (sunrise/sunset or twilight) for given parameters
  // Returns null if event doesn't occur (e.g., polar night/day)
  static DateTime? calculateSunEvent(
    DateTime date,
    double latitude,
    double longitude,
    double zenithDeg,
    bool isSunrise,
    double timezoneHours,
  ) {
    final n = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final lngHour = longitude / 15.0;
    final t = n + ((isSunrise ? 6 : 18) - lngHour) / 24.0;

    double m = (0.9856 * t) - 3.289;
    m = normalizeDegrees(m);

    double l = m + (1.916 * _sinDeg(m)) + (0.020 * _sinDeg(2 * m)) + 282.634;
    l = normalizeDegrees(l);

    double ra = _radToDeg(math.atan(0.91764 * _tanDeg(l)));
    ra = normalizeDegrees(ra);

    final lQuadrant = (l / 90.0).floor() * 90.0;
    final raQuadrant = (ra / 90.0).floor() * 90.0;
    ra = (ra + (lQuadrant - raQuadrant)) / 15.0;

    final sinDec = 0.39782 * _sinDeg(l);
    final cosDec = math.cos(math.asin(sinDec));

    final cosH = (_cosDeg(zenithDeg) - (sinDec * _sinDeg(latitude))) /
        (cosDec * _cosDeg(latitude));

    if (cosH > 1 || cosH < -1) {
      return null;
    }

    double h = isSunrise
        ? 360.0 - _radToDeg(math.acos(cosH))
        : _radToDeg(math.acos(cosH));
    h /= 15.0;

    final tLocal = h + ra - (0.06571 * t) - 6.622;
    double ut = tLocal - lngHour;
    while (ut < 0) {
      ut += 24;
    }
    while (ut >= 24) {
      ut -= 24;
    }

    double localHours = ut + timezoneHours;
    while (localHours < 0) {
      localHours += 24;
    }
    while (localHours >= 24) {
      localHours -= 24;
    }

    final hour = localHours.floor();
    final minute = ((localHours - hour) * 60).floor();
    final second = ((((localHours - hour) * 60) - minute) * 60).round();

    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  // Approximate solar azimuth/altitude for a local datetime and observer.
  // Azimuth is degrees from North clockwise (0..360).
  static SolarPosition calculateSolarPosition(
    DateTime localDateTime,
    double latitudeDeg,
    double longitudeDeg,
  ) {
    final utc = localDateTime.toUtc();

    final y = utc.year;
    final m = utc.month;
    final d = utc.day;
    final hour = utc.hour + (utc.minute / 60.0) + (utc.second / 3600.0);

    final yy = m <= 2 ? y - 1 : y;
    final mm = m <= 2 ? m + 12 : m;

    final a = (yy / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (yy + 4716)).floorToDouble() +
        (30.6001 * (mm + 1)).floorToDouble() +
        d +
        b -
        1524.5 +
        (hour / 24.0);

    final t = (jd - 2451545.0) / 36525.0;
    final l0 = normalizeDegrees(
      280.46646 + t * (36000.76983 + t * 0.0003032),
    );
    final mSun = normalizeDegrees(
      357.52911 + t * (35999.05029 - 0.0001537 * t),
    );
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final c =
        math.sin(_degToRad(mSun)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
            math.sin(_degToRad(2 * mSun)) * (0.019993 - 0.000101 * t) +
            math.sin(_degToRad(3 * mSun)) * 0.000289;
    final trueLong = l0 + c;
    final omega = 125.04 - 1934.136 * t;
    final lambda = trueLong - 0.00569 - 0.00478 * math.sin(_degToRad(omega));
    final epsilon0 = 23 +
        (26 + ((21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0)) /
            60.0;
    final epsilon = epsilon0 + 0.00256 * math.cos(_degToRad(omega));

    final sinDecl = math.sin(_degToRad(epsilon)) * math.sin(_degToRad(lambda));
    final decl = _radToDeg(math.asin(sinDecl));

    final yTerm = math.tan(_degToRad(epsilon / 2.0));
    final ySq = yTerm * yTerm;
    final eqTime = 4 *
        _radToDeg(
          ySq * math.sin(2 * _degToRad(l0)) -
              2 * e * math.sin(_degToRad(mSun)) +
              4 *
                  e *
                  ySq *
                  math.sin(_degToRad(mSun)) *
                  math.cos(2 * _degToRad(l0)) -
              0.5 * ySq * ySq * math.sin(4 * _degToRad(l0)) -
              1.25 * e * e * math.sin(2 * _degToRad(mSun)),
        );

    final minutes = localDateTime.hour * 60 +
        localDateTime.minute +
        (localDateTime.second / 60.0);
    final timezoneMinutes = localDateTime.timeZoneOffset.inMinutes.toDouble();
    final trueSolarTime =
        (minutes + eqTime + 4 * longitudeDeg - timezoneMinutes) % 1440;

    var hourAngle = trueSolarTime / 4.0 - 180.0;
    if (hourAngle < -180) {
      hourAngle += 360;
    }

    final haRad = _degToRad(hourAngle);
    final latRad = _degToRad(latitudeDeg);
    final decRad = _degToRad(decl);

    final cosZenith = math.sin(latRad) * math.sin(decRad) +
        math.cos(latRad) * math.cos(decRad) * math.cos(haRad);
    final zenith = _radToDeg(math.acos(cosZenith.clamp(-1.0, 1.0)));
    final altitude = 90.0 - zenith;

    final azRad = math.atan2(
      math.sin(haRad),
      math.cos(haRad) * math.sin(latRad) - math.tan(decRad) * math.cos(latRad),
    );
    final azimuth = normalizeDegrees(_radToDeg(azRad) + 180.0);

    return SolarPosition(
      azimuthDeg: azimuth,
      altitudeDeg: altitude,
    );
  }
}
