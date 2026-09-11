/// Shared accessible building blocks for calculator screens.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
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

/// Identity block at the top of a calculator screen.
///
/// The route's app bar already carries the tool's name, so the header leads with
/// the tool's icon and a one-line explanation of what it answers instead of
/// repeating the title.
class CalculatorHeader extends StatelessWidget {
  const CalculatorHeader({
    required this.icon,
    required this.description,
    this.title,
    super.key,
  });

  final IconData icon;
  final String description;

  /// Optional title for screens rendered without an app bar.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentForIcon(icon, AppAccents.of(context));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.container,
            borderRadius: AppRadius.controlAll,
          ),
          child: Icon(icon, size: 22, color: accent.onContainer),
        ),
        const SizedBox(width: AppGap.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (title case final text?) ...<Widget>[
                Text(text, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppGap.xs),
              ],
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Two related inputs side by side on a wide window, stacked on a phone.
///
/// Sensor width/height, horizontal/vertical bounds and the like read as pairs;
/// the row only forms when there is genuinely room for it.
class CalculatorFieldPair extends StatelessWidget {
  const CalculatorFieldPair({
    required this.first,
    required this.second,
    this.minWidthForRow = 460,
    super.key,
  });

  final Widget first;
  final Widget second;
  final double minWidthForRow;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < minWidthForRow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[first, second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: first),
          const SizedBox(width: AppGap.md),
          Expanded(child: second),
        ],
      );
    },
  );
}

/// An empty list, search result, or first-run screen.
///
/// One icon in a tinted well, a short title and a sentence that says what to do
/// next; every empty surface in the app uses it so they read the same.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppGap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 30,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppGap.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppGap.sm),
            Text(
              description,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (action case final widget?) ...<Widget>[
              const SizedBox(height: AppGap.lg),
              widget,
            ],
          ],
        ),
      ),
    );
  }
}

/// Splits a formatted value into its number and its unit so the two can carry
/// different weight (`10.47` large, `m` small and quiet).
(String, String, String) _splitValueUnit(String value) {
  final trimmed = value.trim();
  // Shutter fractions read as one token: `1/30 s`, not `1` + `/30 s`.
  final fraction = RegExp(r'^(\d+/\d+)(\s*)(\S.*)$').firstMatch(trimmed);
  if (fraction != null) {
    return (fraction.group(1)!, fraction.group(2)!, fraction.group(3)!);
  }
  final match = RegExp(r'^([+-]?[\d.,]+)(\s*)(\S.*)$').firstMatch(trimmed);
  if (match == null) return (trimmed, '', '');
  final unit = match.group(3)!;
  // A long tail is prose, not a unit; keep it in the value.
  if (unit.length > 14) return (trimmed, '', '');
  return (match.group(1)!, match.group(2)!, unit);
}

/// A measurement printed as a large tabular number with a quiet unit.
class ResultValue extends StatelessWidget {
  const ResultValue({
    required this.value,
    required this.valueStyle,
    required this.unitStyle,
    super.key,
  });

  final String value;
  final TextStyle? valueStyle;
  final TextStyle? unitStyle;

  @override
  Widget build(BuildContext context) {
    final (number, separator, unit) = _splitValueUnit(value);
    if (unit.isEmpty) return Text(number, style: valueStyle);
    // The plain text of the span stays byte-identical to the input, so finders
    // and screen readers see the same string while the unit renders smaller.
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: number, style: valueStyle),
          TextSpan(text: '$separator$unit', style: unitStyle),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => AppContentFrame(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(
        AppGap.lg,
        AppGap.lg,
        AppGap.lg,
        AppGap.xxl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: widget.children,
    ),
  );
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppGap.md),
      child: TextField(
        key: fieldKey,
        controller: controller,
        style: theme.textTheme.titleMedium,
        decoration: InputDecoration(labelText: label, errorText: errorText),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: <String>[
        'Applied equipment $equipmentName',
        appliedValues,
        if (sourceLabel case final source?) 'source $source',
      ].join(', '),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppGap.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppGap.md,
          vertical: AppGap.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: AppRadius.controlAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppGap.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'From $equipmentName'
                    '${sourceLabel == null ? '' : ' ($sourceLabel)'}'
                    ': $appliedValues',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You can edit these values for this calculation only.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
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
      child: _ResultEntrance(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppGap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                  ),
                ),
                if (warnings.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppGap.md),
                  _WarningBanner(warnings: warnings),
                ],
                const SizedBox(height: AppGap.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppGap.lg,
                    vertical: AppGap.lg,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppRadius.controlAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        highlight.$1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppGap.xs),
                      ResultValue(
                        value: highlight.$2,
                        valueStyle: theme.textTheme.displaySmall,
                        unitStyle: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (highlightCaption case final caption?) ...<Widget>[
                        const SizedBox(height: AppGap.xs),
                        Text(caption, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (guidance case final text?) ...<Widget>[
                  const SizedBox(height: AppGap.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppGap.sm),
                      Expanded(
                        child: Text(text, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
                if (tiles.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppGap.lg),
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
                const SizedBox(height: AppGap.lg),
                const Divider(),
                const SizedBox(height: AppGap.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                        label: const Text('Save result'),
                      ),
                    ),
                    const SizedBox(width: AppGap.sm),
                    TextButton(onPressed: onReset, child: const Text('Reset')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts a freshly built result card into place.
///
/// Opacity-only, so the widget tree is complete from the first frame and tests
/// that pump a single frame still find every value.
class _ResultEntrance extends StatelessWidget {
  const _ResultEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: AppMotion.medium,
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );
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
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: AppRadius.controlAll,
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.onTertiaryContainer,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppGap.md,
          AppGap.md,
          AppGap.md,
          AppGap.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: AppGap.sm),
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
        final tileWidth = width >= 240 ? (width - AppGap.sm) / 2 : width;
        return Wrap(
          spacing: AppGap.sm,
          runSpacing: AppGap.sm,
          children: <Widget>[
            for (final (label, value) in tiles)
              SizedBox(
                width: tileWidth,
                child: Semantics(
                  container: true,
                  label: '$label $value',
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppGap.md,
                      vertical: AppGap.md,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: AppRadius.controlAll,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: AppGap.xs),
                        ResultValue(
                          value: value,
                          valueStyle: theme.textTheme.titleMedium,
                          unitStyle: theme.textTheme.bodySmall,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppGap.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(
          Icons.subject,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: const Text('Details'),
        children: <Widget>[
          if (inputs.isNotEmpty) ...<Widget>[
            _DetailHeading('Values used', inputs),
            const SizedBox(height: AppGap.md),
          ],
          if (details.isNotEmpty) ...<Widget>[
            _DetailHeading('Exact values', details),
            const SizedBox(height: AppGap.md),
          ],
          if (assumptions.isNotEmpty) ...<Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Model assumptions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            const SizedBox(height: AppGap.xs),
            for (final assumption in assumptions)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppGap.xs),
                  child: Text('• $assumption'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.label, this.rows);

  final String label;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: ${rows.map((row) => '${row.$1} ${row.$2}').join('; ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: AppGap.xs),
          for (final (name, value) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppGap.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(name, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(width: AppGap.md),
                  Flexible(
                    child: ResultValue(
                      value: value,
                      valueStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unitStyle: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
