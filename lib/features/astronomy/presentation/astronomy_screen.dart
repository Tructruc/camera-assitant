import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../../planning/domain/planning_capabilities.dart';
import '../../planning/domain/planning_time_context.dart';
import '../../planning/domain/saved_location.dart';
import '../../planning/presentation/field_checklist.dart';
import '../../planning/presentation/live_ar_view.dart';
import '../../planning/presentation/live_compass_view.dart';
import '../../planning/presentation/offline_planning_map.dart';
import '../domain/astronomy_calculator.dart';

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
    final equipment = ref.watch(equipmentControllerProvider).items;
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
    return CalculatorPage(
      children: [
        Text(
          'Night-sky planner',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Plan celestial targets entirely offline. Calculations use UTC and bearings use true north; saved locations can display local civil time.',
        ),
        const SizedBox(height: 16),
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
              _elevation.text = (location.elevationMetres ?? 0).toString();
              _timeZoneId = location.timeZoneId;
              _result = null;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownMenu<CelestialTarget>(
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
          onSelected: (value) => setState(() {
            _target = value ?? _target;
            _result = null;
          }),
        ),
        const SizedBox(height: 12),
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
          controller: _elevation,
          errorText: _errors['observerElevationMetres'],
        ),
        _planningTimeControl(),
        CalculatorNumberField(
          label: 'Magnetic declination, east positive (degrees)',
          controller: _magneticDeclination,
        ),
        const SizedBox(height: 12),
        EquipmentPicker<CameraBody>(
          label: 'Saved camera (optional)',
          items: cameras,
          itemLabel: (item) => item.name,
          value: _camera,
          onSelected: (camera) => setState(() {
            _camera = camera;
            _result = null;
          }),
        ),
        EquipmentPicker<Lens>(
          label: 'Saved lens (optional)',
          items: lenses,
          itemLabel: (item) => item.name,
          value: _lens,
          onSelected: _applyLens,
        ),
        if (_lens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            appliedValues: '${_focalLength.text} mm focal length',
          ),
        CalculatorNumberField(
          label: 'Focal length (mm)',
          controller: _focalLength,
          errorText: _errors['focalLengthMm'],
        ),
        CalculatorNumberField(
          label: 'Crop factor',
          controller: _cropFactor,
          errorText: _errors['cropFactor'],
        ),
        CalculatorNumberField(
          label: 'Aperture (f-number)',
          controller: _aperture,
          errorText: _errors['aperture'],
        ),
        CalculatorNumberField(
          label: 'Pixel pitch (µm)',
          controller: _pixelPitch,
          errorText: _errors['pixelPitchMicrometres'],
        ),
        CalculatorNumberField(
          label: 'Desired star-trail arc (degrees)',
          controller: _trailDegrees,
          errorText: _errors['desiredTrailDegrees'],
        ),
        DropdownButtonFormField<StarShutterRule>(
          decoration: const InputDecoration(labelText: 'Sharp-star rule'),
          initialValue: _shutterRule,
          items: const [
            DropdownMenuItem(
              value: StarShutterRule.npf,
              child: Text('NPF rule'),
            ),
            DropdownMenuItem(
              value: StarShutterRule.rule500,
              child: Text('500 rule'),
            ),
          ],
          onChanged: (value) => setState(() {
            _shutterRule = value ?? _shutterRule;
            _result = null;
          }),
        ),
        const SizedBox(height: 12),
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
            _result = null;
          }),
        ),
        FilledButton(
          onPressed: _calculate,
          child: const Text('Plan night sky'),
        ),
        const SizedBox(height: 16),
        if (_result?.output case final output?) ...[
          Builder(
            builder: (context) {
              final time = PlanningTimeContext.parse(_timeZoneId);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Location ${_latitude.text}, ${_longitude.text} · elevation ${_elevation.text} m · ${time.timeZoneId}\n${time.confidenceLabel}\nTrue north · geometric horizon · planning accuracy · offline catalog bundled 2026-08-21',
                  ),
                ),
              );
            },
          ),
          CalculationResultView(
            title: '${_target.label} plan',
            rows: [
              (
                'Altitude',
                '${output.altitudeDegrees.toStringAsFixed(1)}° (${output.isAboveHorizon ? 'above horizon' : 'below horizon'})',
              ),
              ('Azimuth', '${output.azimuthDegrees.toStringAsFixed(1)}° true'),
              ('Visibility cycle', _cycle(output.visibilityCycle)),
              (
                '500 rule',
                '${output.rule500Seconds.toStringAsFixed(1)} seconds',
              ),
              ('NPF rule', '${output.npfSeconds.toStringAsFixed(1)} seconds'),
              (
                'Recommended (${_shutterRule == StarShutterRule.npf ? 'NPF' : '500'}, ${_sharpnessTolerance.name})',
                '${output.recommendedShutterSeconds.toStringAsFixed(1)} seconds',
              ),
              (
                '${_value(_trailDegrees).toStringAsFixed(0)}° star trail',
                _duration(output.trailDurationSeconds),
              ),
            ],
            assumptions: [
              _target.isMoving
                  ? 'JPL 1800–2050 approximate Keplerian model; moving-target events are solved against updated coordinates and remain planning-grade'
                  : 'Fixed ICRS/J2000 target coordinates',
              'Airless geometric horizon; terrain and refraction excluded',
              'Approximate mean sidereal time and planning-grade exposure rules',
            ],
            guidance:
                'The 500 and NPF values are estimates: inspect stars at your intended output size. Event times are UTC and ignore terrain, refraction, precession, and proper motion.',
            onSave: () => _save(output),
            onReset: _reset,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 8),
          _planningView(output),
          const SizedBox(height: 12),
          Text('Next events', style: Theme.of(context).textTheme.titleMedium),
          for (final event in output.events)
            Text(
              '${event.type.name}: ${PlanningTimeContext.parse(_timeZoneId).format(event.instantUtc)}',
            ),
          const SizedBox(height: 12),
          Text(
            '12-hour sky path',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text('Two-hour samples · altitude / azimuth true north'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final sample in output.path)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: Chip(
                      label: Text(
                        '${DateFormat('HH:mm').format(sample.instantUtc)} UTC\n${sample.altitudeDegrees.toStringAsFixed(0)}° / ${sample.azimuthDegrees.toStringAsFixed(0)}°',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          FieldChecklist(
            items: _checklist,
            onChanged: (items) => setState(() => _checklist = items),
          ),
        ],
      ],
    );
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
      _errors = {
        for (final error in result.errors)
          error.field: 'Enter a finite value within the supported range.',
      };
    });
  }

  void _shiftTime(int hours) => setState(() {
    _instantUtc = _instantUtc.add(Duration(hours: hours));
    _result = null;
  });

  Widget _planningTimeControl() {
    final time = PlanningTimeContext.parse(_timeZoneId);
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
          Text(
            '${DateFormat("yyyy-MM-dd HH:mm 'UTC'").format(_instantUtc)} · ${time.confidenceLabel}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
              const Text('Adjust one hour'),
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
      _result = null;
    });
  }

  void _applyLens(Lens? lens) => setState(() {
    _lens = lens;
    if (lens != null) _focalLength.text = lens.minimumFocalLengthMm.toString();
    _result = null;
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
        'rightAscensionDegrees': _target.equatorialAt(_instantUtc).$1,
        'declinationDegrees': _target.equatorialAt(_instantUtc).$2,
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
        'azimuthReference': 'trueNorth',
        'requestedNorthReference':
            ref.read(preferencesProvider).valueOrNull?.northReference.name ??
            NorthReference.trueNorth.name,
        'magneticDeclinationDegrees': _value(_magneticDeclination),
        'angleUnit': 'degrees',
      },
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
      equipment: [
        if (_camera case final camera?)
          _equipment(camera, SnapshotEquipmentType.camera, {
            'sensorWidthMm': camera.sensorWidthMm,
            'sensorHeightMm': camera.sensorHeightMm,
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
  };
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
      _sharpnessTolerance = StarSharpnessTolerance.balanced;
      _view = PlanningView.numeric;
      _camera = null;
      _lens = null;
      _result = null;
      _errors = const {};
    });
  }

  Widget _planningView(AstronomyOutput output) {
    final northReference =
        ref.watch(preferencesProvider).valueOrNull?.northReference ??
        NorthReference.trueNorth;
    if (_view == PlanningView.augmentedReality &&
        widget.capabilities != null &&
        !widget.capabilities!.canShowAr) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'AR unavailable. Numeric, timeline, compass, and offline-map views remain usable without camera or orientation permission.',
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
            'Observer ${_latitude.text}, ${_longitude.text} · ${_elevation.text} m',
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
            isSun: false,
            northReference: northReference,
            magneticDeclinationDegrees: _value(_magneticDeclination),
          ),
        ),
      ),
    };
  }
}
