/// One user-facing wording per persisted calculation warning code.
///
/// Warnings travel through snapshots as stable codes, so every surface that
/// renders them — live results and reopened saved plans — must map the same code
/// to the same sentence. Keeping the single map here prevents the wording from
/// drifting between the two paths, and a code without a specific sentence falls
/// back to a generic statement that still names it.
library;

String calculationWarningText(String code) => switch (code) {
  'solarSafety' =>
    'Solar safety: never look at the Sun through a camera, lens, viewfinder, binoculars, or telescope without a certified solar filter. This plan is an estimate, not a safety guarantee.',
  'planningAccuracy' =>
    'Planning-grade estimate: confirm the target and events against the real sky before relying on them.',
  'milkyWayOrientationUndefined' =>
    'The Milky Way orientation is unavailable within 0.1° of zenith or nadir.',
  'close_focus' =>
    'Close focus reduces the accuracy of the thin-lens estimate.',
  'sampling_visible' =>
    'The Airy disk spans at least two pixels at these settings, so diffraction is visible.',
  // The alignment search reuses the bare `sampling` code for its ten-minute
  // grid, so it needs its own sentence: the diffraction wording above would
  // otherwise appear on a Sun/Moon plan that has nothing to do with optics.
  'sampling' =>
    'Candidates are sampled every ten minutes; confirm the best window near the predicted time.',
  'frame_limit' =>
    'The focus stack reached the 1,000-frame planning limit. The far distance is included, but increase overlap or split the stack before shooting.',
  'exposure_exceeds_interval' =>
    'The calculated exposure is longer than the chosen capture interval.',
  'aperture_outside_typical_range' =>
    'The aperture is outside the typical range for this equipment.',
  'power_range' => 'Flash power is outside the supported range.',
  'configuration_estimate' =>
    'This macro configuration is an estimate; the stated model limitations apply.',
  'distortion' => 'Distortion and field curvature are not modeled.',
  'greater_than_near' =>
    'The far distance must be greater than the near distance.',
  'not_beyond_focal_length' =>
    'The distance must be greater than the focal length.',
  'positive_finite_required' => 'Enter a positive finite value.',
  'range' => 'Enter a value inside the supported range.',
  'plan_too_large' =>
    'These bounds need more than 2,000 frames. Reduce the coverage or use a wider lens.',
  'result_out_of_range' =>
    'These values produce a result outside the representable range. Reduce the extreme value and try again.',
  _ => 'This result reported a limitation ($code).',
};
