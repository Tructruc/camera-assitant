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

/// Builds a Greenwich planning input for the externally traceable fixtures.
AstronomyInput greenwichFixture({
  required CelestialTarget target,
  required DateTime instantUtc,
  double latitudeDegrees = 51.4779,
}) => AstronomyInput(
  observerLatitudeDegrees: latitudeDegrees,
  observerLongitudeDegrees: 0,
  instantUtc: instantUtc,
  target: target,
  focalLengthMm: 24,
  cropFactor: 1,
  aperture: 2.8,
  pixelPitchMicrometres: 5,
  desiredTrailDegrees: 30,
);

/// NASA JPL Horizons geocentric airless-apparent solar coordinates for
/// 2026-03-20 12:00 UTC (`COMMAND=10`, `CENTER=500@399`, `QUANTITIES=2`).
const horizonsSunGeocentric = (ra: 359.894843697, dec: -0.045488014);

/// NASA JPL Horizons geocentric airless-apparent lunar coordinates for
/// 2026-06-01 00:00 UTC (`COMMAND=301`, `CENTER=500@399`, `QUANTITIES=2`).
const horizonsMoonGeocentric = (ra: 255.881235454, dec: -27.674687081);

/// NASA JPL Horizons topocentric airless-apparent solar azimuth/elevation for
/// Greenwich (51.4779 N, 0 E) at 2026-03-20 12:00 UTC
/// (`SITE_COORD=0,51.4779,0`, `QUANTITIES=4`, `APPARENT=AIRLESS`).
const horizonsSunTopocentric = (azimuth: 177.626176859, altitude: 38.450718735);

/// NASA JPL Horizons topocentric airless-apparent lunar azimuth/elevation for
/// Greenwich at 2026-06-01 00:00 UTC.
const horizonsMoonTopocentric = (azimuth: 174.247568346, altitude: 9.763824493);

/// SIMBAD/CDS ICRS J2000 position of `* alf CMa` (Sirius), queried through the
/// SIMBAD TAP service: RA 101.28715533°, Dec −16.71611586°.
const simbadSiriusIcrs = (ra: 101.28715533333, dec: -16.71611586111);

/// USNO Astronomical Applications one-day table for Greenwich on 2026-03-20
/// with `tz=0`, in UTC. Sunrise/sunset include standard refraction and the
/// solar semidiameter; the transit is the geometric meridian crossing.
const usnoGreenwichSun = (rise: '06:03', transit: '12:07', set: '18:13');

/// USNO one-day table for Greenwich on 2026-03-20 with `tz=0`, in UTC. Lunar
/// rise/set use the USNO lunar horizon convention, not a geometric zero
/// altitude.
const usnoGreenwichMoon = (rise: '06:16', transit: '13:15', set: '20:35');

/// NASA JPL Horizons geocentric astrometric ICRF position of Mars for
/// 2026-01-01 00:00 UTC (`COMMAND=499`, `CENTER=500@399`, `QUANTITIES=1`,
/// `CSV_FORMAT=YES`): RA 18 53 57.37, Dec -23 45 06.0.
const horizonsMarsGeocentric = (ra: 283.489041, dec: -23.751667);

/// NASA JPL Horizons geocentric astrometric ICRF position of Saturn for
/// 2026-01-01 00:00 UTC (`COMMAND=699`, same settings): RA 23 48 11.31,
/// Dec -03 44 26.4.
const horizonsSaturnGeocentric = (ra: 357.047125, dec: -3.740667);

/// NASA JPL Horizons geocentric astrometric ICRF position of Jupiter for
/// 2026-01-01 00:00 UTC (`COMMAND=599`, `CENTER=500@399`, `QUANTITIES=1`):
/// RA 07 30 55.04, Dec +22 02 04.5.
const horizonsJupiterGeocentric = (ra: 112.72933, dec: 22.03458);

/// NASA JPL Horizons geocentric astrometric ICRF position of Mercury for
/// 2026-01-01 00:00 UTC (`COMMAND=199`, same settings): RA 17 52 31.46,
/// Dec -23 59 41.6.
const horizonsMercuryGeocentric = (ra: 268.131083, dec: -23.994889);

/// NASA JPL Horizons geocentric astrometric ICRF position of Venus for
/// 2026-01-01 00:00 UTC (`COMMAND=299`, same settings): RA 18 38 39.71,
/// Dec -23 38 40.9.
const horizonsVenusGeocentric = (ra: 279.665458, dec: -23.644694);
