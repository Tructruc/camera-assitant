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
