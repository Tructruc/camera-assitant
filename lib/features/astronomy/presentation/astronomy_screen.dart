import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/domain/validation/validation.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../../equipment/presentation/equipment_specs.dart';
import '../../planning/domain/planning_capabilities.dart';
import '../../planning/domain/planning_time_context.dart';
import '../../planning/domain/saved_location.dart';
import '../../planning/presentation/field_checklist.dart';
import '../../planning/presentation/live_ar_view.dart';
import '../../planning/presentation/live_compass_view.dart';
import '../../planning/presentation/offline_planning_map.dart';
import '../../planning/presentation/planning_context_card.dart';
import '../../planning/presentation/planning_field_controls.dart';
import '../domain/astronomy_calculator.dart';

/// Targets that cover most real night-sky sessions. Everything else stays one
/// searchable picker away, so nothing is hidden.
const List<(CelestialTarget, String)> _commonTargets =
    <(CelestialTarget, String)>[
      (CelestialTarget.milkyWayCore, 'Milky Way core'),
      (CelestialTarget.polaris, 'Polaris'),
      (CelestialTarget.orionNebula, 'Orion Nebula'),
      (CelestialTarget.andromedaGalaxy, 'Andromeda (M31)'),
      (CelestialTarget.pleiades, 'Pleiades (M45)'),
      (CelestialTarget.jupiter, 'Jupiter'),
      (CelestialTarget.moon, 'Moon'),
      (CelestialTarget.sun, 'Sun'),
    ];

class AstronomyScreen extends ConsumerStatefulWidget {
  const AstronomyScreen({this.capabilities, super.key});
  final PlanningCapabilities? capabilities;
  @override
  ConsumerState<AstronomyScreen> createState() => _AstronomyScreenState();
}

class _AstronomyScreenState extends ConsumerState<AstronomyScreen> {
  final _latitude = TextEditingController(text: '51.4779');
  final _longitude = TextEditingController(text: '0');
  final _elevation = TextEditingController(text: '0');
  final _focalLength = TextEditingController(text: '24');
  final _cropFactor = TextEditingController(text: '1');
  final _aperture = TextEditingController(text: '2.8');
  final _pixelPitch = TextEditingController(text: '5');
  final _trailDegrees = TextEditingController(text: '30');
  final _magneticDeclination = TextEditingController(text: '0');
  late DateTime _instantUtc;
  var _target = CelestialTarget.milkyWayCore;
  var _shutterRule = StarShutterRule.npf;
  var _sharpnessTolerance = StarSharpnessTolerance.balanced;
  var _view = PlanningView.numeric;
  CameraBody? _camera;
  Lens? _lens;
  CalculationResult<AstronomyOutput>? _result;
  Map<String, String> _errors = const {};
  Map<String, bool> _checklist = {
    'Check forecast and cloud cover': false,
    'Confirm target visibility and terrain': false,
    'Focus on a bright star': false,
    'Capture a test frame and inspect stars': false,
  };
  var _timeZoneId = 'UTC';
  SavedLocation? _selectedLocation;
  var _defaultsApplied = false;

  /// True once an input changed after a plan, so the cleared result is
  /// explained rather than silently missing.
  var _stale = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _instantUtc = DateTime.utc(now.year, now.month, now.day, now.hour);
  }

  @override
  void dispose() {
    for (final controller in [
      _latitude,
      _longitude,
      _elevation,
      _focalLength,
      _cropFactor,
      _aperture,
      _pixelPitch,
      _trailDegrees,
      _magneticDeclination,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    if (!_defaultsApplied && preferences != null) {
      _sharpnessTolerance = _starSharpness(preferences.defaultStarSharpness);
      _defaultsApplied = true;
    }
    // activeItems, not items: the inventory's Kit kind filter must not hide the
    // saved cameras and lenses from this calculator.
    final equipment = ref.watch(equipmentControllerProvider).activeItems;
    final cameras = equipment
        .where((entry) => entry.kind == EquipmentKind.camera)
        .map((entry) => entry.item)
        .whereType<CameraBody>()
        .toList();
    final lenses = equipment
        .where((entry) => entry.kind == EquipmentKind.lens)
        .map((entry) => entry.item)
        .whereType<Lens>()
        .toList();
    final theme = Theme.of(context);
    final savedLocations =
        ref.watch(savedLocationsProvider).valueOrNull ??
        const <SavedLocation>[];
    return PlanningWorkbench(
      // Pinned under the form rather than sitting at the end of it: the explicit
      // action must never cost a scroll through every field first.
      action: FilledButton.icon(
        key: const Key('astronomy-search'),
        onPressed: _calculate,
        icon: const Icon(Icons.nightlight_outlined),
        label: const Text('Plan night sky'),
      ),
      body: CalculatorPage(
        inputControllers: [
          _latitude,
          _longitude,
          _elevation,
          _focalLength,
          _cropFactor,
          _aperture,
          _pixelPitch,
          _trailDegrees,
          _magneticDeclination,
        ],
        onInputsChanged: () {
          // A changed input can no longer support the displayed plan. Clearing it
          // is the only honest option: the result card must never describe values
          // it was not produced from. The guard also keeps the first build's
          // sharpness default from calling setState during a build.
          if (_result == null && _errors.isEmpty && !_stale) return;
          setState(_discardResult);
        },
        children: [
          const CalculatorHeader(
            icon: Icons.nightlight_round,
            description:
                'Plan celestial targets entirely offline. Calculations use UTC and bearings use true north; saved locations can display local civil time.',
          ),
          PlanningSectionHeader(
            icon: Icons.place_outlined,
            title: 'Site and horizon',
            summary: PlanningLiveText(
              controllers: [_latitude, _longitude, _elevation],
              text: _siteSummary,
              style: theme.textTheme.bodySmall,
            ),
          ),
          // The saved-site picker only exists when a site is saved: an empty
          // dropdown would spend a whole row announcing that it has nothing to
          // offer. Manual coordinates stay below it either way, and nothing is
          // ever chosen for the user - no default site and no location request.
          if (savedLocations.isNotEmpty)
            DropdownButtonFormField<SavedLocation>(
              isExpanded: true,
              key: ValueKey(_selectedLocation?.id ?? 'manual-location'),
              decoration: const InputDecoration(
                labelText: 'Saved location (optional)',
              ),
              items: [
                for (final location in savedLocations)
                  DropdownMenuItem(value: location, child: Text(location.name)),
              ],
              initialValue: _selectedLocation,
              onChanged: (location) {
                if (location == null) return;
                setState(() {
                  _latitude.text = location.latitudeDegrees.toString();
                  _longitude.text = location.longitudeDegrees.toString();
                  // Never invent an elevation: keep the field as entered and
                  // disclose the missing value below instead.
                  if (location.elevationMetres case final elevation?) {
                    _elevation.text = elevation.toString();
                  }
                  _timeZoneId = location.timeZoneId;
                  _selectedLocation = location;
                  _discardResult();
                });
              },
            ),
          if (_selectedLocation case final location?
              when location.elevationMetres == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'This saved location has no elevation, so the observer elevation in Site details is unchanged. '
                'Verify it before relying on horizon, rise, or set times.',
              ),
            ),
          // Coordinates stay full width with exact entry: a half-width column
          // would wrap these long labels, and a slider would only make a precise
          // latitude or longitude harder to read back. Their bounds are stated by
          // the labels and by the error line, not by a standing paragraph over
          // each field.
          CalculatorNumberField(
            label: 'Observer latitude (degrees)',
            controller: _latitude,
            errorText: _errors['observerLatitudeDegrees'],
          ),
          CalculatorNumberField(
            label: 'Observer longitude, east positive (degrees)',
            controller: _longitude,
            errorText: _errors['observerLongitudeDegrees'],
          ),
          // Elevation is set once per trip, so it keeps the viewport cheap while
          // its value - and any validation error - stays in the collapsed row.
          PlanningSiteDetails(
            errorText: _errors['observerElevationMetres'],
            summary: PlanningLiveText(
              controllers: [_elevation],
              text: _elevationSummary,
              style: theme.textTheme.bodySmall,
            ),
            children: <Widget>[
              CalculatorNumberField(
                label: 'Observer elevation (m)',
                controller: _elevation,
                errorText: _errors['observerElevationMetres'],
                presets: const [0, 100, 500, 1000, 2000],
                step: 10,
                helperText: 'Metres above sea level; terrain is not modeled.',
              ),
            ],
          ),
          PlanningSectionHeader(
            icon: Icons.event_outlined,
            title: 'Date and time',
          ),
          _planningTimeControl(),
          PlanningSectionHeader(
            icon: Icons.filter_center_focus,
            title: 'Target',
          ),
          PlanningChipRow(
            chips: <Widget>[
              for (final (target, label) in _commonTargets)
                PlanningShortcutChip(
                  label: label,
                  selected: _target == target,
                  tooltip: '${_category(target.category)} target',
                  onPressed: () => _selectTarget(target),
                ),
            ],
          ),
          const SizedBox(height: AppGap.md),
          DropdownMenu<CelestialTarget>(
            // The picker follows [initialSelection], so a target chosen from the
            // chips above is what this field then shows.
            label: const Text('Search celestial targets'),
            enableFilter: true,
            enableSearch: true,
            initialSelection: _target,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              for (final target in CelestialTarget.values)
                DropdownMenuEntry(
                  value: target,
                  label: '${target.label} · ${_category(target.category)}',
                ),
            ],
            onSelected: (value) {
              if (value == null) return;
              _selectTarget(value);
            },
          ),
          if (_target == CelestialTarget.sun) ...[
            const SizedBox(height: AppGap.md),
            const Card(
              color: Color(0xffffe0b2),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solar safety: never look at the Sun through a camera, lens, viewfinder, binoculars, or telescope without a certified solar filter. This plan is an estimate, not a safety guarantee.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          PlanningSectionHeader(
            icon: Icons.camera_alt_outlined,
            title: 'Camera and exposure',
            summary: PlanningLiveText(
              controllers: [
                _focalLength,
                _cropFactor,
                _aperture,
                _pixelPitch,
                _trailDegrees,
              ],
              text: _cameraSummary,
              style: theme.textTheme.bodySmall,
            ),
          ),
          // The camera supplies the crop factor and the lens the focal length the
          // sharp-star rules use, so both pickers sit with the camera section
          // instead of behind the advanced disclosure. Each hides itself when the
          // kit holds none of that gear, and the raw numbers stay advanced.
          if (cameras.isNotEmpty)
            EquipmentPicker<CameraBody>(
              label: 'Saved camera (optional)',
              items: cameras,
              itemLabel: (item) => item.name,
              itemDetail: cameraSpecSummary,
              value: _camera,
              onSelected: (camera) => setState(() {
                _camera = camera;
                _discardResult();
                if (camera != null) {
                  // The planner consumes a crop factor, so derive it from the
                  // saved sensor width instead of recording an unused dimension.
                  _cropFactor.text = (36 / camera.sensorWidthMm)
                      .toStringAsFixed(2);
                }
              }),
            ),
          if (_camera case final camera?)
            AppliedEquipmentNotice(
              equipmentName: camera.name,
              sourceLabel: camera.provenance.source.label,
              appliedValues: '${_cropFactor.text}× crop factor',
            ),
          if (lenses.isNotEmpty)
            EquipmentPicker<Lens>(
              label: 'Saved lens (optional)',
              items: lenses,
              itemLabel: (item) => item.name,
              itemDetail: lensSpecSummary,
              value: _lens,
              onSelected: _applyLens,
            ),
          if (_lens case final lens?)
            AppliedEquipmentNotice(
              equipmentName: lens.name,
              sourceLabel: lens.provenance.source.label,
              appliedValues: '${_focalLength.text} mm focal length',
            ),
          CalculatorAdvancedSection(
            // Stable identity: applying equipment above must not collapse
            // the section the user is working in.
            key: const ValueKey('advanced'),
            children: <Widget>[
              Text('Optics', style: theme.textTheme.titleSmall),
              CalculatorFieldPair(
                first: CalculatorNumberField(
                  label: 'Focal length (mm)',
                  controller: _focalLength,
                  errorText: _errors['focalLengthMm'],
                  presets: const [14, 24, 35, 50, 85, 135, 200],
                  min: 4,
                  max: 1200,
                  step: 1,
                  helperText:
                      'Any focal length is accepted; presets are common '
                      'night lenses.',
                ),
                second: CalculatorNumberField(
                  label: 'Crop factor',
                  controller: _cropFactor,
                  errorText: _errors['cropFactor'],
                  presets: const [1, 1.5, 1.6, 2],
                  min: 0.5,
                  max: 4,
                  step: 0.01,
                  helperText: 'Full frame is 1×.',
                ),
              ),
              CalculatorFieldPair(
                first: CalculatorNumberField(
                  label: 'Aperture (f-number)',
                  controller: _aperture,
                  errorText: _errors['aperture'],
                  // The steppers walk the standard full stops; exact entry stays
                  // available for off-series apertures.
                  presets: const [1, 1.4, 2, 2.8, 4, 5.6, 8, 11, 16, 22, 32],
                  helperText: 'Used by the NPF sharp-star rule.',
                ),
                second: CalculatorNumberField(
                  label: 'Pixel pitch (µm)',
                  controller: _pixelPitch,
                  errorText: _errors['pixelPitchMicrometres'],
                  presets: const [3.76, 4.3, 5, 6],
                  min: 1,
                  max: 20,
                  step: 0.01,
                  helperText: 'From the camera specification sheet.',
                ),
              ),
              const SizedBox(height: AppGap.md),
              Text('Sharp stars', style: theme.textTheme.titleSmall),
              SegmentedButton<StarShutterRule>(
                segments: const [
                  ButtonSegment(value: StarShutterRule.npf, label: Text('NPF')),
                  ButtonSegment(
                    value: StarShutterRule.rule500,
                    label: Text('500'),
                  ),
                ],
                selected: {_shutterRule},
                onSelectionChanged: (values) => setState(() {
                  _shutterRule = values.first;
                  _discardResult();
                }),
              ),
              const SizedBox(height: AppGap.sm),
              SegmentedButton<StarSharpnessTolerance>(
                segments: const [
                  ButtonSegment(
                    value: StarSharpnessTolerance.strict,
                    label: Text('Strict'),
                  ),
                  ButtonSegment(
                    value: StarSharpnessTolerance.balanced,
                    label: Text('Balanced'),
                  ),
                  ButtonSegment(
                    value: StarSharpnessTolerance.relaxed,
                    label: Text('Relaxed'),
                  ),
                ],
                selected: {_sharpnessTolerance},
                onSelectionChanged: (values) => setState(() {
                  _sharpnessTolerance = values.first;
                  _discardResult();
                }),
              ),
              Text(
                'Default: ${_starSharpness(preferences?.defaultStarSharpness ?? DefaultStarSharpness.balanced).name} from Settings',
              ),
              const SizedBox(height: AppGap.md),
              Text('Star trails', style: theme.textTheme.titleSmall),
              CalculatorNumberField(
                label: 'Desired star-trail arc (degrees)',
                controller: _trailDegrees,
                errorText: _errors['desiredTrailDegrees'],
                presets: const [15, 30, 60, 120],
                min: 1,
                max: 360,
                step: 1,
                helperText: 'Arc the stars should draw during the exposure.',
              ),
              const SizedBox(height: AppGap.md),
              Text('Compass', style: theme.textTheme.titleSmall),
              CalculatorNumberField(
                label: 'Magnetic declination, east positive (degrees)',
                controller: _magneticDeclination,
                presets: const [-20, -10, 0, 10, 20],
                min: -90,
                max: 90,
                step: 0.5,
                helperText: 'Applied to the live compass and AR overlay only.',
              ),
            ],
          ),
          if (_stale && _result == null)
            const PlanningNote(
              message:
                  'Inputs changed since the last plan. Plan night sky again to '
                  'see the position and events for these values.',
            ),
          const SizedBox(height: AppGap.lg),
          if (_result?.output case final output?) ...[
            CalculationResultView(
              title: '${_target.label} plan',
              highlight: (
                'Target altitude',
                '${output.altitudeDegrees.toStringAsFixed(0)}° '
                    '${output.isAboveHorizon ? 'above the horizon' : 'below the horizon'}',
              ),
              highlightCaption:
                  'Azimuth ${output.azimuthDegrees.toStringAsFixed(0)}° true · '
                  '${output.isAboveHorizon ? 'up now' : 'not visible now'}',
              tiles: <(String, String)>[
                (
                  'Recommended',
                  '${output.recommendedShutterSeconds.toStringAsFixed(1)} s',
                ),
                ('500 rule', '${output.rule500Seconds.toStringAsFixed(1)} s'),
                ('NPF rule', '${output.npfSeconds.toStringAsFixed(1)} s'),
                if (_target == CelestialTarget.milkyWayCore)
                  (
                    'Milky Way',
                    output.milkyWayOrientationDegrees != null
                        ? '${output.milkyWayOrientationDegrees!.toStringAsFixed(0)}° to horizon'
                        : 'Unavailable near zenith',
                  ),
              ],
              details: <(String, String)>[
                (
                  'Right ascension',
                  '${output.rightAscensionDegrees.toStringAsFixed(2)}°',
                ),
                (
                  'Declination',
                  '${output.declinationDegrees.toStringAsFixed(2)}°',
                ),
                (
                  'Altitude (exact)',
                  '${output.altitudeDegrees.toStringAsFixed(1)}°',
                ),
                (
                  'Azimuth (exact)',
                  '${output.azimuthDegrees.toStringAsFixed(1)}° true',
                ),
                if (_target == CelestialTarget.milkyWayCore)
                  (
                    'Milky Way orientation',
                    output.milkyWayOrientationDegrees != null
                        ? '${output.milkyWayOrientationDegrees!.toStringAsFixed(1)}° relative to horizon'
                        : 'Unavailable near zenith or nadir',
                  ),
                ('Visibility cycle', _cycle(output.visibilityCycle)),
                (
                  '${_value(_trailDegrees).toStringAsFixed(0)}° star trail',
                  _duration(output.trailDurationSeconds),
                ),
                (
                  'Trail rotation',
                  '${output.trailRotationDegreesPerHour.toStringAsFixed(1)}°/hour',
                ),
                (
                  'Selected rule',
                  '${_shutterRule == StarShutterRule.npf ? 'NPF' : '500'} · ${_sharpnessTolerance.name}',
                ),
                for (final sample in output.path)
                  (
                    'Sky path ${DateFormat('HH:mm').format(sample.instantUtc)} UTC',
                    '${sample.altitudeDegrees.toStringAsFixed(0)}° / ${sample.azimuthDegrees.toStringAsFixed(0)}° true north',
                  ),
              ],
              inputs: [
                ('Target', _target.label),
                (
                  'Observer',
                  '${_latitude.text.trim()}°, ${_longitude.text.trim()}° · ${_elevation.text.trim()} m',
                ),
                ('Planning time', _planningTimeSummary()),
                (
                  'Optics',
                  '${_focalLength.text.trim()} mm · ${_cropFactor.text.trim()}× crop · f/${_aperture.text.trim()} · ${_pixelPitch.text.trim()} µm pixels',
                ),
                (
                  'Sharp-star rule',
                  '${_shutterRule == StarShutterRule.npf ? 'NPF' : '500'} · ${_sharpnessTolerance.name}',
                ),
                ('Star-trail arc', '${_trailDegrees.text.trim()}°'),
              ],
              assumptions: [
                switch (_target) {
                  CelestialTarget.sun =>
                    'USNO-style analytic solar ephemeris; geocentric, mean equinox of date',
                  CelestialTarget.moon =>
                    'USNO-style analytic lunar ephemeris; geocentric, mean equinox of date',
                  _ when _target.isMoving =>
                    'JPL 1800–2050 approximate Keplerian model; moving-target events are solved against updated coordinates and remain planning-grade',
                  _ => 'Fixed ICRS/J2000 target coordinates',
                },
                'Airless geometric horizon; terrain and refraction excluded',
                'Approximate mean sidereal time and planning-grade exposure rules',
                if (_target == CelestialTarget.milkyWayCore) ...[
                  AstronomyCalculator.milkyWayOrientationConvention,
                  AstronomyCalculator.milkyWayOrientationLimitations,
                  if (!output.isAboveHorizon)
                    'The core is below the geometric horizon; its orientation is mathematical, not a visible composition.',
                ],
              ],
              warnings: _warningMessages(_result!.warnings),
              guidance:
                  'The 500 and NPF values are estimates: inspect stars at your intended output size. Event instants are stored in UTC and displayed in the selected timezone. Terrain, refraction, precession, and proper motion are excluded.',
              onSave: () => _save(output),
              onReset: _reset,
            ),
            const SizedBox(height: AppGap.md),
            _planningContext(),
            PlanningSectionHeader(
              icon: Icons.visibility_outlined,
              title: 'View the plan',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<PlanningView>(
                segments: const [
                  ButtonSegment(
                    value: PlanningView.numeric,
                    label: Text('Numeric'),
                  ),
                  ButtonSegment(
                    value: PlanningView.timeline,
                    label: Text('Timeline'),
                  ),
                  ButtonSegment(
                    value: PlanningView.compass,
                    label: Text('Compass'),
                  ),
                  ButtonSegment(value: PlanningView.map, label: Text('Map')),
                  ButtonSegment(
                    value: PlanningView.augmentedReality,
                    label: Text('AR'),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (values) =>
                    setState(() => _view = values.first),
              ),
            ),
            const SizedBox(height: AppGap.sm),
            _planningView(output),
            const SizedBox(height: AppGap.md),
            Text('Next events', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppGap.sm),
            _EventsTimeline(
              events: output.events,
              timeZone: PlanningTimeContext.parse(_timeZoneId),
              onDark: false,
            ),
            const SizedBox(height: AppGap.md),
            FieldChecklist(
              items: _checklist,
              onChanged: (items) => setState(() => _checklist = items),
            ),
          ],
        ],
      ),
    );
  }

  /// Clears a result that no longer matches the inputs, remembering that it is
  /// the reason the result is missing rather than a search that found nothing.
  void _discardResult() {
    if (_result != null) _stale = true;
    _result = null;
    _errors = const {};
  }

  /// The site's identity while scrolling: the saved name (or manual entry) and
  /// the coordinates. The elevation is stated once, by the Site details row that
  /// holds its field, rather than repeated here.
  String _siteSummary() {
    final name = _selectedLocation?.name ?? 'Manual coordinates';
    return '$name · ${_latitude.text.trim()}°, ${_longitude.text.trim()}°';
  }

  /// What the collapsed Site details row states: the value it holds and the
  /// horizon limitation behind it.
  String _elevationSummary() =>
      'Elevation ${_elevation.text.trim()} m · terrain is not modeled';

  /// What the collapsed camera group currently holds, so the conventions behind
  /// "More settings" are stated without opening it.
  String _cameraSummary() {
    final rule = _shutterRule == StarShutterRule.npf ? 'NPF' : '500';
    return '${_focalLength.text.trim()} mm · crop ${_cropFactor.text.trim()}× · '
        'f/${_aperture.text.trim()} · ${_pixelPitch.text.trim()} µm · '
        '$rule ${_sharpnessTolerance.name} · '
        '${_trailDegrees.text.trim()}° trail';
  }

  void _selectTarget(CelestialTarget target) {
    if (_target == target) return;
    setState(() {
      _target = target;
      _discardResult();
    });
  }

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;
  void _calculate() {
    final result = const AstronomyCalculator().calculate(
      AstronomyInput(
        observerLatitudeDegrees: _value(_latitude),
        observerLongitudeDegrees: _value(_longitude),
        observerElevationMetres: _value(_elevation),
        instantUtc: _instantUtc,
        target: _target,
        focalLengthMm: _value(_focalLength),
        cropFactor: _value(_cropFactor),
        aperture: _value(_aperture),
        pixelPitchMicrometres: _value(_pixelPitch),
        desiredTrailDegrees: _value(_trailDegrees),
        selectedRule: _shutterRule,
        sharpnessTolerance: _sharpnessTolerance,
      ),
    );
    setState(() {
      _result = result;
      _stale = false;
      _errors = {
        for (final error in result.errors)
          error.field: 'Enter a finite value within the supported range.',
      };
    });
  }

  void _shiftTime(int hours) => setState(() {
    _instantUtc = _instantUtc.add(Duration(hours: hours));
    _discardResult();
  });

  /// The current instant, floored to the minute, so a shortcut never claims
  /// more precision than a clock reading has.
  DateTime get _nowMinute {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
  }

  /// The next occurrence of a local wall-clock time in the planning zone. A
  /// time already past today belongs to the coming night, not to yesterday.
  DateTime _nextLocalTime(int hour, int minute) {
    final time = PlanningTimeContext.parse(_timeZoneId);
    final localNow = time.localCivilTime(DateTime.now().toUtc());
    final today = DateTime.utc(
      localNow.year,
      localNow.month,
      localNow.day,
      hour,
      minute,
    );
    final candidate = today.isAfter(localNow)
        ? today
        : DateTime.utc(
            localNow.year,
            localNow.month,
            localNow.day + 1,
            hour,
            minute,
          );
    return time.toUtc(candidate);
  }

  void _setInstant(DateTime instant) {
    if (_instantUtc == instant) return;
    setState(() {
      _instantUtc = instant;
      _discardResult();
    });
  }

  /// The instant with its zone for the result's input summary. The formatted
  /// value already ends in the zone it was rendered in, so the requested
  /// identifier is only named when it could not be resolved to one.
  String _planningTimeSummary() {
    final time = PlanningTimeContext.parse(_timeZoneId);
    final formatted = time.format(_instantUtc);
    return time.canConvertOffline
        ? formatted
        : '$formatted (requested $_timeZoneId)';
  }

  /// The canonical UTC instant with the time-zone confidence note, omitting the
  /// instant when the value line above already prints it: a planning zone of
  /// UTC (the default) renders the same string, so repeating it adds noise
  /// without adding information (FR-013).
  String _planningTimeProvenance(PlanningTimeContext time) {
    final canonicalUtc = DateFormat(
      "yyyy-MM-dd HH:mm 'UTC'",
    ).format(_instantUtc);
    return time.format(_instantUtc) == canonicalUtc
        ? time.confidenceLabel
        : '$canonicalUtc · ${time.confidenceLabel}';
  }

  Widget _planningTimeControl() {
    final time = PlanningTimeContext.parse(_timeZoneId);
    final now = _nowMinute;
    final tonight = _nextLocalTime(22, 0);
    final midnight = _nextLocalTime(0, 0);
    final deepNight = _nextLocalTime(2, 0);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Planning time (${time.timeZoneId})',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            time.format(_instantUtc),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(_planningTimeProvenance(time), textAlign: TextAlign.center),
          const SizedBox(height: AppGap.sm),
          PlanningChipRow(
            chips: <Widget>[
              PlanningShortcutChip(
                label: 'Now',
                tooltip: 'The current minute',
                selected: _instantUtc == now,
                onPressed: () => _setInstant(now),
              ),
              PlanningShortcutChip(
                label: 'Tonight 22:00',
                tooltip: 'The next 22:00 in ${time.timeZoneId}',
                selected: _instantUtc == tonight,
                onPressed: () => _setInstant(tonight),
              ),
              PlanningShortcutChip(
                label: 'Midnight',
                tooltip: 'The next 00:00 in ${time.timeZoneId}',
                selected: _instantUtc == midnight,
                onPressed: () => _setInstant(midnight),
              ),
              PlanningShortcutChip(
                label: '02:00',
                tooltip: 'The next 02:00 in ${time.timeZoneId}',
                selected: _instantUtc == deepNight,
                onPressed: () => _setInstant(deepNight),
              ),
            ],
          ),
          const SizedBox(height: AppGap.sm),
          OutlinedButton.icon(
            onPressed: _pickLocalDateTime,
            icon: const Icon(Icons.event_outlined),
            label: const Text('Choose local date and time'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'One hour earlier',
                onPressed: () => _shiftTime(-1),
                icon: const Icon(Icons.remove),
              ),
              // At 200% text scale the label alone is wider than the screen, so
              // it must wrap instead of overflowing the centred row (FR-019).
              const Flexible(
                child: Text('Adjust one hour', textAlign: TextAlign.center),
              ),
              IconButton(
                tooltip: 'One hour later',
                onPressed: () => _shiftTime(1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocalDateTime() async {
    final time = PlanningTimeContext.parse(_timeZoneId);
    final initial = time.localCivilTime(_instantUtc);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: DateTime(2050, 12, 31),
      helpText: 'Choose local date · ${time.timeZoneId}',
    );
    if (selectedDate == null || !mounted) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Choose local time · ${time.timeZoneId}',
    );
    if (selectedTime == null || !mounted) return;
    final localCivilTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    setState(() {
      _instantUtc = time.toUtc(localCivilTime);
      _discardResult();
    });
  }

  void _applyLens(Lens? lens) => setState(() {
    _lens = lens;
    if (lens != null) _focalLength.text = lens.minimumFocalLengthMm.toString();
    _discardResult();
  });

  Future<void> _save(AstronomyOutput output) => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${AstronomyCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: AstronomyCalculator.id,
      formulaVersion: AstronomyCalculator.version,
      createdAt: DateTime.now().toUtc(),
      title: '${_target.label} night-sky plan',
      canonicalInputs: {
        'latitudeDegrees': _value(_latitude),
        'longitudeDegrees': _value(_longitude),
        'observerElevationMetres': _value(_elevation),
        'instantUtc': _instantUtc.toIso8601String(),
        'target': _target.name,
        // Coordinates actually used by the calculation: topocentric for the Sun
        // and Moon, geocentric otherwise.
        'rightAscensionDegrees': output.rightAscensionDegrees,
        'declinationDegrees': output.declinationDegrees,
        'focalLengthMm': _value(_focalLength),
        'cropFactor': _value(_cropFactor),
        'aperture': _value(_aperture),
        'pixelPitchMicrometres': _value(_pixelPitch),
        'desiredTrailDegrees': _value(_trailDegrees),
        'selectedRule': _shutterRule.name,
        'sharpnessTolerance': _sharpnessTolerance.name,
        'magneticDeclinationDegrees': _value(_magneticDeclination),
      },
      canonicalOutputs: {
        'altitudeDegrees': output.altitudeDegrees,
        'azimuthDegrees': output.azimuthDegrees,
        'aboveHorizon': output.isAboveHorizon,
        'visibilityCycle': output.visibilityCycle.name,
        'rule500Seconds': output.rule500Seconds,
        'npfSeconds': output.npfSeconds,
        'trailDurationSeconds': output.trailDurationSeconds,
        'recommendedShutterSeconds': output.recommendedShutterSeconds,
        if (_target == CelestialTarget.milkyWayCore)
          'milkyWayOrientationDegrees': output.milkyWayOrientationDegrees,
        'events': [
          for (final event in output.events)
            {
              'type': event.type.name,
              'instantUtc': event.instantUtc.toIso8601String(),
            },
        ],
        'fieldChecklist': _checklist.entries
            .map((entry) => {'task': entry.key, 'complete': entry.value})
            .toList(growable: false),
      },
      displayContext: {
        'timeZone': _timeZoneId,
        'localPlanningTime': PlanningTimeContext.parse(
          _timeZoneId,
        ).format(_instantUtc),
        'timeZoneConfidence': PlanningTimeContext.parse(
          _timeZoneId,
        ).confidenceLabel,
        'locationLabel': _selectedLocation?.name ?? 'Manual coordinates',
        'locationSource': _selectedLocation?.source.name ?? 'manual entry',
        'locationAccuracyMetres': _selectedLocation?.accuracyMetres,
        'locationUpdatedAtUtc': _selectedLocation?.updatedAt.toIso8601String(),
        'observerElevationMetres': _value(_elevation),
        'horizon': 'airless geometric horizon',
        'refraction': 'not applied',
        'catalogVersion': AstronomyCatalogMetadata.current.version,
        'catalogProvenance': AstronomyCatalogMetadata.current.provenance,
        'catalogSupportedEpoch':
            '${AstronomyCatalogMetadata.current.supportedStartYear}–${AstronomyCatalogMetadata.current.supportedEndYear}',
        'sourceFreshness': _catalogFreshness,
        'expectedAccuracy': _expectedAccuracy,
        'azimuthReference': 'trueNorth',
        'requestedNorthReference':
            ref.read(preferencesProvider).valueOrNull?.northReference.name ??
            NorthReference.trueNorth.name,
        'magneticDeclinationDegrees': _value(_magneticDeclination),
        'angleUnit': 'degrees',
        if (_target == CelestialTarget.milkyWayCore)
          'milkyWayOrientationConvention':
              AstronomyCalculator.milkyWayOrientationConvention,
      },
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
      equipment: [
        if (_camera case final camera?)
          _equipment(camera, SnapshotEquipmentType.camera, {
            // The applied input is the crop factor derived from this width.
            'cropFactor': _value(_cropFactor),
            'sensorWidthMm': camera.sensorWidthMm,
          }),
        if (_lens case final lens?)
          _equipment(lens, SnapshotEquipmentType.lens, {
            'focalLengthMm': _value(_focalLength),
          }),
      ],
    ),
  );
  AppliedEquipmentSnapshot _equipment(
    EquipmentItem item,
    SnapshotEquipmentType type,
    Map<String, Object?> values,
  ) => AppliedEquipmentSnapshot(
    id: item.id,
    type: type,
    name: item.name,
    source: item.provenance.source.name,
    note: item.provenance.note,
    values: values,
  );
  String _cycle(VisibilityCycle cycle) => switch (cycle) {
    VisibilityCycle.risesAndSets => 'Rises and sets',
    VisibilityCycle.circumpolar => 'Circumpolar',
    VisibilityCycle.neverRises => 'Never rises',
  };
  String _category(TargetCategory category) => switch (category) {
    TargetCategory.milkyWay => 'Milky Way',
    TargetCategory.planet => 'Planet · JPL approximate moving model',
    TargetCategory.star => 'Star',
    TargetCategory.nebula => 'Nebula',
    TargetCategory.galaxy => 'Galaxy',
    TargetCategory.cluster => 'Cluster',
    TargetCategory.sun => 'Sun · certified solar filter required',
    TargetCategory.moon => 'Moon',
  };

  List<String> _warningMessages(List<CalculationWarning> warnings) => [
    for (final warning in warnings) _warningMessage(warning.code),
  ];

  String _warningMessage(String code) => calculationWarningText(code);
  String _duration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    return '${duration.inHours} h ${duration.inMinutes.remainder(60)} min';
  }

  void _reset() {
    _latitude.text = '51.4779';
    _longitude.text = '0';
    _elevation.text = '0';
    _focalLength.text = '24';
    _cropFactor.text = '1';
    _aperture.text = '2.8';
    _pixelPitch.text = '5';
    _trailDegrees.text = '30';
    _magneticDeclination.text = '0';
    setState(() {
      _target = CelestialTarget.milkyWayCore;
      _shutterRule = StarShutterRule.npf;
      _sharpnessTolerance = _starSharpness(
        ref.read(preferencesProvider).valueOrNull?.defaultStarSharpness ??
            DefaultStarSharpness.balanced,
      );
      _view = PlanningView.numeric;
      _camera = null;
      _lens = null;
      _selectedLocation = null;
      _timeZoneId = 'UTC';
      _result = null;
      _stale = false;
      _errors = const {};
    });
  }

  StarSharpnessTolerance _starSharpness(DefaultStarSharpness value) =>
      switch (value) {
        DefaultStarSharpness.strict => StarSharpnessTolerance.strict,
        DefaultStarSharpness.balanced => StarSharpnessTolerance.balanced,
        DefaultStarSharpness.relaxed => StarSharpnessTolerance.relaxed,
      };

  String get _catalogFreshness {
    const catalog = AstronomyCatalogMetadata.current;
    return 'catalog ${catalog.version} ${catalog.freshnessLabel(DateTime.now().toUtc())}; bundled ${catalog.bundledAtUtc}; ${catalog.updatePolicy}';
  }

  String get _expectedAccuracy => switch (_target) {
    CelestialTarget.sun =>
      'Planning-grade: approximately ±0.25° position and ±2 minutes for events',
    CelestialTarget.moon =>
      'Planning-grade: approximately ±2° position and ±20 minutes for events; the bundled analytic lunar series omits the smaller periodic terms',
    _ when _target.isMoving =>
      'Planning-grade: approximately ±0.25° position and ±10 minutes for events',
    _ =>
      'Planning-grade: approximately ±0.25° position and ±2 minutes for events',
  };

  /// Elevation is entered and stored in metres; only its presentation follows
  /// the saved length preference (FR-020).
  String _metres(String text) {
    final value = double.tryParse(text.trim());
    if (value == null || !value.isFinite) return '$text m';
    final display =
        ref.watch(preferencesProvider).valueOrNull?.lengthDisplay ??
        LengthDisplay.metric;
    return formatDisplayLength(value * 1000, display);
  }

  Widget _planningContext() {
    final time = PlanningTimeContext.parse(_timeZoneId);
    const catalog = AstronomyCatalogMetadata.current;
    final location = _selectedLocation;
    final locationDetail = location == null
        ? 'Manual entry · accuracy not reported · no saved capture timestamp'
        : '${location.source.name} · ${location.accuracyMetres == null ? 'accuracy not reported' : '±${location.accuracyMetres!.toStringAsFixed(0)} m reported accuracy'} · updated ${DateFormat("yyyy-MM-dd HH:mm 'UTC'").format(location.updatedAt)}';
    return PlanningContextCard(
      entries: [
        ('Location', location?.name ?? 'Manual coordinates'),
        ('Coordinates', '${_latitude.text}, ${_longitude.text}'),
        ('Location data', locationDetail),
        ('Elevation', _metres(_elevation.text)),
        ('Local time', time.format(_instantUtc)),
        (
          'Canonical UTC',
          DateFormat("yyyy-MM-dd HH:mm 'UTC'").format(_instantUtc),
        ),
        ('Timezone', '${time.timeZoneId} · ${time.confidenceLabel}'),
        ('North', 'true north (calculated); user preference retained'),
        ('Horizon', 'airless geometric horizon · refraction not applied'),
        ('Accuracy', _expectedAccuracy),
        (
          'Catalog',
          '${catalog.version} · ${catalog.provenance} · ${catalog.supportedStartYear}–${catalog.supportedEndYear}',
        ),
        ('Freshness', _catalogFreshness),
      ],
    );
  }

  Widget _planningView(AstronomyOutput output) {
    final northReference =
        ref.watch(preferencesProvider).valueOrNull?.northReference ??
        NorthReference.trueNorth;
    // A caller may inject capabilities; otherwise use the detected device state.
    final capabilities =
        widget.capabilities ??
        ref.watch(planningCapabilitiesProvider).valueOrNull;
    if (_view == PlanningView.augmentedReality &&
        capabilities != null &&
        !capabilities.canShowAr) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'AR unavailable. ${capabilities.augmentedRealityLimitation} Numeric, timeline, compass, and offline-map views remain usable without camera or orientation permission.',
          ),
        ),
      );
    }
    return switch (_view) {
      PlanningView.numeric => Text(
        '${_target.label}: ${output.altitudeDegrees.toStringAsFixed(1)}° altitude, ${output.azimuthDegrees.toStringAsFixed(1)}° true azimuth',
      ),
      PlanningView.timeline => Column(
        children: [
          for (final sample in output.path)
            ListTile(
              dense: true,
              title: Text(
                PlanningTimeContext.parse(
                  _timeZoneId,
                ).format(sample.instantUtc),
              ),
              trailing: Text(
                '${sample.altitudeDegrees.toStringAsFixed(0)}° / ${sample.azimuthDegrees.toStringAsFixed(0)}°',
              ),
            ),
        ],
      ),
      PlanningView.compass => LiveCompassView(
        trueBearingDegrees: output.azimuthDegrees,
        magneticDeclinationDegrees: _value(_magneticDeclination),
        northReference: northReference,
      ),
      PlanningView.map => OfflinePlanningMap(
        desiredBearingDegrees: output.azimuthDegrees,
        observerLabel:
            'Observer ${_latitude.text}, ${_longitude.text} · ${_metres(_elevation.text)}',
        markers: [
          PlanningMapMarker(
            bearingDegrees: output.azimuthDegrees,
            altitudeDegrees: output.altitudeDegrees,
            label: '${_target.label} now',
            isPrimary: true,
          ),
          for (final sample in output.path.skip(1).take(7))
            PlanningMapMarker(
              bearingDegrees: sample.azimuthDegrees,
              altitudeDegrees: sample.altitudeDegrees,
              label: DateFormat('HH:mm').format(sample.instantUtc),
            ),
        ],
      ),
      PlanningView.augmentedReality => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LiveArView(
            azimuthDegrees: output.azimuthDegrees,
            altitudeDegrees: output.altitudeDegrees,
            // The Sun is a selectable night-sky target, so the live overlay must
            // repeat the certified-solar-filter warning inside the preview.
            isSun: _target == CelestialTarget.sun,
            northReference: northReference,
            magneticDeclinationDegrees: _value(_magneticDeclination),
          ),
        ),
      ),
    };
  }
}

/// The event list as a timeline: one row per rise, transit or set, with the
/// clock time in the plan's own zone and a connecting rail.
class _EventsTimeline extends StatelessWidget {
  const _EventsTimeline({
    required this.events,
    required this.timeZone,
    required this.onDark,
  });

  final List<CelestialEvent> events;
  final PlanningTimeContext timeZone;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text(
        'No rise, transit or set in the search window.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (index, event) in events.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 32,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _eventIcon(event.type),
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (index != events.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppGap.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 3,
                      bottom: index == events.length - 1 ? 0 : AppGap.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _eventLabel(event.type),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'HH:mm',
                          ).format(timeZone.localCivilTime(event.instantUtc)),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

IconData _eventIcon(CelestialEventType type) => switch (type) {
  CelestialEventType.rise => Icons.arrow_upward,
  CelestialEventType.transit => Icons.height,
  CelestialEventType.set => Icons.arrow_downward,
};

String _eventLabel(CelestialEventType type) => switch (type) {
  CelestialEventType.rise => 'Rises',
  CelestialEventType.transit => 'Transits',
  CelestialEventType.set => 'Sets',
};
