import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';

/// Reference positions for the bundled fixed-target catalog.
///
/// These are the ICRS/J2000 positions the app ships and attributes to
/// SIMBAD/CDS in `test/fixtures/astronomy/README.md`. The literals are repeated
/// here deliberately: the point is a regression guard, so editing a catalog
/// coordinate without updating its documented reference fails the test.
///
/// External spot-check (2026-09-11): the Lagoon Nebula entry was re-queried
/// against SIMBAD (`NAME Lagoon Nebula`,
/// <https://simbad.cds.unistra.fr/simbad/sim-id?Ident=NAME+Lagoon+Nebula>), which
/// returns ICRS J2000 `18 03 37.0 -24 23 12`, quality flag E (>= 10 arcsec), so
/// RA 270.9042 and Dec -24.3867. The shipped 270.925 / -24.375 is within 0.03
/// degrees of that position, which is what the extended-object tolerance below
/// allows. Sirius was already independently verified in
/// `solar_lunar_fixture_test.dart`.
void main() {
  // Extended objects have catalogue positions that legitimately differ between
  // sources by tens of arcseconds, so they are held to a looser tolerance than
  // the two point-source stars.
  const extendedTolerance = 0.1;
  const starTolerance = 0.02;

  const catalog = <CelestialTarget, (double, double, double, String)>{
    CelestialTarget.milkyWayCore: (
      266.41683,
      -29.00781,
      extendedTolerance,
      'Sgr A* (Galactic centre), SIMBAD',
    ),
    CelestialTarget.polaris: (
      37.95456,
      89.26411,
      starTolerance,
      'SIMBAD * alf UMi',
    ),
    CelestialTarget.sirius: (
      101.28716,
      -16.71612,
      starTolerance,
      'SIMBAD * alf CMa',
    ),
    CelestialTarget.orionNebula: (
      83.82208,
      -5.39111,
      extendedTolerance,
      'SIMBAD M 42',
    ),
    CelestialTarget.lagoonNebula: (
      270.925,
      -24.375,
      extendedTolerance,
      'SIMBAD M 8 (re-verified 2026-09-11)',
    ),
    CelestialTarget.eagleNebula: (
      274.7,
      -13.807,
      extendedTolerance,
      'SIMBAD M 16',
    ),
    CelestialTarget.andromedaGalaxy: (
      10.68471,
      41.26875,
      extendedTolerance,
      'SIMBAD M 31',
    ),
    CelestialTarget.triangulumGalaxy: (
      23.4621,
      30.6599,
      extendedTolerance,
      'SIMBAD M 33',
    ),
    CelestialTarget.bodeGalaxy: (
      148.8882,
      69.0653,
      extendedTolerance,
      'SIMBAD M 81',
    ),
    CelestialTarget.pleiades: (
      56.75,
      24.1167,
      extendedTolerance,
      'SIMBAD M 45',
    ),
    CelestialTarget.herculesCluster: (
      250.4235,
      36.4613,
      extendedTolerance,
      'SIMBAD M 13',
    ),
    CelestialTarget.omegaCentauri: (
      201.697,
      -47.4795,
      extendedTolerance,
      'SIMBAD NGC 5139',
    ),
  };

  test('every fixed catalog target matches its documented position', () {
    for (final entry in catalog.entries) {
      final target = entry.key;
      final (ra, dec, tolerance, source) = entry.value;
      expect(
        target.isMoving || target.isSolarLunar,
        isFalse,
        reason: '${target.label} must be a fixed catalog target ($source)',
      );
      expect(
        target.rightAscensionDegrees,
        closeTo(ra, tolerance),
        reason: '${target.label} RA drifted from $source',
      );
      expect(
        target.declinationDegrees,
        closeTo(dec, tolerance),
        reason: '${target.label} Dec drifted from $source',
      );
    }
  });

  test('the fixed catalog covers every non-moving target', () {
    final fixed = CelestialTarget.values
        .where((target) => !target.isMoving && !target.isSolarLunar)
        .toSet();
    expect(fixed, catalog.keys.toSet());
  });

  test('no moving or solar target returns its placeholder coordinates', () {
    // The planets and the Sun/Moon carry 0/0 placeholders in the enum; they must
    // always resolve through an ephemeris instead. The June solstice avoids the
    // March equinox, where the Sun's real position is legitimately near 0/0.
    final instant = DateTime.utc(2026, 6, 21, 12);
    for (final target in CelestialTarget.values) {
      if (!target.isMoving && !target.isSolarLunar) continue;
      final (ra, dec) = target.equatorialAt(instant);
      expect(ra.isFinite && dec.isFinite, isTrue, reason: target.label);
      expect(ra >= 0 && ra < 360, isTrue, reason: 'RA range');
      expect(dec >= -90 && dec <= 90, isTrue, reason: 'Dec range');
      expect(
        ra == 0 && dec == 0,
        isFalse,
        reason: '${target.label} fell back to the placeholder coordinates',
      );
    }
  });
}
