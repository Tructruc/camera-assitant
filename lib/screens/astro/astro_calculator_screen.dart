import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/lens_value_slider.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

class AstroCalculatorScreen extends StatefulWidget {
  const AstroCalculatorScreen({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  State<AstroCalculatorScreen> createState() => _AstroCalculatorScreenState();
}

class _AstroCalculatorScreenState extends State<AstroCalculatorScreen> {
  final _db = LensDatabase.instance;
  final _focalMm = TextEditingController(text: '14');

  List<Lens> _lenses = const [];
  int? _selectedLensId;
  late SensorPreset _selectedSensor;
  AstroShutterRule _selectedRule = AstroShutterRule.rule400;

  String? _errorMessage;
  AstroCalculatorResult? _result;

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
    _focalMm.addListener(_calculateLive);
    _loadLenses();
    _calculate();
  }

  @override
  void dispose() {
    _focalMm.removeListener(_calculateLive);
    _focalMm.dispose();
    super.dispose();
  }

  void _calculateLive() => _calculate(live: true);

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
    _calculate();
  }

  void _applyLens(Lens lens) {
    final focal = lens.minFocalLengthMm;
    setState(() {
      _selectedLensId = lens.id;
      _focalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
    _calculate();
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
    _calculate();
  }

  void _calculate({bool live = false}) {
    final focal = parseDouble(_focalMm.text);

    if (focal == null || focal <= 0) {
      setState(() {
        _errorMessage = live ? null : 'Enter a valid focal length.';
        _result = null;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _result = AstroCalculator.calculateMaxShutter(
        focalLengthMm: focal,
        sensorWidthMm: _selectedSensor.widthMm,
        sensorHeightMm: _selectedSensor.heightMm,
        rule: _selectedRule,
      );
    });
  }

  Future<void> _showRuleHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shutter rule'),
        content: const Text(
          'These are quick star-trailing rules based on full-frame equivalent focal length. '
          '500 is looser, 400 is a safer default, and 300 is stricter for cleaner stars.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatMm(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(0)} mm';
    }
    return '${value.toStringAsFixed(1)} mm';
  }

  @override
  Widget build(BuildContext context) {
    final lens = _selectedLens;
    final focalValue =
        double.tryParse(_focalMm.text) ?? (lens?.minFocalLengthMm ?? 14);

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
                    _calculate();
                  },
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shutter rule',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _showRuleHelp,
                    icon: const Icon(Icons.help_outline),
                    tooltip: 'Shutter rule help',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<AstroShutterRule>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(
                      value: AstroShutterRule.rule500,
                      label: Text('500'),
                    ),
                    ButtonSegment(
                      value: AstroShutterRule.rule400,
                      label: Text('400'),
                    ),
                    ButtonSegment(
                      value: AstroShutterRule.rule300,
                      label: Text('300'),
                    ),
                  ],
                  selected: {_selectedRule},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedRule = selection.first);
                    _calculate();
                  },
                ),
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
                    _MetricTile(
                      label: 'Max shutter',
                      value:
                          formatFractionalSeconds(_result!.maxShutterSeconds),
                    ),
                    _MetricTile(
                      label: 'FF equivalent',
                      value: _formatMm(_result!.equivalentFocalLengthMm),
                    ),
                    _MetricTile(
                      label: 'Crop factor',
                      value: '${_result!.cropFactor.toStringAsFixed(2)}x',
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: 164,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
