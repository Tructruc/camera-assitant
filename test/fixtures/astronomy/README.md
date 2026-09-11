# Astronomy fixture provenance

Fixtures use UTC, east-positive longitude, north-clockwise azimuth, and an airless geometric horizon.
Sidereal-time conventions follow the US Naval Observatory approximate GMST formulation. Reference target
ICRS/J2000 coordinates come from SIMBAD/CDS; observer azimuth/elevation semantics and comparison values use
NASA JPL Horizons observer tables. Tests allow 0.25° for fixed-target positions and two minutes for events,
which is planning-grade rather than observatory-grade accuracy.

The moving-planet fixtures use the JPL Horizons geocentric astrometric ICRF table. Jupiter at
2026-01-01 00:00 UTC (`COMMAND=599`, `CENTER=500@399`, quantity 1): RA 112.72933°, Dec 22.03458°.
Runtime planetary coordinates use JPL's published 1800-2050 approximate Keplerian elements and are
accepted within a conservative 0.25° planning tolerance. Jupiter, Mars, and Saturn are pinned to
Horizons values for all five supported planets (Mercury, Venus, Mars, Jupiter, Saturn), so the 0.25 degree
claim is externally checked in both the inner and outer solar system.

Runtime code and the small coordinate catalog are original project code/data and do not copy SOFA or JPL
software. External services are used only to create and audit test fixtures, never while the app runs.

## Sun, Moon, and Sirius references

`test/fixtures/astronomy_fixtures.dart` records the exact query behind each value, and
`test/unit/features/astronomy/solar_lunar_fixture_test.dart` asserts them:

| Fixture | Source and query | Retrieved value | Asserted tolerance |
|---------|------------------|-----------------|--------------------|
| `horizonsSunGeocentric` | JPL Horizons geocentric airless apparent Sun, 2026-03-20 12:00 UTC, `COMMAND=10`, `CENTER=500@399`, `QUANTITIES=2` | RA 359.894843697°, Dec −0.045488014° | 0.25° |
| `horizonsMoonGeocentric` | JPL Horizons geocentric airless apparent Moon, 2026-06-01 00:00 UTC, `COMMAND=301`, `CENTER=500@399`, `QUANTITIES=2` | RA 255.881235454°, Dec −27.674687081° | 2.0° (lunar series) |
| `horizonsSunTopocentric` | JPL Horizons observer table, Greenwich `SITE_COORD=0,51.4779,0`, 2026-03-20 12:00 UTC, `QUANTITIES=4`, `APPARENT=AIRLESS` | az 177.626176859°, alt 38.450718735° | 0.25° |
| `horizonsMoonTopocentric` | JPL Horizons observer table, Greenwich, 2026-06-01 00:00 UTC | az 174.247568346°, alt 9.763824493° | 2.0° |
| `simbadSiriusIcrs` | SIMBAD TAP, `* alf CMa` ICRS J2000 | RA 101.28715533°, Dec −16.71611586° | 0.01° |
| `horizonsMarsGeocentric` | JPL Horizons geocentric astrometric ICRF Mars, 2026-01-01 00:00 UTC, `COMMAND=499`, `CENTER=500@399`, `QUANTITIES=1` | RA 283.489041°, Dec −23.751667° | 0.25° (measured 0.001°) |
| `horizonsSaturnGeocentric` | JPL Horizons geocentric astrometric ICRF Saturn, 2026-01-01 00:00 UTC, `COMMAND=699` | RA 357.047125°, Dec −3.740667° | 0.25° (measured 0.07°) |
| `horizonsJupiterGeocentric` | JPL Horizons geocentric astrometric ICRF Jupiter, 2026-01-01 00:00 UTC, `COMMAND=599` | RA 112.72933°, Dec 22.03458° | 0.25° |
| `horizonsMercuryGeocentric` | JPL Horizons geocentric astrometric ICRF Mercury, 2026-01-01 00:00 UTC, `COMMAND=199` | RA 268.131083°, Dec −23.994889° | 0.25° (measured 0.005°) |
| `horizonsVenusGeocentric` | JPL Horizons geocentric astrometric ICRF Venus, 2026-01-01 00:00 UTC, `COMMAND=299` | RA 279.665458°, Dec −23.644694° | 0.25° (measured 0.006°) |
| `usnoGreenwichSun` | USNO Astronomical Applications one-day table, Greenwich, 2026-03-20, `tz=0` | rise 06:03, transit 12:07, set 18:13 UTC | 2 min (transit) |
| `usnoGreenwichMoon` | USNO one-day table, Greenwich, 2026-03-20, `tz=0` | rise 06:16, transit 13:15, set 20:35 UTC | 10 min (transit), 20 min (rise/set) |

The planner reports an airless geometric horizon, while published rise and set times apply standard
refraction and the solar semidiameter (−0.8333° for the Sun). The fixture test therefore asserts the
model's altitude at the published solar rise/set instants is −0.8333° instead of comparing the crossing
times directly. Lunar rise and set use the USNO lunar horizon convention, so only the meridian transit is
asserted tightly. Circumpolar and never-rises boundaries are covered at ±80° latitude on the June
solstice.

## Milky Way orientation (astronomy formula version 2)

The local band axis is the tangent to constant Galactic latitude at the catalog core position
(RA 266.41683°, Dec −29.00781°). It approximates the plane near the core, not the curved appearance
of the entire Milky Way. The adopted J2000 north Galactic pole is RA 192.85948°, Dec 27.12825°,
consistent with the rounded [Astropy Galactic-frame constants](https://raw.githubusercontent.com/astropy/astropy/main/astropy/coordinates/builtin_frames/galactic.py).
These coordinate facts are used by original project code; no Astropy runtime or source is bundled.

The result is an undirected angle in `[0, 180)` relative to the local horizon in a level, unmirrored
view looking toward the core: zero is horizontal, 90° is vertical, and the angle increases upward
from image right. Angles below 90° rise to the right; angles above 90° rise to the left.
Below-horizon values are mathematical projections, not visible compositions. Within 0.1° of
zenith or nadir the result is null with an explicit warning. Camera roll, refraction, terrain and
precession are excluded; model agreement does not establish an observational angle-error bound.

Production code projects the Cartesian tangent `pole × core` onto equal-length image-right
`core × zenith` and image-up `(core × zenith) × core` vectors. Fixtures were independently computed
with spherical position angles (all trigonometric arguments in radians):

```text
p = atan2(sin(RA_pole − RA_core),
          cos(Dec_core) tan(Dec_pole) − sin(Dec_core) cos(RA_pole − RA_core))
H = GMST + east_longitude − RA_core
q = atan2(cos(latitude) sin(H),
          sin(latitude) cos(Dec_core) − cos(latitude) sin(Dec_core) cos(H))
orientation = degrees(p − q) modulo 180
```

GMST uses the existing documented USNO mean-sidereal-time convention. Frozen values, accepted
within 0.00001° for numerical agreement between these two derivations, are:

| Location (latitude, longitude) | UTC instant | Orientation |
|---|---|---:|
| Greenwich (51.4779, 0) | 2026-07-01 22:00 | 131.660662° |
| Greenwich (51.4779, 0) | 2026-07-02 02:00 | 95.899654° |
| Sydney (−33.8688, 151.2093) | 2026-07-01 12:00 | 55.381327° |
| Equator (0, 0) | 2026-07-01 22:00 | 152.732536° |
| Greenwich, below horizon | 2026-07-01 10:00 | 96.733879° |
| North/south pole (±90, 0) | 2026-07-01 22:00 | 121.395578° |

At J2000 noon GMST is 280.46061837°. Latitude −29.00781°, longitude −14.04378837°
places the core at zenith; its antipode places it at nadir. Tests cover these exact singularities,
points within/outside the exclusion radius, a full day's axis wrapping, the date line, and omission
for other celestial targets. Display rounds to one decimal place; snapshots retain full precision,
the angle convention, model limitations, formula version, and null when unavailable.

## Moving-body events

`test/unit/features/astronomy/astronomy_calculator_test.dart` asserts Jupiter's Greenwich events against a
Horizons rise/transit/set table for 2026-01-15 (one-minute search step): the app's altitude at the published
rise and set markers matches Horizons' refraction offset within 0.25 degrees, and the transit instant
matches within the marker's own accuracy. The comparison is deliberately framed that way because the app
resolves a geometric horizon while Horizons reports a refracted one, so the published rise and set *times*
differ by several minutes even though the underlying geometry agrees. Sun and Moon events are asserted
against USNO one-day tables in `solar_lunar_fixture_test.dart`.

## Bundled fixed-target catalog

The twelve fixed targets ship ICRS/J2000 positions that are attributed to SIMBAD/CDS. Their values are
pinned in `test/unit/features/astronomy/catalog_reference_test.dart`, which fails if a catalog coordinate
is edited without updating its documented reference, and which also asserts that the planets and the
Sun/Moon never fall back to the 0/0 placeholders they carry in the enum. On 2026-09-11 the Lagoon Nebula
entry was re-queried against SIMBAD
([`NAME Lagoon Nebula`](https://simbad.cds.unistra.fr/simbad/sim-id?Ident=NAME+Lagoon+Nebula)), which
returns ICRS J2000 `18 03 37.0 -24 23 12` with quality flag E (>= 10 arcsec); the shipped position is
within 0.03 degrees of it. Extended objects carry a looser tolerance than the two catalog stars because
their published positions legitimately differ between sources.
