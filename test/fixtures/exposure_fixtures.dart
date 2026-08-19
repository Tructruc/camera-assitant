/// Auditable fixtures for exposure comparison.
///
/// Candidate exposure relative to baseline is expressed in stops as:
///
/// * aperture: `2 * log2(Nbaseline / Ncandidate)`
/// * shutter: `log2(tcandidate / tbaseline)`
/// * ISO: `log2(ISOcandidate / ISObaseline)`
/// * total: the sum of those three components
/// * multiplier: `2 ^ total`
///
/// Positive totals mean the candidate records more exposure (brighter),
/// negative totals mean less exposure (darker), and zero is equivalent.
/// Inputs use f-number, seconds, and ISO respectively.
///
/// Reference basis: Nikon's *A Basic Look at the Basics of Exposure*, linked
/// from `specs/001-photography-assistant/research.md`, describes aperture,
/// shutter speed, and ISO as exposure controls and a full stop as a doubling
/// or halving. Values below are independently derived from those base-2
/// relationships. Tests use a `1e-12` stop tolerance for floating-point math.
const exposureTolerance = 1e-12;

final class ExposureFixture {
  const ExposureFixture({
    required this.name,
    required this.baselineAperture,
    required this.baselineTimeSeconds,
    required this.baselineIso,
    required this.candidateAperture,
    required this.candidateTimeSeconds,
    required this.candidateIso,
    required this.apertureStops,
    required this.timeStops,
    required this.isoStops,
    required this.totalStops,
    required this.multiplier,
  });

  final String name;
  final double baselineAperture;
  final double baselineTimeSeconds;
  final double baselineIso;
  final double candidateAperture;
  final double candidateTimeSeconds;
  final double candidateIso;
  final double apertureStops;
  final double timeStops;
  final double isoStops;
  final double totalStops;
  final double multiplier;
}

const exposureFixtures = <ExposureFixture>[
  ExposureFixture(
    name: 'equal triples are exactly equivalent',
    baselineAperture: 4,
    baselineTimeSeconds: 0.008,
    baselineIso: 100,
    candidateAperture: 4,
    candidateTimeSeconds: 0.008,
    candidateIso: 100,
    apertureStops: 0,
    timeStops: 0,
    isoStops: 0,
    totalStops: 0,
    multiplier: 1,
  ),
  ExposureFixture(
    name: 'one stop wider aperture is twice the exposure',
    baselineAperture: 4,
    baselineTimeSeconds: 0.01,
    baselineIso: 100,
    candidateAperture: 2.8284271247461903,
    candidateTimeSeconds: 0.01,
    candidateIso: 100,
    apertureStops: 1,
    timeStops: 0,
    isoStops: 0,
    totalStops: 1,
    multiplier: 2,
  ),
  ExposureFixture(
    name: 'component changes can compensate exactly',
    baselineAperture: 4,
    baselineTimeSeconds: 0.008,
    baselineIso: 100,
    candidateAperture: 5.656854249492381,
    candidateTimeSeconds: 0.032,
    candidateIso: 50,
    apertureStops: -1,
    timeStops: 2,
    isoStops: -1,
    totalStops: 0,
    multiplier: 1,
  ),
];
