/// Shared accessible building blocks for calculator screens.
library;

import 'package:flutter/material.dart';

import '../../data/repositories/preferences_repository.dart';

String formatDisplayLength(double millimetres, LengthDisplay display) {
  if (display == LengthDisplay.imperial) {
    final inches = millimetres / 25.4;
    return inches >= 12
        ? '${(inches / 12).toStringAsFixed(2)} ft'
        : '${inches.toStringAsFixed(2)} in';
  }
  return millimetres >= 1000
      ? '${(millimetres / 1000).toStringAsFixed(2)} m'
      : '${millimetres.toStringAsFixed(1)} mm';
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    required this.children,
    required this.inputControllers,
    required this.onInputsChanged,
    super.key,
  });

  final List<Widget> children;
  final List<TextEditingController> inputControllers;
  final VoidCallback onInputsChanged;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _inputText = <TextEditingController, String>{};

  @override
  void initState() {
    super.initState();
    _watchInputs();
  }

  @override
  void didUpdateWidget(CalculatorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unwatchInputs();
    _watchInputs();
  }

  void _watchInputs() {
    for (final controller in widget.inputControllers) {
      _inputText[controller] = controller.text;
      controller.addListener(_inputChanged);
    }
  }

  void _unwatchInputs() {
    for (final controller in _inputText.keys) {
      controller.removeListener(_inputChanged);
    }
    _inputText.clear();
  }

  void _inputChanged() {
    var changed = false;
    for (final controller in _inputText.keys) {
      if (_inputText[controller] != controller.text) {
        _inputText[controller] = controller.text;
        changed = true;
      }
    }
    // Cursor/selection/composing changes alone do not change the calculation.
    if (changed) widget.onInputsChanged();
  }

  @override
  void dispose() {
    _unwatchInputs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: widget.children);
}

class CalculatorNumberField extends StatelessWidget {
  const CalculatorNumberField({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.errorText,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    ),
  );
}

class AppliedEquipmentNotice extends StatelessWidget {
  const AppliedEquipmentNotice({
    required this.equipmentName,
    required this.appliedValues,
    super.key,
  });

  final String equipmentName;
  final String appliedValues;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Applied equipment $equipmentName, $appliedValues',
    child: Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'From $equipmentName: $appliedValues\nYou can edit these values for this calculation only.',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CalculationResultView extends StatelessWidget {
  const CalculationResultView({
    required this.title,
    required this.inputs,
    required this.rows,
    required this.assumptions,
    required this.onReset,
    required this.onSave,
    this.guidance,
    super.key,
  });

  final String title;
  final List<(String, String)> inputs;
  final List<(String, String)> rows;
  final List<String> assumptions;
  final String? guidance;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: '$title calculation result',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label:
                  'Input summary: ${inputs.map((input) => '${input.$1} ${input.$2}').join('; ')}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Input summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  for (final (label, value) in inputs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: Text(label)),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(value, textAlign: TextAlign.end),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 24),
            Text('Results', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: Text(label)),
                    const SizedBox(width: 12),
                    Flexible(child: Text(value, textAlign: TextAlign.end)),
                  ],
                ),
              ),
            if (guidance case final text?) ...<Widget>[
              const SizedBox(height: 4),
              Text(text),
            ],
            const Divider(height: 24),
            Text('Assumptions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final assumption in assumptions) Text('• $assumption'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save result'),
                ),
                OutlinedButton(onPressed: onReset, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
