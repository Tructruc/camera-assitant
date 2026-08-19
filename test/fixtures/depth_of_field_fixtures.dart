/// Auditable fixtures for the thin-lens depth-of-field calculator.
///
/// Formula convention (all distances in millimetres):
///
/// * `H = f² / (N c) + f`
/// * `Dnear = s (H - f) / (H + s - 2f)`
/// * `Dfar = s (H - f) / (H - s)` when `s < H`, otherwise infinity
/// * finite total depth is `Dfar - Dnear`
///
/// Here `f` is focal length, `N` the f-number, `c` circle of confusion,
/// and `s` focus distance measured from the lens principal plane. The model
/// assumes a thin lens and geometric circle-of-confusion criterion; it does
/// not model pupil magnification, diffraction, focus breathing, or viewing
/// enlargement.
///
/// Reference basis:
/// Carl Zeiss Camera Lens Division, *Depth of Field and Bokeh* (2010), and
/// Zeiss Cinema Zoom 70–200 mm depth-of-field tables, linked from
/// `specs/001-photography-assistant/research.md`. Expected values below are
/// independently evaluated from the declared equations rather than copied
/// from rounded display tables.
///
/// The tolerance is 0.01 mm for equation fixtures. This is tighter than any
/// user-facing rounding and only accommodates binary floating-point error.
const depthOfFieldToleranceMm = 0.01;

final class DepthOfFieldFixture {
  const DepthOfFieldFixture({
    required this.name,
    required this.focalLengthMm,
    required this.aperture,
    required this.focusDistanceMm,
    required this.circleOfConfusionMm,
    required this.hyperfocalDistanceMm,
    required this.nearLimitMm,
    required this.farLimitMm,
  });

  final String name;
  final double focalLengthMm;
  final double aperture;
  final double focusDistanceMm;
  final double circleOfConfusionMm;
  final double hyperfocalDistanceMm;
  final double nearLimitMm;
  final double? farLimitMm;
}

const depthOfFieldFixtures = <DepthOfFieldFixture>[
  DepthOfFieldFixture(
    name: '50 mm at f/8 focused at 10 m',
    focalLengthMm: 50,
    aperture: 8,
    focusDistanceMm: 10000,
    circleOfConfusionMm: 0.03,
    hyperfocalDistanceMm: 10466.666666666666,
    nearLimitMm: 5114.566284779051,
    farLimitMm: 223214.2857142857,
  ),
  DepthOfFieldFixture(
    name: '35 mm at f/11 focused at hyperfocal',
    focalLengthMm: 35,
    aperture: 11,
    focusDistanceMm: 3747.121212121212,
    circleOfConfusionMm: 0.03,
    hyperfocalDistanceMm: 3747.121212121212,
    nearLimitMm: 1873.5606060606062,
    farLimitMm: null,
  ),
];
