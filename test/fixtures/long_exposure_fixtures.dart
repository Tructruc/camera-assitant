/// Auditable fixtures for long-exposure and neutral-density calculations.
///
/// Canonical equations:
///
/// * filtered time: `tFiltered = tBase * 2 ^ totalStops`
/// * filter factor to stops: `stops = log2(factor)`
/// * optical density to stops: `stops = density * log2(10)`
/// * inverse strength: `requiredStops = log2(tTarget / tBase)`
///
/// Filter strengths stack by summing canonical stops. Input time is seconds;
/// optical density is the base-10 logarithm of attenuation. Raw results are
/// never rounded; conventional shutter text is display guidance only.
///
/// Reference basis: Nikon's long-exposure/ND guidance and exposure
/// fundamentals, linked from `specs/001-photography-assistant/research.md`,
/// establish that each stop doubles exposure time. Factor and optical-density
/// fixtures are independently derived from the definitions above. Numerical
/// assertions use a `1e-10` tolerance.
const longExposureTolerance = 1e-10;

final class LongExposureFixture {
  const LongExposureFixture({
    required this.name,
    required this.baseTimeSeconds,
    required this.filterStops,
    required this.totalStops,
    required this.filteredTimeSeconds,
  });

  final String name;
  final double baseTimeSeconds;
  final List<double> filterStops;
  final double totalStops;
  final double filteredTimeSeconds;
}

const longExposureFixtures = <LongExposureFixture>[
  LongExposureFixture(
    name: 'zero stops preserves base exposure',
    baseTimeSeconds: 0.5,
    filterStops: [],
    totalStops: 0,
    filteredTimeSeconds: 0.5,
  ),
  LongExposureFixture(
    name: 'one stop doubles exposure',
    baseTimeSeconds: 0.25,
    filterStops: [1],
    totalStops: 1,
    filteredTimeSeconds: 0.5,
  ),
  LongExposureFixture(
    name: 'stacked three and seven stops multiply by 1024',
    baseTimeSeconds: 1 / 30,
    filterStops: [3, 7],
    totalStops: 10,
    filteredTimeSeconds: 34.13333333333333,
  ),
];
