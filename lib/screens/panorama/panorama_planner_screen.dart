import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/calculators/panorama_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/shared/widgets/lens_value_slider.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/info_metric_tile.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

class PanoramaPlannerScreen extends StatefulWidget {
  const PanoramaPlannerScreen({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  State<PanoramaPlannerScreen> createState() => _PanoramaPlannerScreenState();
}

class _PanoramaPlannerScreenState extends State<PanoramaPlannerScreen> {
  final _db = LensDatabase.instance;

  final _focalMm = TextEditingController(text: '35');
  final _targetHorizontalFovDeg = TextEditingController(text: '120');
  final _targetVerticalFovDeg = TextEditingController(text: '40');
  final _overlapPercent = TextEditingController(text: '30');

  List<Lens> _lenses = const [];
  int? _selectedLensId;
  late SensorPreset _selectedSensor;
  PanoramaOrientation _orientation = PanoramaOrientation.portrait;

  String? _errorMessage;
  PanoramaCalculatorResult? _result;

  List<SensorPreset> get _availableSensors =>
      resolveEnabledSensorPresets(widget.settings.enabledSensorIds);

  Lens? get _selectedLens {
    if (_selectedLensId == null) {
      return null;
    }
    for (final lens in _lenses) {
      if (lens.id == _selectedLensId) {
        return lens;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedSensor = _availableSensors.first;
    _loadLenses();
  }

  @override
  void dispose() {
    _focalMm.dispose();
    _targetHorizontalFovDeg.dispose();
    _targetVerticalFovDeg.dispose();
    _overlapPercent.dispose();
    super.dispose();
  }

  Future<void> _loadLenses() async {
    final lenses = await _db.getLenses();
    if (!mounted) {
      return;
    }

    final selectedExists = lenses.any((lens) => lens.id == _selectedLensId);
    setState(() {
      _lenses = lenses;
      if (!selectedExists) {
        _selectedLensId = null;
      }
    });
  }

  void _clearSelectedLens() {
    setState(() {
      _selectedLensId = null;
    });
  }

  void _applyLens(Lens lens) {
    final focal = lens.minFocalLengthMm;
    setState(() {
      _selectedLensId = lens.id;
      _focalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
  }

  void _updateLensFocal(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    setState(() {
      _focalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
  }

  void _calculate() {
    final focal = double.tryParse(_focalMm.text);
    final targetHorizontal = double.tryParse(_targetHorizontalFovDeg.text);
    final targetVertical = double.tryParse(_targetVerticalFovDeg.text);
    final overlap = double.tryParse(_overlapPercent.text);

    if (focal == null ||
        targetHorizontal == null ||
        targetVertical == null ||
        overlap == null ||
        focal <= 0 ||
        targetHorizontal <= 0 ||
        targetVertical <= 0 ||
        overlap < 0 ||
        overlap >= 100) {
      setState(() {
        _errorMessage =
            'Enter valid positive values. Overlap must stay below 100%.';
        _result = null;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _result = PanoramaCalculator.calculate(
        focalLengthMm: focal,
        sensorWidthMm: _selectedSensor.widthMm,
        sensorHeightMm: _selectedSensor.heightMm,
        orientation: _orientation,
        targetHorizontalFovDeg: targetHorizontal,
        targetVerticalFovDeg: targetVertical,
        overlapPercent: overlap,
      );
    });
  }

  String _formatAngle(double value) => '${value.toStringAsFixed(1)}°';

  @override
  Widget build(BuildContext context) {
    final lens = _selectedLens;
    final focalValue =
        double.tryParse(_focalMm.text) ?? (lens?.minFocalLengthMm ?? 35);

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
                  final lensIndex =
                      _lenses.indexWhere((lens) => lens.id == value);
                  if (lensIndex >= 0) {
                    _applyLens(_lenses[lensIndex]);
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
                    labelText: 'Sensor format',
                  ),
                  items: _availableSensors
                      .map(
                        (sensor) => DropdownMenuItem<SensorPreset>(
                          value: sensor,
                          child: Text(sensor.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedSensor = value);
                  },
                ),
                const SizedBox(height: 12),
              ],
              SegmentedButton<PanoramaOrientation>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: PanoramaOrientation.landscape,
                    label: Text('Landscape'),
                    icon: Icon(Icons.crop_landscape),
                  ),
                  ButtonSegment(
                    value: PanoramaOrientation.portrait,
                    label: Text('Portrait'),
                    icon: Icon(Icons.crop_portrait),
                  ),
                ],
                selected: {_orientation},
                onSelectionChanged: (selection) {
                  setState(() => _orientation = selection.first);
                },
              ),
              const SizedBox(height: 12),
              if (lens == null)
                NumField(
                  controller: _focalMm,
                  label: 'Focal length',
                  suffix: 'mm',
                )
              else if (lens.isZoom)
                LensValueSlider(
                  label: 'Focal length',
                  minLabel: '${lens.minFocalLengthMm.toStringAsFixed(0)}mm',
                  maxLabel: '${lens.maxFocalLengthMm.toStringAsFixed(0)}mm',
                  min: lens.minFocalLengthMm,
                  max: lens.maxFocalLengthMm,
                  value: focalValue.clamp(
                    lens.minFocalLengthMm,
                    lens.maxFocalLengthMm,
                  ),
                  controller: _focalMm,
                  suffix: 'mm',
                  onChanged: _updateLensFocal,
                ),
              NumField(
                controller: _targetHorizontalFovDeg,
                label: 'Horizontal coverage',
                suffix: 'deg',
                helpText:
                    'How much final stitched width you want to cover, in degrees across the scene.',
              ),
              NumField(
                controller: _targetVerticalFovDeg,
                label: 'Vertical coverage',
                suffix: 'deg',
                helpText:
                    'How much final stitched height you want to cover, in degrees across the scene.',
              ),
              NumField(
                controller: _overlapPercent,
                label: 'Overlap',
                suffix: '%',
                helpText:
                    'Shared area between neighboring frames. More overlap is safer but increases shot count.',
              ),
              FilledButton(
                onPressed: _calculate,
                child: const Text('Plan Panorama'),
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
                  'No result',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    InfoMetricTile(
                      label: 'Per-frame coverage',
                      value:
                          '${_formatAngle(_result!.frameHorizontalFovDeg)} x ${_formatAngle(_result!.frameVerticalFovDeg)}',
                      helpText:
                          'How much scene one frame covers at the chosen focal length and orientation.',
                    ),
                    InfoMetricTile(
                      label: 'Advance',
                      value:
                          '${_formatAngle(_result!.horizontalAdvanceDeg)} x ${_formatAngle(_result!.verticalAdvanceDeg)}',
                      helpText:
                          'How far you can move between shots after overlap is accounted for.',
                    ),
                    InfoMetricTile(
                      label: 'Frames',
                      value:
                          '${_result!.horizontalFrames} x ${_result!.verticalFrames}',
                    ),
                    InfoMetricTile(
                      label: 'Total shots',
                      value: '${_result!.totalFrames}',
                    ),
                    InfoMetricTile(
                      label: 'Stitched coverage',
                      value:
                          '${_formatAngle(_result!.stitchedHorizontalFovDeg)} x ${_formatAngle(_result!.stitchedVerticalFovDeg)}',
                      helpText:
                          'Estimated final coverage of the planned grid once the overlapping frames are stitched.',
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
