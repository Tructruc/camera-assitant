import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../planning/domain/north_reference.dart';
import '../../planning/domain/planning_capabilities.dart';
import '../../planning/domain/planning_time_context.dart';
import '../../planning/domain/saved_location.dart';
import '../../planning/presentation/field_checklist.dart';
import '../../planning/presentation/live_ar_view.dart';
import '../domain/alignment_calculator.dart';

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
  late DateTime _startUtc;
  late DateTime _endUtc;
  CalculationResult<AlignmentSearchOutput>? _result;
  Map<String, String> _errors = const {};
  Map<String, bool> _checklist = {
    'Verify terrain and weather': false,
    'Calibrate compass away from metal': false,
    'Confirm framing before the event': false,
    'Use certified solar filtration for Sun plans': false,
  };
  var _timeZoneId = 'UTC';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _startUtc = DateTime.utc(now.year, now.month, now.day);
    _endUtc = _startUtc.add(const Duration(days: 1));
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
  Widget build(BuildContext context) => CalculatorPage(
    children: [
      Text(
        'Sun & Moon alignment',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Search one UTC day for the closest bearing and elevation match. All calculations run offline.',
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<SavedLocation>(
        decoration: const InputDecoration(
          labelText: 'Saved location (optional)',
        ),
        items: [
          for (final location
              in ref.watch(savedLocationsProvider).valueOrNull ??
                  const <SavedLocation>[])
            DropdownMenuItem(value: location, child: Text(location.name)),
        ],
        onChanged: (location) {
          if (location == null) return;
          setState(() {
            _latitude.text = location.latitudeDegrees.toString();
            _longitude.text = location.longitudeDegrees.toString();
            if (location.elevationMetres != null) {
              _observerElevation.text = location.elevationMetres.toString();
            }
            _timeZoneId = location.timeZoneId;
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
      CalculatorNumberField(
        label: 'Magnetic declination, east positive (degrees)',
        controller: _magneticDeclination,
      ),
      InputDecorator(
        decoration: const InputDecoration(labelText: 'Start date (UTC)'),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous day',
              onPressed: () => _shiftStartDay(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('yyyy-MM-dd').format(_startUtc),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              onPressed: () => _shiftStartDay(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      InputDecorator(
        decoration: const InputDecoration(
          labelText: 'End date (UTC, maximum 31 days)',
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'End one day earlier',
              onPressed: () => _shiftEndDay(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('yyyy-MM-dd').format(_endUtc),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'End one day later',
              onPressed: () => _shiftEndDay(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _search, child: const Text('Search alignments')),
      const SizedBox(height: 16),
      if (_result?.output case final output?) ...[
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
            onSelectionChanged: (value) => setState(() => _view = value.first),
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
    final magneticBearing = NorthReferenceBearing.trueToMagnetic(
      best.azimuthDegrees,
      _value(_magneticDeclination),
    );
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
            'Best opportunities ${DateFormat('yyyy-MM-dd').format(_startUtc)} to ${DateFormat('yyyy-MM-dd').format(_endUtc)}',
          ),
          for (final candidate in output.candidates.take(8))
            LinearProgressIndicator(
              value:
                  1 -
                  (candidate.angularErrorDegrees / _value(_tolerance)).clamp(
                    0,
                    1,
                  ),
              semanticsLabel:
                  '${DateFormat('HH:mm').format(candidate.instantUtc)} alignment closeness',
            ),
        ],
      ),
      PlanningView.compass => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Transform.rotate(
                  angle: best.azimuthDegrees * 3.141592653589793 / 180,
                  child: const Icon(Icons.navigation, size: 72),
                ),
                Text('${best.azimuthDegrees.toStringAsFixed(1)}° true north'),
                Text(
                  northReference == NorthReference.magneticNorth
                      ? '${magneticBearing.toStringAsFixed(1)}° magnetic using ${_value(_magneticDeclination).toStringAsFixed(1)}° east declination.'
                      : 'True north selected. Device magnetic headings require local declination and calibration.',
                ),
              ],
            ),
          ),
        ),
      ),
      PlanningView.map => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offline schematic map',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Observer: ${_latitude.text}, ${_longitude.text}'),
              Text(
                'Sight line: ${_bearing.text}° true for ${_targetDistance.text} m',
              ),
              const Text(
                'No terrain or downloaded map tiles are available; coordinates and geometry remain usable.',
              ),
            ],
          ),
        ),
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
        startUtc: _startUtc,
        endUtc: _endUtc,
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

  void _shiftStartDay(int days) => setState(() {
    _startUtc = _startUtc.add(Duration(days: days));
    _result = null;
  });
  void _shiftEndDay(int days) => setState(() {
    _endUtc = _endUtc.add(Duration(days: days));
    _result = null;
  });
  Future<void> _save(AlignmentSearchOutput output) => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${AlignmentCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: AlignmentCalculator.id,
      formulaVersion: AlignmentCalculator.version,
      createdAt: DateTime.now().toUtc(),
      title:
          '${_body.name} alignment ${DateFormat('yyyy-MM-dd').format(_startUtc)}',
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
        'startUtc': _startUtc.toIso8601String(),
        'endUtc': _endUtc.toIso8601String(),
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
    _tolerance.text = '3';
    _targetLatitude.clear();
    _targetLongitude.clear();
    _magneticDeclination.text = '0';
    setState(() {
      _body = AlignmentBody.sun;
      _view = PlanningView.numeric;
      _endUtc = _startUtc.add(const Duration(days: 1));
      _result = null;
      _errors = const {};
    });
  }
}
