import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';

import '../../../fixtures/astronomy_fixtures.dart';

void main() {
  const calculator = AstronomyCalculator();

  test('places Sirius for the documented Greenwich fixture', () {
    final output = calculator.calculate(greenwichSiriusFixture).output!;
    expect(output.altitudeDegrees, closeTo(20.40, 0.25));
    expect(output.azimuthDegrees, closeTo(163.72, 0.25));
    expect(output.isAboveHorizon, isTrue);
    expect(
      output.events.map((event) => event.type),
      containsAll(CelestialEventType.values),
    );
  });

  test('identifies Polaris as circumpolar from Greenwich', () {
    final output = calculator
        .calculate(
          AstronomyInput(
            observerLatitudeDegrees: 51.4779,
            observerLongitudeDegrees: 0,
            instantUtc: DateTime.utc(2026, 1, 15, 22),
            target: CelestialTarget.polaris,
            focalLengthMm: 50,
            cropFactor: 1,
            aperture: 2,
            pixelPitchMicrometres: 5,
            desiredTrailDegrees: 15,
          ),
        )
        .output!;
    expect(output.visibilityCycle, VisibilityCycle.circumpolar);
    expect(output.events.map((event) => event.type), [
      CelestialEventType.transit,
    ]);
  });

  test('calculates 500, NPF, and star-trail guidance', () {
    final output = calculator.calculate(greenwichSiriusFixture).output!;
    expect(output.rule500Seconds, closeTo(20.833, 0.001));
    expect(output.npfSeconds, closeTo(10.333, 0.001));
    expect(output.trailDurationSeconds, closeTo(7180.34, 0.1));
    expect(output.recommendedShutterSeconds, closeTo(output.npfSeconds, 0.001));
    expect(output.path, hasLength(7));
    expect(
      output.path[3].altitudeDegrees,
      closeTo(output.altitudeDegrees, 0.001),
    );
  });

  test('selected rule and tolerance alter the recommendation', () {
    final strict = calculator
        .calculate(
          AstronomyInput(
            observerLatitudeDegrees: 51.4779,
            observerLongitudeDegrees: 0,
            instantUtc: DateTime.utc(2026, 1, 15, 22),
            target: CelestialTarget.sirius,
            focalLengthMm: 24,
            cropFactor: 1,
            aperture: 2,
            pixelPitchMicrometres: 5,
            desiredTrailDegrees: 30,
            selectedRule: StarShutterRule.rule500,
            sharpnessTolerance: StarSharpnessTolerance.strict,
          ),
        )
        .output!;
    expect(
      strict.recommendedShutterSeconds,
      closeTo(strict.rule500Seconds * 0.75, 0.001),
    );
  });

  test('ships a categorized offline deep-sky catalog', () {
    expect(CelestialTarget.values.length, greaterThanOrEqualTo(12));
    expect(
      CelestialTarget.values.map((target) => target.category).toSet(),
      containsAll(TargetCategory.values),
    );
  });

  test('catalog metadata declares provenance, epoch, and staleness', () {
    const metadata = AstronomyCatalogMetadata.current;
    expect(metadata.version, isNotEmpty);
    expect(metadata.provenance, contains('SIMBAD'));
    expect(metadata.supportedStartYear, 1800);
    expect(metadata.supportedEndYear, 2050);
    expect(
      metadata.freshnessAt(DateTime.utc(2026, 8, 29)),
      CatalogFreshness.current,
    );
    expect(
      metadata.freshnessAt(DateTime.utc(2028, 8, 29)),
      CatalogFreshness.stale,
    );
    expect(metadata.updatePolicy, contains('annual'));
  });

  test('moving planets change equatorial position over time', () {
    final first = CelestialTarget.jupiter.equatorialAt(
      DateTime.utc(2026, 1, 1),
    );
    final later = CelestialTarget.jupiter.equatorialAt(
      DateTime.utc(2026, 7, 1),
    );
    expect(first.$1, isNot(closeTo(later.$1, 0.01)));
    expect(first.$1, inInclusiveRange(0, 360));
    expect(first.$2, inInclusiveRange(-90, 90));
  });

  test('every planet agrees with its JPL Horizons fixture', () {
    // All five supported planets are pinned to geocentric astrometric ICRF
    // positions fetched from the JPL Horizons API on 2026-09-11 for
    // 2026-01-01 00:00 UTC. The declared planning tolerance is 0.25 degrees;
    // the measured deviations are far tighter (about 0.001 to 0.07 degrees).
    final instant = DateTime.utc(2026, 1, 1);
    final fixtures = <CelestialTarget, (double, double)>{
      CelestialTarget.mercury: (
        horizonsMercuryGeocentric.ra,
        horizonsMercuryGeocentric.dec,
      ),
      CelestialTarget.venus: (
        horizonsVenusGeocentric.ra,
        horizonsVenusGeocentric.dec,
      ),
      CelestialTarget.mars: (
        horizonsMarsGeocentric.ra,
        horizonsMarsGeocentric.dec,
      ),
      CelestialTarget.jupiter: (
        horizonsJupiterGeocentric.ra,
        horizonsJupiterGeocentric.dec,
      ),
      CelestialTarget.saturn: (
        horizonsSaturnGeocentric.ra,
        horizonsSaturnGeocentric.dec,
      ),
    };
    for (final entry in fixtures.entries) {
      final (ra, dec) = entry.key.equatorialAt(instant);
      final (expectedRa, expectedDec) = entry.value;
      expect(
        ra,
        closeTo(expectedRa, 0.25),
        reason: '${entry.key.label} RA outside the declared tolerance',
      );
      expect(
        dec,
        closeTo(expectedDec, 0.25),
        reason: '${entry.key.label} Dec outside the declared tolerance',
      );
    }
    // The inner planets are exact enough to hold to a tenth of the claim.
    final mercury = CelestialTarget.mercury.equatorialAt(instant);
    final venus = CelestialTarget.venus.equatorialAt(instant);
    final mars = CelestialTarget.mars.equatorialAt(instant);
    expect(mercury.$1, closeTo(horizonsMercuryGeocentric.ra, 0.02));
    expect(venus.$1, closeTo(horizonsVenusGeocentric.ra, 0.02));
    expect(mars.$1, closeTo(horizonsMarsGeocentric.ra, 0.02));
  });

  test('moving-planet events are solved against the live ephemeris', () {
    final input = AstronomyInput(
      observerLatitudeDegrees: 51.4779,
      observerLongitudeDegrees: 0,
      instantUtc: DateTime.utc(2026, 8, 26),
      target: CelestialTarget.mercury,
      focalLengthMm: 200,
      cropFactor: 1,
      aperture: 4,
      pixelPitchMicrometres: 4,
      desiredTrailDegrees: 10,
    );
    final result = calculator.calculate(input);
    final horizonEvents = result.output!.events.where(
      (event) => event.type != CelestialEventType.transit,
    );
    expect(horizonEvents, hasLength(2));
    for (final event in horizonEvents) {
      final atEvent = calculator
          .calculate(
            AstronomyInput(
              observerLatitudeDegrees: input.observerLatitudeDegrees,
              observerLongitudeDegrees: input.observerLongitudeDegrees,
              instantUtc: event.instantUtc,
              target: input.target,
              focalLengthMm: input.focalLengthMm,
              cropFactor: input.cropFactor,
              aperture: input.aperture,
              pixelPitchMicrometres: input.pixelPitchMicrometres,
              desiredTrailDegrees: input.desiredTrailDegrees,
            ),
          )
          .output!;
      expect(atEvent.altitudeDegrees, closeTo(0, 0.02));
    }
    expect(
      result.assumptions.first.value,
      contains('JPL 1800-2050 approximate Keplerian'),
    );
  });

  test('rejects invalid location, optics, and trail inputs', () {
    final result = calculator.calculate(
      AstronomyInput(
        observerLatitudeDegrees: 91,
        observerLongitudeDegrees: 181,
        instantUtc: DateTime.utc(2026),
        target: CelestialTarget.sirius,
        focalLengthMm: 0,
        cropFactor: -1,
        aperture: double.nan,
        pixelPitchMicrometres: 0,
        desiredTrailDegrees: 361,
      ),
    );
    expect(result.output, isNull);
    expect(result.errors, hasLength(7));
  });
}
