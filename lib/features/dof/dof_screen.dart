import 'dart:math' as math;

import 'package:camera_assistant/app/app_dependencies.dart';
import 'package:camera_assistant/core/formatting/length_formatter.dart';
import 'package:camera_assistant/core/parsing/number_parser.dart';
import 'package:camera_assistant/data/lenses/sqlite_lens_repository.dart';
import 'package:camera_assistant/domain/calculators/dof_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/features/dof/dof_controller.dart';
import 'package:camera_assistant/features/dof/dof_state.dart';
import 'package:camera_assistant/features/dof/widgets/dof_metric_pill.dart';
import 'package:camera_assistant/screens/focus_stacking/focus_stacking_planner_screen.dart';
import 'package:camera_assistant/shared/lenses/lens_selection_controller.dart';
import 'package:camera_assistant/shared/lenses/lens_selection_state.dart';
import 'package:camera_assistant/shared/widgets/lens_value_slider.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

class DofScreen extends StatefulWidget {
  const DofScreen({
    super.key,
    this.settings = const AppSettings(),
  });

  final AppSettings settings;

  @override
  State<DofScreen> createState() => _DofScreenState();
}

class _DofScreenState extends State<DofScreen> {
  final _dofController = const DofController();
  final _focalMm = TextEditingController(text: '50');
  final _aperture = TextEditingController(text: '2.8');
  final _subjectDistanceM = TextEditingController(text: '3');

  late SensorPreset _selectedSensor;
  LensSelectionController? _lensSelection;
  LensSelectionState _lensSelectionState = const LensSelectionState();

  String? _errorMessage;
  DofResult? _result;

  List<SensorPreset> get _availableSensors =>
      resolveEnabledSensorPresets(widget.settings.enabledSensorIds);

  List<Lens> get _lenses => _lensSelectionState.lenses;

  int? get _selectedLensId => _lensSelectionState.selectedLensId;

  Lens? get _selectedLens => _lensSelectionState.selectedLens;

  @override
  void initState() {
    super.initState();
    _selectedSensor = _availableSensors.first;
    _focalMm.addListener(_onInputChanged);
    _aperture.addListener(_onInputChanged);
    _subjectDistanceM.addListener(_onInputChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lensSelection != null) {
      return;
    }

    _lensSelection = LensSelectionController(
      repository: AppDependenciesScope.maybeOf(context)?.lenses ??
          SqliteLensRepository(),
    );
    _loadLenses();
  }

  @override
  void dispose() {
    _focalMm.removeListener(_onInputChanged);
    _aperture.removeListener(_onInputChanged);
    _subjectDistanceM.removeListener(_onInputChanged);
    _focalMm.dispose();
    _aperture.dispose();
    _subjectDistanceM.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _calculate(live: true);
  }

  Future<void> _loadLenses() async {
    final controller = _lensSelection;
    if (controller == null) {
      return;
    }

    setState(() {
      _lensSelectionState = controller.state.copyWith(loading: true);
    });

    final state = await controller.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _lensSelectionState = state;
    });
  }

  void _clearSelectedLens() {
    setState(() {
      _lensSelectionState =
          _lensSelection?.clearSelection() ?? const LensSelectionState();
    });
    _calculate(live: true);
  }

  void _applyLens(Lens lens) {
    final focal = lens.minFocalLengthMm;
    final minApertureAtFocal =
        _lensSelection?.minApertureAtFocal(lens, focal) ??
            lens.minApertureAtFocal(focal);

    setState(() {
      _lensSelectionState =
          _lensSelection?.selectLens(lens) ?? _lensSelectionState;
      _focalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      _aperture.text = minApertureAtFocal.toStringAsFixed(1);
      if ((parseDouble(_subjectDistanceM.text) ?? 0) < lens.minFocusDistanceM) {
        _subjectDistanceM.text = lens.minFocusDistanceM.toStringAsFixed(2);
      }
    });
    _calculate(live: true);
  }

  void _updateLensFocal(double value) {
    final lens = _selectedLens;
    final lensSelection = _lensSelection;
    if (lens == null) {
      return;
    }
    final focal = lensSelection?.clampFocalLength(lens, value) ??
        value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    final currentAperture =
        parseDouble(_aperture.text) ?? lens.minApertureAtFocal(focal);
    final minAtFocal = lensSelection?.minApertureAtFocal(lens, focal) ??
        lens.minApertureAtFocal(focal);

    setState(() {
      _focalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      if (currentAperture < minAtFocal) {
        _aperture.text = minAtFocal.toStringAsFixed(1);
      }
    });
    _calculate(live: true);
  }

  void _updateLensAperture(double value) {
    final lens = _selectedLens;
    final lensSelection = _lensSelection;
    if (lens == null) {
      return;
    }
    final focal = parseDouble(_focalMm.text) ?? lens.minFocalLengthMm;
    final aperture = lensSelection?.clampApertureAtFocal(
          lens,
          focalMm: focal,
          aperture: value,
        ) ??
        value.clamp(lens.minApertureAtFocal(focal), lens.maxAperture);

    setState(() {
      _aperture.text = aperture.toStringAsFixed(1);
    });
    _calculate(live: true);
  }

  void _updateSubjectDistance(double value, {double? maxDistance}) {
    final lens = _selectedLens;
    final minDistance = lens?.minFocusDistanceM ?? 0.05;
    final clamped = value.clamp(minDistance, maxDistance ?? 120.0);
    setState(() {
      _subjectDistanceM.text = clamped.toStringAsFixed(2);
    });
    _calculate(live: true);
  }

  double _focusDistanceMax({
    required Lens lens,
    required double focalMm,
    required double aperture,
  }) {
    final fM = focalMm / 1000;
    final cM = _selectedSensor.cocMm / 1000;
    final hyperfocalM = DOFCalculator.computeHyperfocal(fM, aperture, cM);
    return (hyperfocalM * 3).clamp(lens.minFocusDistanceM + 1.0, 500.0);
  }

  void _calculate({bool live = false}) {
    final state = _dofController.calculate(
      DofInput(
        focalLengthMm: parseDouble(_focalMm.text),
        aperture: parseDouble(_aperture.text),
        subjectDistanceM: parseDouble(_subjectDistanceM.text),
        sensor: _selectedSensor,
        lens: _selectedLens,
      ),
      live: live,
    );

    switch (state) {
      case DofCalculationSuccess(:final result):
        setState(() {
          _errorMessage = null;
          _result = result;
        });
      case DofCalculationError(:final message):
        setState(() {
          _errorMessage = message;
          _result = null;
        });
    }
  }

  void _openFocusStackingPlanner() {
    final result = _result;
    if (result == null) {
      return;
    }

    final farDistanceM = result.farLimitM ??
        (result.subjectDistanceM +
            (result.subjectDistanceM - result.nearLimitM));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusStackingPlannerScreen(
          settings: widget.settings,
          initialPreset: FocusStackingPreset.standard(
            method: FocusStackingMethod.refocusLens,
            lensId: _selectedLensId,
            sensorCocMm: _selectedSensor.cocMm,
            focalMm: parseDouble(_focalMm.text),
            aperture: parseDouble(_aperture.text),
            nearDistanceM: result.nearLimitM,
            farDistanceM: farDistanceM,
            overlapPercent: 30,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lens = _selectedLens;
    final focalValue =
        parseDouble(_focalMm.text) ?? (lens?.minFocalLengthMm ?? 50);
    final minApertureAtFocal = lens?.minApertureAtFocal(focalValue) ?? 1.0;
    final apertureValue =
        parseDouble(_aperture.text) ?? (lens?.minApertureWide ?? 2.8);
    final subjectDistanceValue =
        parseDouble(_subjectDistanceM.text) ?? (lens?.minFocusDistanceM ?? 3);
    final focusMaxDistance = lens == null
        ? 120.0
        : _focusDistanceMax(
            lens: lens,
            focalMm: focalValue,
            aperture: apertureValue.clamp(minApertureAtFocal, lens.maxAperture),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SectionCard(
            title: 'Lens',
            children: [
              DropdownButtonFormField<int>(
                key: ValueKey(_selectedLensId),
                initialValue: _selectedLensId,
                isExpanded: true,
                hint: const Text('Use a saved lens'),
                items: _lenses
                    .map(
                      (lens) => DropdownMenuItem<int>(
                        value: lens.id,
                        child: Text(
                          lens.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (context) => _lenses
                    .map(
                      (lens) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          lens.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  final lens = _lensSelection?.lensById(value);
                  if (lens != null) {
                    _applyLens(lens);
                  }
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _loadLenses,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh lenses'),
                    ),
                    if (_selectedLensId != null)
                      TextButton.icon(
                        onPressed: _clearSelectedLens,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Enter manually'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SectionCard(
            title: 'Inputs',
            children: [
              if (_availableSensors.length > 1) ...[
                DropdownButtonFormField<SensorPreset>(
                  initialValue: _selectedSensor,
                  decoration: const InputDecoration(
                    labelText: 'Sensor format / circle of confusion',
                  ),
                  items: _availableSensors
                      .map(
                        (sensor) => DropdownMenuItem<SensorPreset>(
                          value: sensor,
                          child: Text(sensor.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedSensor = value);
                    _calculate(live: true);
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (lens == null) ...[
                NumField(
                    controller: _focalMm, label: 'Focal length', suffix: 'mm'),
                NumField(controller: _aperture, label: 'Aperture', suffix: 'f'),
                NumField(
                  controller: _subjectDistanceM,
                  label: 'Subject distance',
                  suffix: 'm',
                  helpText:
                      'Distance from the camera to the plane you want in focus.',
                ),
              ] else ...[
                if (lens.isZoom)
                  LensValueSlider(
                    label: 'Focal length',
                    minLabel: '${lens.minFocalLengthMm.toStringAsFixed(0)}mm',
                    maxLabel: '${lens.maxFocalLengthMm.toStringAsFixed(0)}mm',
                    min: lens.minFocalLengthMm,
                    max: lens.maxFocalLengthMm,
                    value: focalValue.clamp(
                        lens.minFocalLengthMm, lens.maxFocalLengthMm),
                    controller: _focalMm,
                    suffix: 'mm',
                    onChanged: _updateLensFocal,
                  ),
                LensValueSlider(
                  label: lens.variableAperture
                      ? 'Aperture (changes with zoom)'
                      : 'Aperture',
                  minLabel: 'f/${minApertureAtFocal.toStringAsFixed(1)}',
                  maxLabel: 'f/${lens.maxAperture.toStringAsFixed(1)}',
                  min: minApertureAtFocal,
                  max: lens.maxAperture,
                  value:
                      apertureValue.clamp(minApertureAtFocal, lens.maxAperture),
                  controller: _aperture,
                  suffix: 'f',
                  onChanged: _updateLensAperture,
                ),
                _LogDistanceControl(
                  label: 'Focus distance',
                  value: subjectDistanceValue.clamp(
                      lens.minFocusDistanceM, focusMaxDistance),
                  min: lens.minFocusDistanceM,
                  max: focusMaxDistance,
                  controller: _subjectDistanceM,
                  onChanged: (value) => _updateSubjectDistance(value,
                      maxDistance: focusMaxDistance),
                ),
              ],
              Text(
                'Results update as you adjust the controls.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          SectionCard(
            title: 'Output',
            children: [
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else if (_result == null)
                Text(
                  'Enter your settings to see the focus range.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...[
                _DofRuler(
                  nearLimitM: _result!.nearLimitM,
                  subjectDistanceM: _result!.subjectDistanceM,
                  farLimitM: _result!.farLimitM,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DofMetricPill(
                      label: 'Hyperfocal',
                      value: '${_result!.hyperfocalM.toStringAsFixed(2)} m',
                      helpText:
                          'The focus distance where everything from about half that distance to infinity appears acceptably sharp.',
                    ),
                    DofMetricPill(
                      label: 'Start',
                      value: '${_result!.nearLimitM.toStringAsFixed(2)} m',
                      helpText:
                          'The nearest distance that still falls inside the calculated depth of field.',
                    ),
                    DofMetricPill(
                      label: 'Set',
                      value:
                          '${_result!.subjectDistanceM.toStringAsFixed(2)} m',
                      helpText: 'The distance you set as the focus target.',
                    ),
                    DofMetricPill(
                      label: 'Far',
                      value: _result!.farLimitM == null
                          ? 'Infinity'
                          : '${_result!.farLimitM!.toStringAsFixed(2)} m',
                      helpText:
                          'The farthest distance that still falls inside the calculated depth of field.',
                    ),
                    DofMetricPill(
                      label: 'Focus plane thickness',
                      value: _result!.totalDofM == null
                          ? 'Infinity'
                          : formatLengthMeters(_result!.totalDofM!),
                      helpText:
                          'The total subject-side depth that appears acceptably sharp at the chosen settings.',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: _openFocusStackingPlanner,
                    icon: const Icon(Icons.layers_outlined),
                    label: const Text('Open in Focus Stacking'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LogDistanceControl extends StatelessWidget {
  const _LogDistanceControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;

  double _toNormalized(double distance) {
    final minLog = math.log(min);
    final maxLog = math.log(max);
    return ((math.log(distance) - minLog) / (maxLog - minLog)).clamp(0.0, 1.0);
  }

  double _fromNormalized(double t) {
    final minLog = math.log(min);
    final maxLog = math.log(max);
    return math.exp(minLog + (maxLog - minLog) * t);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _toNormalized(value.clamp(min, max));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    suffixText: 'm',
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: normalized,
            min: 0,
            max: 1,
            divisions: 240,
            onChanged: (t) => onChanged(_fromNormalized(t)),
          ),
          Row(
            children: [
              Text('${min.toStringAsFixed(2)}m',
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text('${max.toStringAsFixed(0)}m',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _DofRuler extends StatelessWidget {
  const _DofRuler({
    required this.nearLimitM,
    required this.subjectDistanceM,
    required this.farLimitM,
  });

  final double nearLimitM;
  final double subjectDistanceM;
  final double? farLimitM;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final farIsInfinity = farLimitM == null;
    final nearGap = math.max(subjectDistanceM - nearLimitM, 0.001);
    final farGap = farIsInfinity
        ? nearGap * 8
        : math.max((farLimitM! - subjectDistanceM), 0.001);
    final leftWeight = math.log(1 + nearGap);
    final rightWeight = math.log(1 + farGap);
    final subjectPos =
        (leftWeight / (leftWeight + rightWeight)).clamp(0.0, 1.0);
    const farPos = 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerLow.withValues(alpha: 0.75),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Depth Of Field Ruler',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 94,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final subjectX = width * subjectPos;
                final farX = width * farPos;
                final markerMaxLeft =
                    math.max(0.0, width - _RulerMarker.markerWidth);
                final minMarkerGap = _RulerMarker.markerWidth * 0.82;

                double toLeft(double x) => (x - _RulerMarker.markerWidth / 2)
                    .clamp(0.0, markerMaxLeft);

                var startLeft = toLeft(0);
                var subjectLeft = toLeft(subjectX);
                var farLeft = toLeft(farX);

                if ((subjectDistanceM - nearLimitM).abs() > 0.0001 &&
                    subjectLeft < startLeft + minMarkerGap) {
                  subjectLeft =
                      (startLeft + minMarkerGap).clamp(0.0, markerMaxLeft);
                }
                if (!farIsInfinity &&
                    farLimitM != null &&
                    (farLimitM! - subjectDistanceM).abs() > 0.0001 &&
                    farLeft < subjectLeft + minMarkerGap) {
                  farLeft =
                      (subjectLeft + minMarkerGap).clamp(0.0, markerMaxLeft);
                }
                if (!farIsInfinity &&
                    farLimitM != null &&
                    (farLimitM! - nearLimitM).abs() > 0.0001 &&
                    farLeft < startLeft + minMarkerGap) {
                  farLeft =
                      (startLeft + minMarkerGap).clamp(0.0, markerMaxLeft);
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 38,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 38,
                      left: 0,
                      width: farX,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: 0.55),
                              scheme.primary
                            ],
                          ),
                        ),
                      ),
                    ),
                    _RulerMarker(
                      left: startLeft,
                      color: scheme.primary,
                      label: 'Start',
                      value: '${nearLimitM.toStringAsFixed(2)} m',
                    ),
                    _RulerMarker(
                      left: subjectLeft,
                      color: scheme.tertiary,
                      label: 'Set Distance',
                      value: '${subjectDistanceM.toStringAsFixed(2)} m',
                    ),
                    _RulerMarker(
                      left: farLeft,
                      color: scheme.secondary,
                      label: 'Far',
                      value: farIsInfinity
                          ? 'Infinity'
                          : '${farLimitM!.toStringAsFixed(2)} m',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerMarker extends StatelessWidget {
  static const double markerWidth = 96;

  const _RulerMarker({
    required this.left,
    required this.color,
    required this.label,
    required this.value,
  });

  final double left;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: left,
      top: 0,
      child: SizedBox(
        width: markerWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Container(
              width: 2,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
