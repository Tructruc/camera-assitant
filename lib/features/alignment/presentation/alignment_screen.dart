import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../planning/domain/planning_capabilities.dart';
import '../../planning/domain/planning_time_context.dart';
import '../../planning/domain/saved_location.dart';
import '../../planning/presentation/field_checklist.dart';
import '../../planning/presentation/live_ar_view.dart';
import '../../planning/presentation/live_compass_view.dart';
import '../../planning/presentation/offline_planning_map.dart';
import '../../planning/presentation/planning_context_card.dart';
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
    return CalculatorPage(
      children: [
        Text(
          'Sun & Moon alignment',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Search up to one year for the closest bearing and elevation match. All calculations run offline.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SavedLocation>(
          key: ValueKey(_selectedLocation?.id ?? 'manual-location'),
          decoration: const InputDecoration(
            labelText: 'Saved location (optional)',
          ),
          items: [
            for (final location
                in ref.watch(savedLocationsProvider).valueOrNull ??
                    const <SavedLocation>[])
              DropdownMenuItem(value: location, child: Text(location.name)),
          ],
          initialValue: _selectedLocation,
          onChanged: (location) {
            if (location == null) return;
            setState(() {
              _latitude.text = location.latitudeDegrees.toString();
              _longitude.text = location.longitudeDegrees.toString();
              if (location.elevationMetres != null) {
                _observerElevation.text = location.elevationMetres.toString();
              }
              _timeZoneId = location.timeZoneId;
              _selectedLocation = location;
              _result = null;
            });
          },
        ),
        const SizedBox(height: 12),
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
            _result = null;
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
        CalculatorNumberField(
          label: 'Observer elevation (m)',
          controller: _observerElevation,
          errorText: _errors['observerElevationMetres'],
        ),
        CalculatorNumberField(
          label: 'Target elevation (m)',
          controller: _targetElevation,
          errorText: _errors['targetElevationMetres'],
        ),
        CalculatorNumberField(
          label: 'Target distance (m)',
          controller: _targetDistance,
          errorText: _errors['targetDistanceMetres'],
        ),
        CalculatorNumberField(
          label: 'Desired true bearing (degrees)',
          controller: _bearing,
          errorText: _errors['desiredBearingDegrees'],
        ),
        ExpansionTile(
          title: const Text('Target coordinate'),
          subtitle: const Text(
            'Derive bearing and distance; manual values remain editable.',
          ),
          children: [
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
          ],
        ),
        CalculatorNumberField(
          label: 'Angular tolerance (degrees)',
          controller: _tolerance,
          errorText: _errors['angularToleranceDegrees'],
        ),
        Text(
          'Default: ${_numberText(preferences?.defaultAlignmentToleranceDegrees ?? 3)}° from Settings',
        ),
        CalculatorNumberField(
          label: 'Magnetic declination, east positive (degrees)',
          controller: _magneticDeclination,
        ),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Inclusive date range ($_timeZoneId, maximum one year)',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${DateFormat('yyyy-MM-dd').format(_startLocalDate)} to ${DateFormat('yyyy-MM-dd').format(_endLocalDate)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                PlanningTimeContext.parse(_timeZoneId).confidenceLabel,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('alignment-date-range'),
                onPressed: _pickLocalDateRange,
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('Choose local date range'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('alignment-search'),
          onPressed: _search,
          child: const Text('Search alignments'),
        ),
        const SizedBox(height: 16),
        if (_result?.output case final output?) ...[
          _planningContext(),
          CalculationResultView(
            title: '${_body.name} alignment search',
            rows: [
              (
                'Target altitude',
                '${output.desiredAltitudeDegrees.toStringAsFixed(1)}°',
              ),
              ('Candidates', '${output.candidates.length}'),
              ('Search resolution', '${output.sampleMinutes} minutes'),
              (
                'Best angular error',
                output.candidates.isEmpty
                    ? 'No match within tolerance'
                    : '${output.candidates.first.angularErrorDegrees.toStringAsFixed(2)}°',
              ),
            ],
            assumptions: const [
              'True north and unobstructed geometric horizon',
              'Manual elevations; terrain and refraction are not modeled',
              'Ten-minute samples; confirm near the predicted time',
            ],
            guidance: output.candidates.isEmpty
                ? 'Increase the tolerance, adjust geometry, or try another date.'
                : 'Review the best candidates below and verify terrain, weather, and composition on site.',
            onSave: () => _save(output),
            onReset: _reset,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _planningView(output),
          FieldChecklist(
            items: _checklist,
            onChanged: (items) => setState(() => _checklist = items),
          ),
        ],
      ],
    );
  }

  Widget _planningView(AlignmentSearchOutput output) {
    final northReference =
        ref.watch(preferencesProvider).valueOrNull?.northReference ??
        NorthReference.trueNorth;
    if (_view == PlanningView.augmentedReality &&
        widget.capabilities != null &&
        !widget.capabilities!.canShowAr) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AR unavailable',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'This device or session does not provide the required camera and orientation capabilities. Numeric, timeline, compass, and map plans remain fully usable; no permission is requested until a supported live view is opened.',
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
          for (final candidate in output.candidates.take(8))
            Text(
              '${PlanningTimeContext.parse(_timeZoneId).format(candidate.instantUtc)} — az ${candidate.azimuthDegrees.toStringAsFixed(1)}°, alt ${candidate.altitudeDegrees.toStringAsFixed(1)}°, error ${candidate.angularErrorDegrees.toStringAsFixed(2)}°',
            ),
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
        _result = null;
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
      _result = null;
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

  String get _expectedAccuracy => _body == AlignmentBody.sun
      ? 'About ±1° position; candidate times sampled every 10 minutes'
      : 'About ±1.5° position; candidate times sampled every 10 minutes';

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
          'observer ${_observerElevation.text} m · target ${_targetElevation.text} m',
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
