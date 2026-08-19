/// Shared accessible building blocks for calculator screens.
library;

import 'package:flutter/material.dart';

class CalculatorPage extends StatelessWidget {
  const CalculatorPage({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: children);
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
    required this.rows,
    required this.assumptions,
    required this.onReset,
    required this.onSave,
    this.guidance,
    super.key,
  });

  final String title;
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
