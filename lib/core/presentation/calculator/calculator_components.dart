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
    this.sourceLabel,
    super.key,
  });

  final String equipmentName;
  final String appliedValues;

  /// Display label for the saved item's declared provenance source.
  final String? sourceLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: <String>[
      'Applied equipment $equipmentName',
      appliedValues,
      if (sourceLabel case final source?) 'source $source',
    ].join(', '),
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
                <String>[
                  'From $equipmentName'
                      '${sourceLabel == null ? '' : ' ($sourceLabel)'}'
                      ': $appliedValues',
                  'You can edit these values for this calculation only.',
                ].join('\n'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A collapsed group of secondary inputs.
///
/// Photographers act on two or three numbers per calculator; everything else is
/// a convention or a preference. Keeping those fields behind one expander
/// leaves the default screen readable without removing any control.
class CalculatorAdvancedSection extends StatelessWidget {
  const CalculatorAdvancedSection({
    required this.children,
    this.title = 'More settings',
    super.key,
  });

  final List<Widget> children;
  final String title;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 4),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.tune),
      title: Text(title),
      children: children,
    ),
  );
}

/// Result-first presentation shared by every calculator.
///
/// One hero answer carries the decision, a short row of tiles carries the
/// numbers a photographer compares, and the inputs, exact intermediates and
/// model assumptions live in a collapsed details section. Warnings stay visible
/// above the hero because they can change how the result may be used.
class CalculationResultView extends StatelessWidget {
  const CalculationResultView({
    required this.title,
    required this.highlight,
    required this.onReset,
    required this.onSave,
    this.highlightCaption,
    this.tiles = const <(String, String)>[],
    this.details = const <(String, String)>[],
    this.inputs = const <(String, String)>[],
    this.assumptions = const <String>[],
    this.guidance,
    this.warnings = const <String>[],
    super.key,
  });

  /// Screen title, also the accessibility name of the result region.
  final String title;

  /// The single number (or wording) this calculator exists to produce.
  final (String, String) highlight;

  /// Optional plain-language note printed under the hero value.
  final String? highlightCaption;

  /// Secondary answers, rendered as compact half-width tiles.
  final List<(String, String)> tiles;

  /// Intermediates and exact values, collapsed under "Details".
  final List<(String, String)> details;

  /// Values actually used, collapsed under "Details".
  final List<(String, String)> inputs;

  final List<String> assumptions;

  /// User-facing limitations the calculator reported for this result.
  final List<String> warnings;
  final String? guidance;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '$title calculation result: ${highlight.$1} ${highlight.$2}'
          '${warnings.isEmpty ? '' : '. Warnings: ${warnings.join('; ')}'}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (warnings.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                _WarningBanner(warnings: warnings),
              ],
              const SizedBox(height: 10),
              Text(
                highlight.$1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                highlight.$2,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (highlightCaption case final caption?) ...<Widget>[
                const SizedBox(height: 4),
                Text(caption, style: theme.textTheme.bodySmall),
              ],
              if (guidance case final text?) ...<Widget>[
                const SizedBox(height: 8),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
              if (tiles.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _ResultTiles(tiles: tiles),
              ],
              if (details.isNotEmpty ||
                  inputs.isNotEmpty ||
                  assumptions.isNotEmpty)
                _DetailsSection(
                  // Stable identity: a warning appearing above must not reset
                  // the section the user just opened.
                  key: const ValueKey('details'),
                  details: details,
                  inputs: inputs,
                  assumptions: assumptions,
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save result'),
                  ),
                  TextButton(onPressed: onReset, child: const Text('Reset')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Warnings: ${warnings.join('; ')}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final warning in warnings)
                    Text(
                      warning,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTiles extends StatelessWidget {
  const _ResultTiles({required this.tiles});

  final List<(String, String)> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Two columns whenever a phone-width card can hold them; the tiles stay
        // scannable instead of turning into another full-width value list.
        final tileWidth = width >= 240 ? (width - 10) / 2 : width;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (final (label, value) in tiles)
              SizedBox(
                width: tileWidth,
                child: Semantics(
                  container: true,
                  label: '$label $value',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.details,
    required this.inputs,
    required this.assumptions,
    super.key,
  });

  final List<(String, String)> details;
  final List<(String, String)> inputs;
  final List<String> assumptions;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      title: const Text('Details'),
      children: <Widget>[
        if (inputs.isNotEmpty) ...<Widget>[
          _DetailHeading('Values used', inputs),
          const SizedBox(height: 12),
        ],
        if (details.isNotEmpty) ...<Widget>[
          _DetailHeading('Exact values', details),
          const SizedBox(height: 12),
        ],
        if (assumptions.isNotEmpty) ...<Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Model assumptions',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 4),
          for (final assumption in assumptions)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('• $assumption'),
            ),
        ],
      ],
    ),
  );
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.label, this.rows);

  final String label;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label: ${rows.map((row) => '${row.$1} ${row.$2}').join('; ')}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(height: 4),
        for (final (name, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(name)),
                const SizedBox(width: 12),
                Flexible(child: Text(value, textAlign: TextAlign.end)),
              ],
            ),
          ),
      ],
    ),
  );
}
