/// Copyable text for a saved calculation: a human field brief and the exact
/// stored JSON.
///
/// Everything here is pure. It reads an immutable [CalculationSnapshot] plus the
/// presentation strings the saved screen already formats, and returns text: no
/// widget, no `BuildContext`, no current preferences. It never recalculates a
/// physical result, and it never invents a unit for a canonical key it does not
/// recognise - an unrecognised key is copied verbatim, so a payload written by a
/// newer build is shared honestly instead of being mislabelled.
library;

import 'dart:convert';

import '../../../core/domain/calculation_snapshot.dart';

/// The human name of a saved tool.
///
/// Shared by the library rows and the field brief so both surfaces name a tool
/// the same way. An unrecognised id is returned unchanged: a payload written by
/// a build whose catalog is wider is named by its own id rather than relabelled.
String savedCalculationToolLabel(String calculatorId) => switch (calculatorId) {
  'depth_of_field' => 'Depth of field',
  'exposure_comparison' => 'Exposure comparison',
  'long_exposure_nd' => 'Long exposure / ND',
  'field_of_view' => 'Field of view',
  'diffraction' => 'Diffraction guidance',
  'focus_stacking' => 'Focus stack planner',
  'flash_exposure' => 'Flash exposure',
  'timelapse' => 'Timelapse planner',
  'macro' => 'Macro planner',
  'panorama' => 'Panorama planner',
  'astronomy' => 'Night-sky planner',
  'sun_moon_alignment' => 'Sun & Moon alignment',
  _ => calculatorId,
};

/// A human label and the unit a canonical key honestly carries.
///
/// [unit] is empty when the value is unitless or already self-describing (an
/// enum name, an ISO instant, an ISO number). `f-number` renders as `f/2.8`;
/// `×`, `%` and `°` bind to the number; anything else is printed after a space.
final class SavedCalculationValueLabel {
  const SavedCalculationValueLabel(this.label, [this.unit = '']);

  final String label;
  final String unit;
}

/// Canonical input keys whose unit is unambiguous from the key itself.
///
/// Only keys listed here are labelled and given a unit. Every other key is
/// printed verbatim as `key: value`, because guessing a unit for an unknown
/// payload key would put a false physical claim into a plan someone else reads.
/// The labels below cover every key the shipped calculators write.
const Map<String, SavedCalculationValueLabel>
savedCalculationValueLabels = <String, SavedCalculationValueLabel>{
  // Depth of field.
  'focalLengthMm': SavedCalculationValueLabel('Focal length', 'mm'),
  'aperture': SavedCalculationValueLabel('Aperture', 'f-number'),
  'focusDistanceMm': SavedCalculationValueLabel('Focus distance', 'mm'),
  'circleOfConfusionMm': SavedCalculationValueLabel(
    'Circle of confusion',
    'mm',
  ),
  // Long exposure and ND filters.
  'baseTimeSeconds': SavedCalculationValueLabel('Base exposure', 's'),
  'filterStops': SavedCalculationValueLabel('Filter strength', 'stops'),
  'targetTimeSeconds': SavedCalculationValueLabel('Target exposure', 's'),
  'strengthStops': SavedCalculationValueLabel('Filter strength', 'stops'),
  'opticalDensity': SavedCalculationValueLabel('Optical density'),
  'filterFactor': SavedCalculationValueLabel('Filter factor'),
  // Exposure comparison: two labelled A/B groups of the same three keys.
  'baseline': SavedCalculationValueLabel('Baseline'),
  'candidate': SavedCalculationValueLabel('Candidate'),
  'timeSeconds': SavedCalculationValueLabel('Time', 's'),
  'iso': SavedCalculationValueLabel('ISO'),
  // Flash exposure.
  'guideNumberIso100Metres': SavedCalculationValueLabel(
    'Guide number (ISO 100)',
    'm',
  ),
  'powerFraction': SavedCalculationValueLabel('Flash power (fraction)'),
  'subjectDistanceMetres': SavedCalculationValueLabel('Subject distance', 'm'),
  // Optics: field of view, diffraction, focus stacking.
  'sensorWidthMm': SavedCalculationValueLabel('Sensor width', 'mm'),
  'sensorHeightMm': SavedCalculationValueLabel('Sensor height', 'mm'),
  'distanceMm': SavedCalculationValueLabel('Subject distance', 'mm'),
  'wavelengthNm': SavedCalculationValueLabel('Wavelength', 'nm'),
  'pixelPitchMicrometres': SavedCalculationValueLabel('Pixel pitch', 'µm'),
  'nearDistanceMm': SavedCalculationValueLabel('Near distance', 'mm'),
  'farDistanceMm': SavedCalculationValueLabel('Far distance', 'mm'),
  'overlapPercent': SavedCalculationValueLabel('Overlap', '%'),
  // Timelapse.
  'intervalSeconds': SavedCalculationValueLabel('Interval', 's'),
  'captureDurationSeconds': SavedCalculationValueLabel('Capture duration', 's'),
  'playbackFps': SavedCalculationValueLabel('Playback frame rate', 'fps'),
  'megabytesPerFrame': SavedCalculationValueLabel(
    'Estimated size per frame',
    'MB',
  ),
  'startExposureSeconds': SavedCalculationValueLabel('Starting exposure', 's'),
  'endExposureSeconds': SavedCalculationValueLabel('Ending exposure', 's'),
  // Macro.
  'configuration': SavedCalculationValueLabel('Configuration'),
  'extensionLengthMm': SavedCalculationValueLabel('Extension length', 'mm'),
  'nativeMagnification': SavedCalculationValueLabel(
    'Native magnification',
    '×',
  ),
  'nominalAperture': SavedCalculationValueLabel('Nominal aperture', 'f-number'),
  'reversedFocalLengthMm': SavedCalculationValueLabel(
    'Reversed lens focal length',
    'mm',
  ),
  'flangeDistanceMm': SavedCalculationValueLabel('Flange distance', 'mm'),
  'primaryFocalLengthMm': SavedCalculationValueLabel(
    'Primary lens focal length',
    'mm',
  ),
  // Panorama.
  'orientation': SavedCalculationValueLabel('Orientation'),
  'horizontalBoundsDegrees': SavedCalculationValueLabel(
    'Horizontal bounds',
    '°',
  ),
  'verticalBoundsDegrees': SavedCalculationValueLabel('Vertical bounds', '°'),
  'horizontalOverlapPercent': SavedCalculationValueLabel(
    'Horizontal overlap',
    '%',
  ),
  'verticalOverlapPercent': SavedCalculationValueLabel('Vertical overlap', '%'),
  // Sun & Moon alignment.
  'body': SavedCalculationValueLabel('Body'),
  'observerLatitudeDegrees': SavedCalculationValueLabel(
    'Observer latitude',
    '°',
  ),
  'observerLongitudeDegrees': SavedCalculationValueLabel(
    'Observer longitude',
    '°',
  ),
  'observerElevationMetres': SavedCalculationValueLabel(
    'Observer elevation',
    'm',
  ),
  'targetElevationMetres': SavedCalculationValueLabel('Target elevation', 'm'),
  'targetDistanceMetres': SavedCalculationValueLabel('Target distance', 'm'),
  'desiredBearingDegrees': SavedCalculationValueLabel('Desired bearing', '°'),
  'targetLatitudeDegrees': SavedCalculationValueLabel('Target latitude', '°'),
  'targetLongitudeDegrees': SavedCalculationValueLabel('Target longitude', '°'),
  'angularToleranceDegrees': SavedCalculationValueLabel(
    'Angular tolerance',
    '°',
  ),
  'magneticDeclinationDegrees': SavedCalculationValueLabel(
    'Magnetic declination',
    '°',
  ),
  'startLocalDate': SavedCalculationValueLabel('Search start date'),
  'endLocalDate': SavedCalculationValueLabel('Search end date'),
  'startUtc': SavedCalculationValueLabel('Search window start (UTC)'),
  'endUtc': SavedCalculationValueLabel('Search window end (UTC)'),
  // Night-sky planning.
  'latitudeDegrees': SavedCalculationValueLabel('Latitude', '°'),
  'longitudeDegrees': SavedCalculationValueLabel('Longitude', '°'),
  'instantUtc': SavedCalculationValueLabel('Planned instant (UTC)'),
  'target': SavedCalculationValueLabel('Target'),
  'rightAscensionDegrees': SavedCalculationValueLabel('Right ascension', '°'),
  'declinationDegrees': SavedCalculationValueLabel('Declination', '°'),
  'cropFactor': SavedCalculationValueLabel('Crop factor'),
  'desiredTrailDegrees': SavedCalculationValueLabel('Desired star trail', '°'),
  'selectedRule': SavedCalculationValueLabel('Shutter rule'),
  'sharpnessTolerance': SavedCalculationValueLabel('Sharpness tolerance'),
};

/// A canonical value as plain text: a finite number without a trailing `.0`,
/// `yes`/`no` for a flag, JSON for a list or map, and `not recorded` for null.
String savedCalculationValueText(Object? value) => switch (value) {
  null => 'not recorded',
  final num number when number.isFinite => _numberText(number),
  final bool flag => flag ? 'yes' : 'no',
  final List<Object?> list => jsonEncode(list),
  final Map<String, Object?> map => jsonEncode(map),
  _ => '$value',
};

String _numberText(num number) {
  if (number == 0) return '0';
  if (number == number.roundToDouble() && number.abs() < 1e15) {
    return number.toStringAsFixed(0);
  }
  return number.toString();
}

/// Formats canonical input values as human lines with honest units.
///
/// A key in [savedCalculationValueLabels] is labelled and given the unit the key
/// itself declares. Every other key is printed verbatim as `key: value` with no
/// unit invented for it. A nested map (the exposure comparison's `baseline` and
/// `candidate`) becomes `Group · Label` lines; a list is printed as one JSON
/// line instead of being interpreted. A null optional value reads
/// `not recorded`.
///
/// [skip] omits top-level keys the caller already presents elsewhere, such as
/// the field brief's own observation block. Nothing is recomputed here.
List<String> savedCalculationRecordedValues(
  Map<String, Object?> values, {
  Set<String> skip = const <String>{},
}) {
  final lines = <String>[];
  _collectRecordedValues(values, skip: skip, group: null, into: lines);
  return List<String>.unmodifiable(lines);
}

void _collectRecordedValues(
  Map<String, Object?> values, {
  required Set<String> skip,
  required String? group,
  required List<String> into,
}) {
  for (final entry in values.entries) {
    if (group == null && skip.contains(entry.key)) continue;
    final value = entry.value;
    if (value is Map<String, Object?>) {
      _collectRecordedValues(
        value,
        skip: const <String>{},
        group: _qualifiedLabel(group, entry.key),
        into: into,
      );
      continue;
    }
    into.add(_recordedLine(group, entry.key, value));
  }
}

String _qualifiedLabel(String? group, String key) {
  final label = savedCalculationValueLabels[key]?.label ?? key;
  return group == null ? label : '$group · $label';
}

String _recordedLine(String? group, String key, Object? value) {
  final label = _qualifiedLabel(group, key);
  if (value == null) return '$label: not recorded';
  final text = savedCalculationValueText(value);
  final known = savedCalculationValueLabels[key];
  // A unit is only appended to a finite number: a string the calculator wrote
  // (an enum name, an ISO instant) already describes itself.
  if (known == null || value is! num || !value.isFinite) {
    return '$label: $text';
  }
  return '$label: ${_withUnit(text, known.unit)}';
}

String _withUnit(String text, String unit) => switch (unit) {
  '' => text,
  'f-number' => 'f/$text',
  '×' => '$text×',
  '%' => '$text%',
  '°' => '$text°',
  _ => '$text $unit',
};

/// The observation block of a field brief.
///
/// The wording comes from the plan that was saved - its own site, instant and
/// zone - never from the current global preferences.
final class SavedCalculationObservationBrief {
  const SavedCalculationObservationBrief({
    required this.site,
    required this.zone,
    this.time,
    this.reference,
  });

  final String site;

  /// The saved instant or window in the recorded zone's wording, or null when
  /// the payload carries no instant at all.
  final String? time;

  /// The recorded zone, or `UTC` when the plan recorded none.
  final String zone;

  /// The recorded north/azimuth reference, when the plan recorded one.
  final String? reference;
}

/// Everything the field brief prints, already formatted.
///
/// The saved screen owns the wording - the hero answer, its unit, the warning
/// sentences - and passes it in, so this builder never recomputes a physical
/// result and never re-reads a preference.
final class SavedCalculationBriefInput {
  const SavedCalculationBriefInput({
    required this.title,
    required this.toolLabel,
    required this.savedDate,
    required this.primaryLabel,
    required this.primaryValue,
    this.primaryCaption,
    this.notes,
    this.recordedInputs = const <String>[],
    this.warnings = const <String>[],
    this.assumptions = const <String>[],
    this.observation,
    this.equipment = const <String>[],
  });

  final String title;
  final String toolLabel;
  final String savedDate;
  final String primaryLabel;

  /// The primary answer including its unit, exactly as the saved screen shows
  /// it.
  final String primaryValue;
  final String? primaryCaption;
  final String? notes;
  final List<String> recordedInputs;
  final List<String> warnings;
  final List<String> assumptions;
  final SavedCalculationObservationBrief? observation;
  final List<String> equipment;
}

/// Builds the copyable field brief as plain text.
///
/// A section whose record carries nothing is omitted rather than printed empty,
/// so a plan saved before a field existed reads as a shorter brief instead of a
/// list of blanks.
String buildSavedCalculationBrief(SavedCalculationBriefInput input) {
  final buffer = StringBuffer();
  buffer.writeln('Field brief — ${input.title}');
  buffer.writeln('${input.toolLabel} · saved ${input.savedDate}');
  buffer.writeln('${input.primaryLabel}: ${input.primaryValue}');
  final caption = input.primaryCaption;
  if (caption != null && caption.trim().isNotEmpty) {
    buffer.writeln(caption);
  }
  final notes = input.notes;
  if (notes != null && notes.trim().isNotEmpty) {
    _writeSection(buffer, 'Notes', <String>[notes]);
  }
  _writeSection(buffer, 'Recorded inputs', _bulleted(input.recordedInputs));
  _writeSection(buffer, 'Warnings', _bulleted(input.warnings));
  _writeSection(buffer, 'Assumptions', _bulleted(input.assumptions));
  final observation = input.observation;
  if (observation != null) {
    _writeSection(buffer, 'Observation', <String>[
      'Site: ${observation.site}',
      if (observation.time case final time?) 'Time: $time',
      'Zone: ${observation.zone}',
      if (observation.reference case final reference?) 'Reference: $reference',
    ]);
  }
  _writeSection(buffer, 'Equipment', _bulleted(input.equipment));
  return buffer.toString();
}

List<String> _bulleted(List<String> lines) => <String>[
  for (final line in lines) '- $line',
];

void _writeSection(StringBuffer buffer, String heading, List<String> lines) {
  if (lines.isEmpty) return;
  buffer
    ..writeln()
    ..writeln(heading);
  for (final line in lines) {
    buffer.writeln(line);
  }
}

/// The stored record exactly as it was saved, pretty-printed for a person to
/// read.
///
/// This is [CalculationSnapshot.toJson] and nothing else: every canonical value,
/// id, payload/formula version, equipment entry, note, assumption and saved
/// observation input survives, and the text round-trips through
/// [CalculationSnapshot.fromJson]. Session-only state (a checklist tick made
/// while reading) is never part of the snapshot and so can never appear here.
String buildSavedCalculationExactJson(CalculationSnapshot snapshot) =>
    const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
