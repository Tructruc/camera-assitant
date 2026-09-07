# Astronomy fixture provenance

Fixtures use UTC, east-positive longitude, north-clockwise azimuth, and an airless geometric horizon.
Sidereal-time conventions follow the US Naval Observatory approximate GMST formulation. Reference target
ICRS/J2000 coordinates come from SIMBAD/CDS; observer azimuth/elevation semantics and comparison values use
NASA JPL Horizons observer tables. Tests allow 0.25° for fixed-target positions and two minutes for events,
which is planning-grade rather than observatory-grade accuracy.

The moving-planet fixture uses the JPL Horizons geocentric astrometric ICRF table for Jupiter at
2026-01-01 00:00 UTC (`COMMAND=599`, `CENTER=500@399`, quantity 1): RA 112.72933°, Dec 22.03458°.
Runtime planetary coordinates use JPL's published 1800-2050 approximate Keplerian elements and are
accepted within a conservative 0.25° planning tolerance.

Runtime code and the small coordinate catalog are original project code/data and do not copy SOFA or JPL
software. External services are used only to create and audit test fixtures, never while the app runs.

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
