import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../planning/domain/planning_capabilities.dart';
import '../../planning/domain/planning_time_context.dart';
import '../../planning/domain/saved_location.dart';
import '../../planning/presentation/field_checklist.dart';
import '../../planning/presentation/live_ar_view.dart';
import '../../planning/presentation/live_compass_view.dart';
import '../../planning/presentation/offline_planning_map.dart';
import '../../planning/presentation/planning_context_card.dart';
import '../../planning/presentation/planning_field_controls.dart';
import '../domain/alignment_calculator.dart';
import 'alignment_timeline.dart';

class AlignmentScreen extends ConsumerStatefulWidget {
  const AlignmentScreen({this.capabilities, super.key});
  final PlanningCapabilities? capabilities;
  @override
  ConsumerState<AlignmentScreen> createState() => _AlignmentScreenState();
}

class _AlignmentScreenState extends ConsumerState<AlignmentScreen> {
  final _latitude = TextEditingController(text: '51.4779');
  final _longitude = TextEditingController(text: '0');
  final _observerElevation = TextEditingController(text: '20');
  final _targetElevation = TextEditingController(text: '820');
  final _targetDistance = TextEditingController(text: '1000');
  final _bearing = TextEditingController(text: '180');
  final _tolerance = TextEditingController(text: '3');
  final _targetLatitude = TextEditingController();
  final _targetLongitude = TextEditingController();
  final _magneticDeclination = TextEditingController(text: '0');
  var _body = AlignmentBody.sun;
  var _view = PlanningView.numeric;
  late DateTime _startLocalDate;
  late DateTime _endLocalDate;
  CalculationResult<AlignmentSearchOutput>? _result;
  Map<String, String> _errors = const {};
  Map<String, bool> _checklist = {
    'Verify terrain and weather': false,
    'Calibrate compass away from metal': false,
    'Confirm framing before the event': false,
    'Use certified solar filtration for Sun plans': false,
  };
  var _timeZoneId = 'UTC';
  SavedLocation? _selectedLocation;
  var _defaultsApplied = false;

  /// True once an input changed after a search, so the cleared result is
  /// explained rather than silently missing.
  var _stale = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _startLocalDate = DateTime(now.year, now.month, now.day);
    _endLocalDate = _startLocalDate;
  }

  @override
  void dispose() {
    for (final c in [
      _latitude,
      _longitude,
      _observerElevation,
      _targetElevation,
      _targetDistance,
      _bearing,
      _tolerance,
      _targetLatitude,
      _targetLongitude,
      _magneticDeclination,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    if (!_defaultsApplied && preferences != null) {
      _tolerance.text = _numberText(
        preferences.defaultAlignmentToleranceDegrees,
      );
      _defaultsApplied = true;
    }
    final theme = Theme.of(context);
    final savedLocations =
        ref.watch(savedLocationsProvider).valueOrNull ??
        const <SavedLocation>[];
    return PlanningWorkbench(
      // Pinned under the form rather than sitting at the end of it: the explicit
      // action must never cost a scroll through every field first.
      action: FilledButton.icon(
        key: const Key('alignment-search'),
        onPressed: _search,
        icon: const Icon(Icons.search),
        label: const Text('Find alignment'),
      ),
      body: CalculatorPage(
        inputControllers: [
          _latitude,
          _longitude,
          _observerElevation,
          _targetElevation,
          _targetDistance,
          _bearing,
          _tolerance,
          _magneticDeclination,
        ],
        onInputsChanged: () {
          // A changed input can no longer support the displayed search. Clearing
          // it is the only honest option: the result card must never describe
          // values it was not produced from. The guard also keeps the first
          // build's tolerance default from calling setState during a build.
          if (_result == null && _errors.isEmpty && !_stale) return;
          setState(_discardResult);
        },
        children: [
          const CalculatorHeader(
            icon: Icons.align_horizontal_left,
            description:
                'Line the Sun or Moon up with a bearing and elevation you can stand at. The search runs only when you ask, and everything is calculated offline.',
          ),
          PlanningSectionHeader(
            icon: Icons.place_outlined,
            title: 'Site and horizon',
            summary: PlanningLiveText(
              controllers: [_latitude, _longitude, _observerElevation],
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
                  if (location.elevationMetres != null) {
                    _observerElevation.text = location.elevationMetres
                        .toString();
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
                'Verify it before relying on horizon or terrain-limited candidates.',
              ),
            ),
          // Coordinates stay full width and exact: their labels are long enough
          // that a half-width column would wrap them, and a slider would only make
          // a precise latitude or longitude harder to read back. Their bounds are
          // stated by the labels and by the error line, not by a standing
          // paragraph over each field.
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
              controllers: [_observerElevation],
              text: _elevationSummary,
              style: theme.textTheme.bodySmall,
            ),
            children: <Widget>[
              CalculatorNumberField(
                label: 'Observer elevation (m)',
                controller: _observerElevation,
                errorText: _errors['observerElevationMetres'],
                presets: const [0, 50, 500, 2000],
                step: 10,
                helperText: 'Metres above sea level; terrain is not modeled.',
              ),
            ],
          ),
          PlanningSectionHeader(
            icon: Icons.event_outlined,
            title: 'When to look',
            summary: Text(_rangeSpanLabel(), style: theme.textTheme.bodySmall),
          ),
          InputDecorator(
            decoration: InputDecoration(
              labelText:
                  'Inclusive date range ($_timeZoneId, maximum one year)',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${DateFormat('yyyy-MM-dd').format(_startLocalDate)} to ${DateFormat('yyyy-MM-dd').format(_endLocalDate)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  PlanningTimeContext.parse(_timeZoneId).confidenceLabel,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppGap.sm),
                PlanningChipRow(chips: _rangeShortcuts()),
                const SizedBox(height: AppGap.sm),
                OutlinedButton.icon(
                  key: const Key('alignment-date-range'),
                  onPressed: _pickLocalDateRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: const Text('Choose local date range'),
                ),
              ],
            ),
          ),
          PlanningSectionHeader(
            icon: Icons.filter_center_focus,
            title: 'What to align',
          ),
          SegmentedButton<AlignmentBody>(
            segments: const [
              ButtonSegment(
                value: AlignmentBody.sun,
                label: Text('Sun'),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment(
                value: AlignmentBody.moon,
                label: Text('Moon'),
                icon: Icon(Icons.nightlight_outlined),
              ),
            ],
            selected: {_body},
            onSelectionChanged: (value) => setState(() {
              _body = value.first;
              _discardResult();
            }),
          ),
          if (_body == AlignmentBody.sun)
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
          const SizedBox(height: AppGap.md),
          CalculatorNumberField(
            label: 'Desired true bearing (degrees)',
            controller: _bearing,
            errorText: _errors['desiredBearingDegrees'],
            presets: const [0, 90, 180, 270],
            min: 0,
            max: 359.9,
            step: 1,
            helperText: '0° north, 90° east, 180° south, 270° west.',
          ),
          CalculatorNumberField(
            label: 'Angular tolerance (degrees)',
            controller: _tolerance,
            errorText: _errors['angularToleranceDegrees'],
            presets: const [0.5, 1, 3, 5, 10, 30],
            min: 0.1,
            max: 180,
            step: 0.1,
            helperText:
                'How close the body must come to the bearing. Exact entry accepts any value up to 180°.',
          ),
          Text(
            'Default: ${_numberText(preferences?.defaultAlignmentToleranceDegrees ?? 3)}° from Settings',
          ),
          PlanningSectionHeader(icon: Icons.straighten, title: 'Sight line'),
          CalculatorFieldPair(
            first: CalculatorNumberField(
              label: 'Target elevation (m)',
              controller: _targetElevation,
              errorText: _errors['targetElevationMetres'],
              presets: const [0, 20, 100, 500],
              step: 5,
              helperText: 'Height of the landmark above sea level.',
            ),
            second: CalculatorNumberField(
              label: 'Target distance (m)',
              controller: _targetDistance,
              errorText: _errors['targetDistanceMetres'],
              presets: const [100, 500, 1000, 5000],
              step: 10,
              helperText: 'Horizontal distance from you to the landmark.',
            ),
          ),
          CalculatorAdvancedSection(
            // Stable identity: applying equipment above must not collapse
            // the section the user is working in.
            key: const ValueKey('advanced'),
            children: <Widget>[
              Text(
                'Target coordinate',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                'Derive the bearing and distance from a second coordinate; the manual values above stay editable.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppGap.sm),
              CalculatorNumberField(
                label: 'Target latitude (degrees)',
                controller: _targetLatitude,
              ),
              CalculatorNumberField(
                label: 'Target longitude (degrees)',
                controller: _targetLongitude,
              ),
              OutlinedButton.icon(
                onPressed: _deriveTargetGeometry,
                icon: const Icon(Icons.route_outlined),
                label: const Text('Calculate geometry'),
              ),
              const SizedBox(height: AppGap.md),
              Text('Compass', style: Theme.of(context).textTheme.titleSmall),
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
                  'Inputs changed since the last search. Find alignment again to '
                  'see the windows for these values.',
            ),
          const SizedBox(height: AppGap.lg),
          if (_result?.output case final output?) ...[
            CalculationResultView(
              title: '${_body.name} alignment search',
              highlight: (
                'Best window',
                output.candidates.isEmpty
                    ? 'No matching window'
                    : PlanningTimeContext.parse(
                        _timeZoneId,
                      ).format(output.candidates.first.instantUtc),
              ),
              highlightCaption: output.candidates.isEmpty
                  ? '${_body.name} · bearing ${_bearing.text.trim()}° true · nothing inside the tolerance'
                  : '${_body.name} · bearing ${_bearing.text.trim()}° true · ${output.candidates.length} matching window${output.candidates.length == 1 ? '' : 's'}',
              tiles: <(String, String)>[
                if (output.candidates.isNotEmpty) ...[
                  (
                    'Azimuth',
                    '${output.candidates.first.azimuthDegrees.toStringAsFixed(0)}° true',
                  ),
                  (
                    'Altitude',
                    '${output.candidates.first.altitudeDegrees.toStringAsFixed(0)}°',
                  ),
                  (
                    'Angular error',
                    '${output.candidates.first.angularErrorDegrees.toStringAsFixed(2)}°',
                  ),
                ],
                ('Windows', '${output.candidates.length}'),
              ],
              details: <(String, String)>[
                (
                  'Target altitude',
                  '${output.desiredAltitudeDegrees.toStringAsFixed(1)}°',
                ),
                ('Search resolution', '${output.sampleMinutes} minutes'),
                for (final candidate in output.candidates)
                  (
                    PlanningTimeContext.parse(
                      _timeZoneId,
                    ).format(candidate.instantUtc),
                    'az ${candidate.azimuthDegrees.toStringAsFixed(1)}° · alt ${candidate.altitudeDegrees.toStringAsFixed(1)}° · error ${candidate.angularErrorDegrees.toStringAsFixed(2)}°',
                  ),
                if (output.candidates.isEmpty)
                  ('Best angular error', 'No match within tolerance'),
              ],
              inputs: [
                ('Body', _body.name),
                (
                  'Observer',
                  '${_latitude.text.trim()}°, ${_longitude.text.trim()}° · ${_observerElevation.text.trim()} m',
                ),
                (
                  'Target geometry',
                  '${_bearing.text.trim()}° true · ${_targetDistance.text.trim()} m · ${_targetElevation.text.trim()} m elevation',
                ),
                ('Angular tolerance', '${_tolerance.text.trim()}°'),
                (
                  'Date range',
                  '${DateFormat('yyyy-MM-dd').format(_startLocalDate)} to ${DateFormat('yyyy-MM-dd').format(_endLocalDate)} ($_timeZoneId)',
                ),
              ],
              assumptions: const [
                'True north and unobstructed geometric horizon',
                'Manual elevations; terrain and refraction are not modeled',
                'Ten-minute samples; confirm near the predicted time',
              ],
              warnings: [
                for (final warning in _result!.warnings)
                  calculationWarningText(warning.code),
              ],
              guidance: output.candidates.isEmpty
                  ? 'Increase the tolerance, adjust geometry, or try another date.'
                  : 'Review the best candidates below and verify terrain, weather, and composition on site.',
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
                showSelectedIcon: false,
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
                onSelectionChanged: (value) =>
                    setState(() => _view = value.first),
              ),
            ),
            const SizedBox(height: AppGap.md),
            _planningView(output),
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
      'Elevation ${_observerElevation.text.trim()} m · terrain is not modeled';

  String _rangeSpanLabel() {
    final days = _calendarDays(_startLocalDate, _endLocalDate);
    final span = days <= 1 ? '1 day' : '$days days';
    return '$span · $_timeZoneId';
  }

  /// Whole calendar days between two date carriers, counted in UTC so a
  /// daylight-saving transition can never shift the count by one.
  int _calendarDays(DateTime start, DateTime end) =>
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;

  /// The local calendar day a shortcut counts from: the planning zone's today,
  /// not the device's, so a saved site's range is never a day out.
  DateTime get _localToday {
    final local = PlanningTimeContext.parse(
      _timeZoneId,
    ).localCivilTime(DateTime.now().toUtc());
    return DateTime(local.year, local.month, local.day);
  }

  /// A local date carrier [days] after [date]; UTC does the arithmetic so a
  /// daylight-saving week still lands on the intended calendar day.
  DateTime _dayOffset(DateTime date, int days) {
    final shifted = DateTime.utc(date.year, date.month, date.day + days);
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  bool _rangeIs(DateTime start, DateTime end) =>
      _startLocalDate == start && _endLocalDate == end;

  List<Widget> _rangeShortcuts() {
    final today = _localToday;
    final tomorrow = _dayOffset(today, 1);
    final week = _dayOffset(today, 6);
    final month = _dayOffset(today, 29);
    final year = _dayOffset(today, 365);
    return <Widget>[
      PlanningShortcutChip(
        label: 'Today',
        selected: _rangeIs(today, today),
        onPressed: () => _setRange(today, today),
      ),
      PlanningShortcutChip(
        label: 'Tomorrow',
        selected: _rangeIs(tomorrow, tomorrow),
        onPressed: () => _setRange(tomorrow, tomorrow),
      ),
      PlanningShortcutChip(
        label: 'Next 7 days',
        selected: _rangeIs(today, week),
        onPressed: () => _setRange(today, week),
      ),
      PlanningShortcutChip(
        label: 'Next 30 days',
        selected: _rangeIs(today, month),
        onPressed: () => _setRange(today, month),
      ),
      PlanningShortcutChip(
        label: 'Next year',
        tooltip: 'The longest range the search accepts: about one year',
        selected: _rangeIs(today, year),
        onPressed: () => _setRange(today, year),
      ),
    ];
  }

  void _setRange(DateTime start, DateTime end) {
    if (_startLocalDate == start && _endLocalDate == end) return;
    setState(() {
      _startLocalDate = start;
      _endLocalDate = end;
      _discardResult();
    });
  }

  Widget _planningView(AlignmentSearchOutput output) {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AR unavailable',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${capabilities.augmentedRealityLimitation} Numeric, timeline, compass, and map plans remain fully usable; no permission is requested until a supported live view is opened.',
              ),
            ],
          ),
        ),
      );
    }
    if (output.candidates.isEmpty) {
      return const Text('No candidate positions to display.');
    }
    final best = output.candidates.first;
    return switch (_view) {
      PlanningView.numeric => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only the best windows here; the rest of the sampled grid lives in
          // the result card's Details so the default view stays scannable.
          for (final line in alignmentWindowLines(
            output.candidates,
            (candidate) => PlanningTimeContext.parse(
              _timeZoneId,
            ).format(candidate.instantUtc),
          ))
            Text(line),
        ],
      ),
      PlanningView.timeline => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best opportunities ${DateFormat('yyyy-MM-dd').format(_startLocalDate)} to ${DateFormat('yyyy-MM-dd').format(_endLocalDate)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          AlignmentTimeline(
            candidates: output.candidates.take(20).toList(growable: false),
            timeZoneId: _timeZoneId,
          ),
        ],
      ),
      PlanningView.compass => LiveCompassView(
        trueBearingDegrees: best.azimuthDegrees,
        magneticDeclinationDegrees: _value(_magneticDeclination),
        northReference: northReference,
      ),
      PlanningView.map => OfflinePlanningMap(
        desiredBearingDegrees: _value(_bearing),
        observerLabel:
            'Observer ${_latitude.text}, ${_longitude.text} · sight-line distance ${_targetDistance.text} m',
        markers: [
          for (final candidate in output.candidates.take(8))
            PlanningMapMarker(
              bearingDegrees: candidate.azimuthDegrees,
              altitudeDegrees: candidate.altitudeDegrees,
              label: PlanningTimeContext.parse(
                _timeZoneId,
              ).format(candidate.instantUtc),
              isPrimary: identical(candidate, best),
            ),
        ],
      ),
      PlanningView.augmentedReality => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LiveArView(
            azimuthDegrees: best.azimuthDegrees,
            altitudeDegrees: best.altitudeDegrees,
            isSun: _body == AlignmentBody.sun,
            northReference: northReference,
            magneticDeclinationDegrees: _value(_magneticDeclination),
          ),
        ),
      ),
    };
  }

  double _value(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? double.nan;
  void _deriveTargetGeometry() {
    try {
      final geometry = TargetGeometry.fromCoordinates(
        observerLatitudeDegrees: _value(_latitude),
        observerLongitudeDegrees: _value(_longitude),
        targetLatitudeDegrees: _value(_targetLatitude),
        targetLongitudeDegrees: _value(_targetLongitude),
      );
      setState(() {
        _bearing.text = geometry.bearingDegrees.toStringAsFixed(3);
        _targetDistance.text = geometry.distanceMetres.toStringAsFixed(1);
        _discardResult();
      });
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid observer and target coordinates.'),
        ),
      );
    }
  }

  void _search() {
    final range = _utcRange;
    final result = const AlignmentCalculator().search(
      AlignmentSearchInput(
        body: _body,
        observerLatitudeDegrees: _value(_latitude),
        observerLongitudeDegrees: _value(_longitude),
        observerElevationMetres: _value(_observerElevation),
        targetElevationMetres: _value(_targetElevation),
        targetDistanceMetres: _value(_targetDistance),
        desiredBearingDegrees: _value(_bearing),
        angularToleranceDegrees: _value(_tolerance),
        startUtc: range.startUtc,
        endUtc: range.endUtc,
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

  PlanningUtcRange get _utcRange => PlanningTimeContext.parse(
    _timeZoneId,
  ).inclusiveLocalDateRange(startDate: _startLocalDate, endDate: _endLocalDate);

  Future<void> _pickLocalDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startLocalDate,
        end: _endLocalDate,
      ),
      firstDate: DateTime(1800),
      lastDate: DateTime(2050, 12, 31),
      helpText: 'Choose inclusive dates · $_timeZoneId',
      saveText: 'Use range',
    );
    if (selected == null || !mounted) return;
    if (selected.end.difference(selected.start) > const Duration(days: 365)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a range of one year or less.')),
      );
      return;
    }
    setState(() {
      _startLocalDate = DateTime(
        selected.start.year,
        selected.start.month,
        selected.start.day,
      );
      _endLocalDate = DateTime(
        selected.end.year,
        selected.end.month,
        selected.end.day,
      );
      _discardResult();
    });
  }

  Future<void> _save(AlignmentSearchOutput output) => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${AlignmentCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: AlignmentCalculator.id,
      formulaVersion: AlignmentCalculator.version,
      createdAt: DateTime.now().toUtc(),
      title:
          '${_body.name} alignment ${DateFormat('yyyy-MM-dd').format(_startLocalDate)}',
      canonicalInputs: {
        'body': _body.name,
        'observerLatitudeDegrees': _value(_latitude),
        'observerLongitudeDegrees': _value(_longitude),
        'observerElevationMetres': _value(_observerElevation),
        'targetElevationMetres': _value(_targetElevation),
        'targetDistanceMetres': _value(_targetDistance),
        'desiredBearingDegrees': _value(_bearing),
        if (_targetLatitude.text.trim().isNotEmpty)
          'targetLatitudeDegrees': _value(_targetLatitude),
        if (_targetLongitude.text.trim().isNotEmpty)
          'targetLongitudeDegrees': _value(_targetLongitude),
        'angularToleranceDegrees': _value(_tolerance),
        'magneticDeclinationDegrees': _value(_magneticDeclination),
        'startLocalDate': DateFormat('yyyy-MM-dd').format(_startLocalDate),
        'endLocalDate': DateFormat('yyyy-MM-dd').format(_endLocalDate),
        'startUtc': _utcRange.startUtc.toIso8601String(),
        'endUtc': _utcRange.endUtc.toIso8601String(),
      },
      canonicalOutputs: {
        'desiredAltitudeDegrees': output.desiredAltitudeDegrees,
        'sampleMinutes': output.sampleMinutes,
        'candidates': [
          for (final c in output.candidates)
            {
              'instantUtc': c.instantUtc.toIso8601String(),
              'azimuthDegrees': c.azimuthDegrees,
              'altitudeDegrees': c.altitudeDegrees,
              'angularErrorDegrees': c.angularErrorDegrees,
              'aboveHorizon': c.aboveHorizon,
            },
        ],
        'fieldChecklist': _checklist.entries
            .map((entry) => {'task': entry.key, 'complete': entry.value})
            .toList(growable: false),
      },
      displayContext: {
        'timeZone': _timeZoneId,
        'northReference': 'true',
        'requestedNorthReference':
            ref.read(preferencesProvider).valueOrNull?.northReference.name ??
            NorthReference.trueNorth.name,
        'magneticDeclinationDegrees': _value(_magneticDeclination),
        'mapMode': 'offlineSchematic',
        'locationLabel': _locationLabel,
        'locationSource': _locationSource,
        'locationAccuracyMetres': ?_selectedLocation?.accuracyMetres,
        'timeZoneConfidence': PlanningTimeContext.parse(
          _timeZoneId,
        ).confidenceLabel,
        'observerElevationMetres': _value(_observerElevation),
        'targetElevationMetres': _value(_targetElevation),
        'horizon': 'unobstructed geometric horizon',
        'refraction': 'not applied',
        'sourceFreshness': 'Bundled formula v${AlignmentCalculator.version}',
        'expectedAccuracy': _expectedAccuracy,
      },
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
    ),
  );
  void _reset() {
    _latitude.text = '51.4779';
    _longitude.text = '0';
    _observerElevation.text = '20';
    _targetElevation.text = '820';
    _targetDistance.text = '1000';
    _bearing.text = '180';
    _tolerance.text = _numberText(
      ref
              .read(preferencesProvider)
              .valueOrNull
              ?.defaultAlignmentToleranceDegrees ??
          3,
    );
    _targetLatitude.clear();
    _targetLongitude.clear();
    _magneticDeclination.text = '0';
    setState(() {
      _body = AlignmentBody.sun;
      _view = PlanningView.numeric;
      _endLocalDate = _startLocalDate;
      _selectedLocation = null;
      _timeZoneId = 'UTC';
      _result = null;
      _stale = false;
      _errors = const {};
    });
  }

  String _numberText(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  String get _locationLabel =>
      _selectedLocation?.name ?? '${_latitude.text}, ${_longitude.text}';

  String get _locationSource {
    final location = _selectedLocation;
    if (location == null) return 'Manual coordinates';
    final accuracy = location.accuracyMetres;
    return '${location.source.name}${accuracy == null ? '' : ' · ±${accuracy.toStringAsFixed(0)} m reported accuracy'}';
  }

  /// Elevations are entered and stored in metres; only their presentation
  /// follows the saved length preference (FR-020).
  String _metres(String text) {
    final value = double.tryParse(text.trim());
    if (value == null || !value.isFinite) return '$text m';
    final display =
        ref.watch(preferencesProvider).valueOrNull?.lengthDisplay ??
        LengthDisplay.metric;
    return formatDisplayLength(value * 1000, display);
  }

  String get _expectedAccuracy => _body == AlignmentBody.sun
      ? 'About ±1° position; candidate times sampled every 10 minutes. Geocentric model: topocentric parallax is not applied.'
      : 'About ±1.5° position; candidate times sampled every 10 minutes. Geocentric model: lunar parallax up to about 1° is not applied, which is inside this tolerance.';

  Widget _planningContext() {
    final time = PlanningTimeContext.parse(_timeZoneId);
    final north =
        ref.watch(preferencesProvider).valueOrNull?.northReference ??
        NorthReference.trueNorth;
    return PlanningContextCard(
      entries: [
        ('Location', _locationLabel),
        ('Location source', _locationSource),
        (
          'Local range',
          '${DateFormat('yyyy-MM-dd').format(_startLocalDate)} to ${DateFormat('yyyy-MM-dd').format(_endLocalDate)} · $_timeZoneId',
        ),
        ('Time-zone rules', time.confidenceLabel),
        (
          'Elevations',
          'observer ${_metres(_observerElevation.text)} · target ${_metres(_targetElevation.text)}',
        ),
        (
          'North reference',
          'Calculated in true north · compass preference ${north.name}',
        ),
        ('Horizon / refraction', 'Unobstructed geometric horizon · none'),
        (
          'Source freshness',
          'Bundled formula v${AlignmentCalculator.version}; no remote data',
        ),
        ('Expected accuracy', _expectedAccuracy),
      ],
    );
  }
}

/// One-line numeric summary of a candidate, including whether it is actually
/// above the geometric horizon.
String alignmentCandidateSummary(
  AlignmentCandidate candidate,
  String formattedLocalTime,
) =>
    '$formattedLocalTime — az ${candidate.azimuthDegrees.toStringAsFixed(1)}°, '
    'alt ${candidate.altitudeDegrees.toStringAsFixed(1)}°, '
    'error ${candidate.angularErrorDegrees.toStringAsFixed(2)}° · '
    '${candidate.aboveHorizon ? 'above horizon' : 'below horizon'}';

/// Windows the numeric planning view lists inline before the remainder moves
/// into the collapsed candidate table.
const int numericWindowPreviewLimit = 3;

/// Builds the numeric view's window lines.
///
/// The best [numericWindowPreviewLimit] candidates are summarised and, when the
/// search found more, a count line names the total so matches are never
/// silently hidden; the full sampled grid stays in the result card's Details.
List<String> alignmentWindowLines(
  List<AlignmentCandidate> candidates,
  String Function(AlignmentCandidate candidate) formatInstant,
) => <String>[
  for (final candidate in candidates.take(numericWindowPreviewLimit))
    alignmentCandidateSummary(candidate, formatInstant(candidate)),
  if (candidates.length > numericWindowPreviewLimit)
    '$numericWindowPreviewLimit of ${candidates.length} windows shown · '
        'open Details for the full list.',
];
