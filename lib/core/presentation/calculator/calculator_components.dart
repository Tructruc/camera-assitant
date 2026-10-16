/// Shared accessible building blocks for calculator screens.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../data/repositories/preferences_repository.dart';

// -------------------------------------------------------------- value adapter

/// Parses the text of a field into the canonical raw value a calculator reads.
///
/// This is the exact-entry adapter for [CalculatorNumberField]: an empty or
/// unparsable field, a non-finite value (`Infinity`, `NaN`) and a value that
/// overflows when scaled back to raw units all parse to `null`, which every
/// calculator already treats as "no usable number". Negative values are parsed
/// as typed; nothing here clamps or rounds.
///
/// The parse is `double.tryParse` on the trimmed text - the same reader the
/// calculators use on the canonical controller - plus the finite and overflow
/// checks. It is deliberately not a wider grammar: a field must never accept a
/// number the domain's own `double.tryParse` cannot read back.
double? canonicalValueFromText(String text, {double displayDivisor = 1}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  // The canonical parse contract is `double.tryParse`; a comma is a thousands
  // or decimal separator depending on locale, so it is refused rather than
  // guessed at.
  if (trimmed.contains(',')) return null;
  final display = double.tryParse(trimmed);
  if (display == null || !display.isFinite) return null;
  if (!displayDivisor.isFinite || displayDivisor == 0) return null;
  final raw = display * displayDivisor;
  return raw.isFinite ? raw : null;
}

/// Formats a canonical raw value as display text.
///
/// [decimalPlaces] fixes the number of decimals; without it the shortest form
/// that agrees with the value to 12 significant digits is used, so `1500 / 1000`
/// reads `1.5` rather than `1.5000000000000002`. Every string this produces is a
/// `double.tryParse` literal, so the canonical text a field stores is exactly
/// what a calculator reads back from the controller.
String textFromCanonicalValue(
  double value, {
  double displayDivisor = 1,
  int? decimalPlaces,
}) {
  if (!value.isFinite) return '';
  final divisor = displayDivisor.isFinite && displayDivisor != 0
      ? displayDivisor
      : 1;
  final display = value / divisor;
  if (!display.isFinite) return '';
  if (decimalPlaces != null) {
    return display.toStringAsFixed(decimalPlaces.clamp(0, 12));
  }
  if (display == display.roundToDouble() && display.abs() < 1e15) {
    return display.toStringAsFixed(0);
  }
  var text = display.toStringAsPrecision(12);
  if (text.contains('e') || text.contains('E')) {
    text = display.toString();
  }
  if (text.contains('.') && !text.contains('e') && !text.contains('E')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}

// Display rounding must never become a storage precision policy.
String _exactCanonicalText(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

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
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String description;

  /// Optional title for screens rendered without an app bar.
  final String? title;

  /// Optional control at the end of the header row, for a mode selector or an
  /// applied-equipment chip that belongs with the tool's identity.
  final Widget? trailing;

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
        if (trailing case final widget?) ...<Widget>[
          const SizedBox(width: AppGap.sm),
          widget,
        ],
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

/// The shape of the content that is about to arrive.
///
/// Static on purpose: a pulsing placeholder would keep `pumpAndSettle` busy and
/// these screens resolve from a local database in a frame or two.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    required this.label,
    this.rows = 4,
    this.rowHeight = 76,
    super.key,
  });

  final String label;
  final int rows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A Column, not a ListView: this placeholder is dropped inside parents that
    // already scroll, and a nested viewport would have unbounded height. The
    // row count is capped to the space actually available so it can never
    // overflow a short viewport either.
    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final budget = constraints.maxHeight.isFinite
              ? constraints.maxHeight - AppGap.lg * 2
              : double.infinity;
          final fitting = budget.isFinite
              ? (budget / (rowHeight + AppGap.md)).floor()
              : rows;
          final visible = fitting.clamp(1, rows);
          return Padding(
            padding: const EdgeInsets.all(AppGap.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var index = 0; index < visible; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == visible - 1 ? 0 : AppGap.md,
                    ),
                    child: Container(
                      height: rowHeight,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: AppRadius.cardAll,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      padding: const EdgeInsets.all(AppGap.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: index.isEven ? 180 : 140,
                            height: 12,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: AppGap.sm),
                          Container(
                            width: index.isEven ? 240 : 200,
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
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

/// The pinned answer strip's painted text: an exact string as one rich run.
///
/// The strip is a *mirror* of a label and value the result card already
/// carries as [Text]. Drawing the mirror as a single rich run keeps the card
/// the one canonical, addressable text node for that answer: the strip adds
/// pixels and one semantics node, never a second string of the same value that
/// a reader (or a finder) could land on. The number/unit split - the only
/// styling decision - is the shared [_splitValueUnit], so nothing about the
/// value is re-derived.
class _MirrorText extends StatelessWidget {
  const _MirrorText({
    required this.value,
    required this.valueStyle,
    this.unitStyle,
  });

  final String value;
  final TextStyle? valueStyle;
  final TextStyle? unitStyle;

  @override
  Widget build(BuildContext context) {
    final (number, separator, unit) = _splitValueUnit(value);
    return RichText(
      // Rich text does not inherit the ambient text scale the way Text does.
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(text: number, style: valueStyle),
          if (unit.isNotEmpty)
            TextSpan(text: '$separator$unit', style: unitStyle ?? valueStyle),
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
    this.onCalculate,
    this.calculationKey,
    this.liveCalculationDelay = const Duration(milliseconds: 220),
    super.key,
  });

  final List<Widget> children;
  final List<TextEditingController> inputControllers;

  /// Called as soon as any input's text changes, so a screen can invalidate a
  /// result it is still showing instead of letting it describe stale inputs.
  final VoidCallback onInputsChanged;

  /// Optional live calculation.
  ///
  /// When supplied it is scheduled once shortly after the first frame, again
  /// after every input change (debounced by [liveCalculationDelay]) and again
  /// whenever [calculationKey] changes. It is never called after the screen is
  /// disposed, and it is *not* re-scheduled by an ordinary rebuild, so a screen
  /// that rebuilds from its own result cannot drive an endless recalculation
  /// loop. Heavy searches (astronomy, alignment) must keep their explicit
  /// action and simply not pass this.
  final VoidCallback? onCalculate;

  /// Identity of everything that should force a recalculation besides the text
  /// of the input controllers - a selected location, an applied lens, a
  /// preference. A scalar or string compares by `==`; a `List`, `Set` or `Map`
  /// compares by value, so a screen may pass a freshly built collection on every
  /// build without recalculating forever. Changing it re-runs [onCalculate].
  final Object? calculationKey;

  /// Debounce between the last keystroke and a live calculation.
  final Duration liveCalculationDelay;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

/// Value equality for a calculation key, including freshly built collections.
bool _sameCalculationKey(Object? first, Object? second) {
  if (identical(first, second)) return true;
  if (first is List && second is List) return listEquals(first, second);
  if (first is Set && second is Set) return setEquals(first, second);
  if (first is Map && second is Map) return mapEquals(first, second);
  return first == second;
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _inputText = <TextEditingController, String>{};
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _watchInputs();
    _scheduleLiveCalculation();
  }

  @override
  void didUpdateWidget(CalculatorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unwatchInputs();
    _watchInputs();
    // Only a genuine change of identity re-runs the calculation. The callback
    // itself is deliberately not compared: a screen usually passes a fresh
    // closure on every build, and treating that as a change would recalculate
    // forever.
    final wasLive = oldWidget.onCalculate != null;
    final isLive = widget.onCalculate != null;
    if (wasLive && !isLive) {
      _cancelLiveCalculation();
    } else if (isLive &&
        (!wasLive ||
            !_sameCalculationKey(
              oldWidget.calculationKey,
              widget.calculationKey,
            ))) {
      _scheduleLiveCalculation();
    }
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
    if (!changed) return;
    widget.onInputsChanged();
    _scheduleLiveCalculation();
  }

  void _scheduleLiveCalculation() {
    _cancelLiveCalculation();
    if (widget.onCalculate == null) return;
    _liveTimer = Timer(widget.liveCalculationDelay, _runLiveCalculation);
  }

  void _runLiveCalculation() {
    _liveTimer = null;
    if (!mounted) return;
    // Read through the widget, so the build that just happened supplies the
    // current callback rather than a closure captured when the timer was set.
    widget.onCalculate?.call();
  }

  void _cancelLiveCalculation() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  @override
  void dispose() {
    _cancelLiveCalculation();
    _unwatchInputs();
    super.dispose();
  }

  /// The live answer this page is allowed to pin, or null when there is none.
  ///
  /// The strip is deliberately generic: a screen opts in simply by being live
  /// ([CalculatorPage.onCalculate] is set) and by rendering its answer through
  /// the shared [CalculationResultView], which every calculator already does.
  /// A heavy search (astronomy, alignment) keeps an explicit Calculate action
  /// and never passes [CalculatorPage.onCalculate], so nothing is pinned for a
  /// result that may not track its inputs. A stale result is never summarised
  /// either: a strip describing numbers the inputs have moved past would be
  /// worse than no strip at all.
  CalculationResultView? _liveResult() {
    if (widget.onCalculate == null) return null;
    for (final child in widget.children) {
      if (child is CalculationResultView && !child.stale) return child;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final live = _liveResult();
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(
        AppGap.lg,
        AppGap.lg,
        AppGap.lg,
        AppGap.xxl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: widget.children,
    );
    // Keep the scroll view at the same tree position even when an incomplete
    // edit withdraws the result. Swapping Column/ListView would dispose the
    // focused field (and its keyboard) exactly when the user clears a value.
    // The strip is a layout sibling, never an overlay on the controls.
    return AppContentFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: body),
          if (live != null)
            CalculatorLiveAnswerBar(
              title: live.title,
              highlight: live.highlight,
            ),
        ],
      ),
    );
  }
}

/// A compact, always-visible readout of a live calculator's answer.
///
/// A lightweight calculator answers on every keystroke, but its full
/// [CalculationResultView] can sit far below the inputs it describes - on a
/// phone the baseline half of the exposure comparison alone fills the screen.
/// This strip mirrors the one label/value pair that view leads with, so the
/// answer stays on screen without copying a single number of the physics.
///
/// It is not a control: there is no tap target, no navigation and no state of
/// its own, so it can never read as a button that does nothing.
///
/// It is also a pure mirror in the widget tree: the result card stays the one
/// canonical, addressable node for the answer, and the strip paints the same
/// two strings as rich runs with a single semantics node
/// ([_MirrorText]). Locate the strip by type or by its semantics label rather
/// than by matching result text again.
class CalculatorLiveAnswerBar extends StatelessWidget {
  const CalculatorLiveAnswerBar({
    required this.title,
    required this.highlight,
    super.key,
  });

  /// Name of the result being summarised, used for accessibility only.
  final String title;

  /// The same label/value pair [CalculationResultView.highlight] carries.
  final (String, String) highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      // The label carries the whole announcement; the visual mirror below is
      // the same string, so it is excluded rather than read twice.
      excludeSemantics: true,
      label: '$title: ${highlight.$1} ${highlight.$2}',
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppGap.lg,
                AppGap.sm,
                AppGap.lg,
                AppGap.sm,
              ),
              // A wrap, not a row: at 200 percent text on a 320 wide phone the
              // value drops onto its own line instead of squeezing the label
              // into an ellipsis or overflowing the strip.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppGap.md,
                runSpacing: AppGap.xs,
                children: <Widget>[
                  _MirrorText(
                    value: highlight.$1,
                    valueStyle: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  _MirrorText(
                    value: highlight.$2,
                    valueStyle: theme.textTheme.titleMedium?.tabular,
                    unitStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled numeric input with exact entry plus keyboard-free adjustment.
///
/// The [controller] always carries the canonical raw value the calculator
/// parses. [presets], [step], [min] and [max] are expressed in those same raw
/// units; [displayDivisor] only changes what the field shows and what typed text
/// is multiplied by, and [displayUnit] only labels it. Every path - typing, a
/// preset chip, a stepper button, the slider - writes through that one
/// controller, so no screen has to reconcile two sources of truth.
///
/// Typing stays exact: an out-of-range or higher-precision value is never
/// clamped to fit the slider, and the whole slider is only offered when both
/// bounds are known. The display is a view of the canonical value, never a
/// source for it: [displayDivisor] and [decimalPlaces] reformat what is shown
/// without ever rewriting the precise stored value, which only a real user edit
/// can change.
///
/// One parameter stays one compact block: the exact field with its 48dp
/// steppers beside it (they drop to their own line rather than squeezing the
/// field at large text scales), the presets as a single horizontally
/// scrollable rail whose trailing edge fades while more chips are reachable,
/// and the slider only when a range was supplied.
class CalculatorNumberField extends StatefulWidget {
  const CalculatorNumberField({
    required this.label,
    required this.controller,
    this.fieldKey,
    this.errorText,
    this.presets = const <double>[],
    this.step,
    this.min,
    this.max,
    this.displayDivisor = 1,
    this.displayUnit,
    this.decimalPlaces,
    this.logarithmic = false,
    this.helperText,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? errorText;

  /// Standard values for this quantity, in canonical raw units. Each one is
  /// written straight into [controller] when chosen.
  final List<double> presets;

  /// Canonical raw increment for the decrement/increment buttons. When omitted
  /// but [presets] holds more than one value, the buttons walk the presets.
  final double? step;

  /// Canonical raw bounds. They bound the slider and the steppers only; exact
  /// typed input is never clamped to them.
  final double? min;
  final double? max;

  /// How many canonical raw units one displayed unit is. `1000` shows `1500`
  /// raw as `1.5`.
  final double displayDivisor;

  /// Unit label shown inside the field (`mm`, `s`, `m`).
  final String? displayUnit;

  /// Fixed decimals for the displayed value; omit for the shortest exact form.
  final int? decimalPlaces;

  /// Space the slider logarithmically. Only applies to strictly positive
  /// bounds; any other bounds fall back to a linear slider, which is the
  /// honest presentation for them.
  final bool logarithmic;

  /// Optional supporting line under the field.
  final String? helperText;

  @override
  State<CalculatorNumberField> createState() => _CalculatorNumberFieldState();
}

class _CalculatorNumberFieldState extends State<CalculatorNumberField> {
  /// Keyboard-free adjustment target: the minimum Material asks of any control
  /// a finger has to hit, at every text scale.
  static const double _target = 48;

  /// Width below which an exact-entry field stops being usable beside the
  /// steppers, so they take their own line instead of squeezing it.
  static const double _minEntryWidth = 120;

  /// Display-side controller, used only while the displayed text differs from
  /// the canonical raw text. It is created once and kept for the field's
  /// lifetime, so a mode change can never dispose a controller a live
  /// [TextField] is still holding.
  TextEditingController? _display;
  bool _listeningToDisplay = false;

  /// True while this widget writes [_display]. A [TextEditingController]
  /// notifies synchronously, and a display rounded to fit the field must never
  /// parse back over the precise canonical value: a canonical `1234.56789`
  /// shown in metres as `1.23` must not become `1230`.
  bool _syncingDisplay = false;

  /// True while the canonical write came from the display field itself, so the
  /// text under the cursor is not reformatted mid-edit.
  bool _editingDisplay = false;

  /// Canonical text this field last observed, so a notification that repeats it
  /// (a cursor move in a raw field) is not mistaken for a value change.
  String _canonicalText = '';

  /// Display text this field last wrote or accepted. Selection moves and IME
  /// composing updates leave it identical, and they change no number.
  String _lastDisplayText = '';

  bool get _needsAdapter =>
      widget.displayDivisor != 1 || widget.decimalPlaces != null;

  TextEditingController get _effectiveController =>
      _needsAdapter ? (_display ?? widget.controller) : widget.controller;

  /// The presets that are values at all; a non-finite one is not writable.
  List<double> get _presets =>
      widget.presets.where((preset) => preset.isFinite).toList();

  @override
  void initState() {
    super.initState();
    _canonicalText = widget.controller.text;
    widget.controller.addListener(_handleCanonicalChanged);
    _refreshAdapter();
  }

  @override
  void didUpdateWidget(covariant CalculatorNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleCanonicalChanged);
      widget.controller.addListener(_handleCanonicalChanged);
      _canonicalText = widget.controller.text;
    }
    final adapterChanged =
        oldWidget.displayDivisor != widget.displayDivisor ||
        oldWidget.decimalPlaces != widget.decimalPlaces;
    if (adapterChanged || oldWidget.controller != widget.controller) {
      // A changed divisor, a changed rounding or a swapped controller all mean
      // the displayed text has to be recomputed from the canonical value.
      _refreshAdapter(force: true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleCanonicalChanged);
    _display?.removeListener(_handleDisplayChanged);
    _display?.dispose();
    super.dispose();
  }

  /// Gives the field a display controller exactly while it needs one.
  ///
  /// Without a divisor or fixed decimals the canonical controller is the text
  /// field's own controller, so switching back to plain raw entry can never
  /// leave a stale, unwired display behind.
  void _refreshAdapter({bool force = false}) {
    if (!_needsAdapter) return;
    final display = _display ??= TextEditingController();
    if (!_listeningToDisplay) {
      display.addListener(_handleDisplayChanged);
      _listeningToDisplay = true;
    }
    _syncDisplayFromCanonical(force: force);
  }

  /// Mirrors the canonical value into the displayed text.
  ///
  /// This is a programmatic write and the notification it causes is suppressed:
  /// the display is a scaled, rounded view, and parsing that view back would
  /// replace the precise canonical value with it.
  void _syncDisplayFromCanonical({bool force = false}) {
    final display = _display;
    if (display == null) return;
    final canonicalText = widget.controller.text;
    final raw = canonicalValueFromText(canonicalText);
    // An unparsable canonical value is still shown verbatim: it is what the
    // calculator is reading, and hiding it would be a lie about the input.
    final next = raw == null
        ? canonicalText
        : textFromCanonicalValue(
            raw,
            displayDivisor: widget.displayDivisor,
            decimalPlaces: widget.decimalPlaces,
          );
    _lastDisplayText = next;
    if (!force && display.text == next) return;
    final selection = display.selection;
    final offset = selection.isValid
        ? selection.baseOffset.clamp(0, next.length)
        : next.length;
    _syncingDisplay = true;
    try {
      display.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: offset),
      );
    } finally {
      _syncingDisplay = false;
    }
  }

  void _handleCanonicalChanged() {
    final incoming = widget.controller.text;
    if (incoming == _canonicalText) return;
    _canonicalText = incoming;
    if (!mounted) return;
    // The display is a pure mirror of the canonical value, so a change from
    // anywhere (typing, applied equipment, a reset) reaches it here - unless it
    // came from the display itself, which must not be reformatted under the
    // cursor.
    if (_needsAdapter && !_editingDisplay) _syncDisplayFromCanonical();
    // A screen may also rewrite the controller while it is building; a nested
    // setState is not allowed there, and the frame already in flight is
    // rendering the new value anyway.
    if (_insideFrame) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    // The keyboard-free controls read the controller directly and have no other
    // rebuild source, so this is what advances a second step, disables a button
    // at its bound, or moves the slider after an external edit.
    setState(() {});
  }

  static bool get _insideFrame {
    final phase = SchedulerBinding.instance.schedulerPhase;
    return phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
  }

  void _handleDisplayChanged() {
    // A programmatic mirror is not an edit.
    if (_syncingDisplay) return;
    if (!_needsAdapter) return;
    final display = _display;
    if (display == null) return;
    final text = display.value.text;
    // Moving the cursor, or an IME composition update, changes no number:
    // parsing the unchanged (and possibly rounded) display back would rewrite
    // the precise canonical value for nothing.
    if (text == _lastDisplayText) return;
    _lastDisplayText = text;
    final raw = canonicalValueFromText(
      text,
      displayDivisor: widget.displayDivisor,
    );
    // Empty or unparsable text clears the canonical value rather than keeping a
    // stale number the calculator would silently keep using.
    final next = raw == null ? '' : _exactCanonicalText(raw);
    if (widget.controller.text == next) return;
    _editingDisplay = true;
    try {
      widget.controller.text = next;
    } finally {
      _editingDisplay = false;
    }
  }

  /// Writes a canonical raw value. Only this widget calls it - a preset chip, a
  /// stepper or the slider - so the display always follows the canonical value.
  void _writeCanonical(double raw) {
    if (!raw.isFinite) return;
    // The canonical listener mirrors the new value into the display and
    // rebuilds the controls. It stays silent when a step lands on the value the
    // controller already holds, which needs no redraw either.
    widget.controller.text = _exactCanonicalText(raw);
  }

  double? get _stepSize {
    final step = widget.step;
    if (step == null || !step.isFinite || step <= 0) return null;
    return step;
  }

  bool get _canStep => _stepSize != null || _presets.length > 1;

  /// The value a decrement ([direction] -1) or increment (+1) button would
  /// write, or null when that write is not allowed.
  double? _steppedValue(int direction) {
    final current = canonicalValueFromText(widget.controller.text);
    final step = _stepSize;
    if (step != null) {
      final base = current ?? widget.min ?? 0;
      final next = base + direction * step;
      if (!next.isFinite || !_stepAllowed(base, next)) return null;
      return next;
    }
    final presets = _presets..sort();
    if (presets.length < 2) return null;
    if (current == null) return direction < 0 ? presets.last : presets.first;
    const tolerance = 1e-9;
    if (direction > 0) {
      for (final preset in presets) {
        if (preset > current + tolerance) return preset;
      }
      return null;
    }
    for (final preset in presets.reversed) {
      if (preset < current - tolerance) return preset;
    }
    return null;
  }

  /// A step is allowed when it stays inside the bounds - or, for a value the
  /// user typed outside them (exact entry is never clamped, so that is a real
  /// state), when it moves back toward them.
  bool _stepAllowed(double from, double next) {
    final outside = _distanceOutside(from);
    if (outside > 0) return _distanceOutside(next) < outside;
    return !_belowMin(next) && !_aboveMax(next);
  }

  double _distanceOutside(double value) {
    final min = widget.min;
    final max = widget.max;
    var distance = 0.0;
    if (min != null && value < min) distance += min - value;
    if (max != null && value > max) distance += value - max;
    return distance;
  }

  bool _belowMin(double value) {
    final min = widget.min;
    if (min == null) return false;
    return value < min - _boundTolerance(min, value);
  }

  bool _aboveMax(double value) {
    final max = widget.max;
    if (max == null) return false;
    return value > max + _boundTolerance(max, value);
  }

  /// Stepping writes a computed value straight into the controller, so a
  /// floating-point crumb (0.7999999999999999 for 0.8) must not read as out of
  /// range.
  static double _boundTolerance(double bound, double value) =>
      1e-9 * math.max(1, math.max(bound.abs(), value.abs()));

  String _displayText(double raw) {
    final text = textFromCanonicalValue(
      raw,
      displayDivisor: widget.displayDivisor,
      decimalPlaces: widget.decimalPlaces,
    );
    final unit = widget.displayUnit;
    return unit == null ? text : '$text $unit';
  }

  @override
  Widget build(BuildContext context) {
    final lower = widget.min;
    final upper = widget.max;
    final bounded =
        lower != null &&
        upper != null &&
        lower.isFinite &&
        upper.isFinite &&
        lower < upper;
    final presets = _presets;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppGap.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildEntry(context),
          if (presets.isNotEmpty)
            CalculatorChipRail(
              semanticsLabel: '${widget.label} presets',
              children: <Widget>[
                for (final preset in presets) _buildPresetChip(preset),
              ],
            ),
          if (bounded) _buildSlider(context, lower, upper),
        ],
      ),
    );
  }

  /// The exact-entry field, with its keyboard-free steppers beside it whenever
  /// there is room for both at this text scale.
  Widget _buildEntry(BuildContext context) {
    final theme = Theme.of(context);
    final field = TextField(
      key: widget.fieldKey,
      controller: _effectiveController,
      style: theme.textTheme.titleMedium,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        helperText: widget.helperText,
        suffixText: widget.displayUnit,
      ),
    );
    if (!_canStep) return field;
    final steppers = _buildSteppers();
    return LayoutBuilder(
      builder: (context, constraints) {
        // The steppers keep their full targets at every text scale, so what
        // gives way at 200 percent text is the row: they drop under the field
        // instead of squeezing it into an unusable width.
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final besideField = _target * 2 + AppGap.xs;
        final fitsBeside =
            constraints.maxWidth - besideField >=
            _minEntryWidth * math.max(1.0, scale);
        if (!fitsBeside) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              field,
              const SizedBox(height: AppGap.xs),
              Align(alignment: Alignment.centerLeft, child: steppers),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: field),
            const SizedBox(width: AppGap.xs),
            Padding(
              padding: const EdgeInsets.only(top: AppGap.xs),
              child: steppers,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSteppers() {
    final decrease = _steppedValue(-1);
    final increase = _steppedValue(1);
    // Both buttons carry the same explicit 48dp box, so the target does not
    // depend on the ambient density or on the font the device happens to ship.
    final style = IconButton.styleFrom(
      minimumSize: const Size.square(_target),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: 'Decrease ${widget.label}',
          onPressed: decrease == null ? null : () => _writeCanonical(decrease),
          icon: const Icon(Icons.remove),
          style: style,
        ),
        IconButton(
          tooltip: 'Increase ${widget.label}',
          onPressed: increase == null ? null : () => _writeCanonical(increase),
          icon: const Icon(Icons.add),
          style: style,
        ),
      ],
    );
  }

  Widget _buildPresetChip(double preset) {
    final label = _displayText(preset);
    return Tooltip(
      message: 'Set ${widget.label} to $label',
      child: ChoiceChip(
        label: Text(label),
        selected: _presetSelected(preset),
        onSelected: (_) => _writeCanonical(preset),
      ),
    );
  }

  /// Whether the controller already holds this preset, within the floating
  /// point tolerance a canonical round trip can introduce.
  bool _presetSelected(double preset) {
    final current = canonicalValueFromText(widget.controller.text);
    if (current == null) return false;
    return (current - preset).abs() <= _boundTolerance(preset, current);
  }

  Widget _buildSlider(BuildContext context, double lower, double upper) {
    // A logarithmic slider is only honest for strictly positive bounds; every
    // other range is presented linearly.
    final logarithmic = widget.logarithmic && lower > 0;
    final sliderMin = logarithmic ? math.log(lower) : lower;
    final sliderMax = logarithmic ? math.log(upper) : upper;
    final raw = canonicalValueFromText(widget.controller.text);
    final clampedRaw = raw == null ? lower : raw.clamp(lower, upper).toDouble();
    final position = logarithmic ? math.log(clampedRaw) : clampedRaw;
    final step = _stepSize;
    final rawDivisions = step == null ? null : ((upper - lower) / step).round();
    final divisions =
        !logarithmic &&
            rawDivisions != null &&
            rawDivisions > 0 &&
            rawDivisions <= 1000
        ? rawDivisions
        : null;
    double rawFromSlider(double value) =>
        (logarithmic ? math.exp(value) : value).clamp(lower, upper).toDouble();

    return SliderTheme(
      // Compact by design: a thin track keeps the row visually quiet, while the
      // slider keeps its own interaction padding for the finger.
      data: SliderTheme.of(context).copyWith(trackHeight: 4),
      child: Semantics(
        container: true,
        label: '${widget.label} slider',
        child: Slider(
          value: position.clamp(sliderMin, sliderMax).toDouble(),
          min: sliderMin,
          max: sliderMax,
          divisions: divisions,
          label: _displayText(clampedRaw),
          semanticFormatterCallback: (value) =>
              _displayText(rawFromSlider(value)),
          onChanged: (value) => _writeCanonical(rawFromSlider(value)),
        ),
      ),
    );
  }
}

/// One row of chips that scrolls sideways instead of wrapping.
///
/// Seven or nine presets wrapping into three rows is what makes a calculator
/// feel cluttered: the rail keeps the parameter to a single row, marks the
/// value the controller already holds, and fades its trailing edge while there
/// is more to reach so the overflow reads as "this scrolls" rather than as a
/// clipped control. It is a real scroll view - no invented gesture - and the
/// chips keep their own semantics and 48dp targets.
///
/// Shared by the numeric presets inside [CalculatorNumberField] and by the
/// capture family's camera-value chips, so both speak one compact language.
class CalculatorChipRail extends StatefulWidget {
  const CalculatorChipRail({
    required this.semanticsLabel,
    required this.children,
    this.padding = const EdgeInsets.only(top: AppGap.xs),
    super.key,
  });

  /// Accessibility name for the whole strip of options.
  final String semanticsLabel;

  /// The chips, in scroll order. All of them are built, so a screen reader and
  /// a keyboard can reach the far end without a gesture.
  final List<Widget> children;

  final EdgeInsetsGeometry padding;

  @override
  State<CalculatorChipRail> createState() => _CalculatorChipRailState();
}

class _CalculatorChipRailState extends State<CalculatorChipRail> {
  final ScrollController _scroll = ScrollController();
  bool _moreToReach = false;

  @override
  void initState() {
    super.initState();
    // Scrolling changes no metrics, so the metrics notification alone would
    // leave the fade on screen after the end of the rail was reached.
    _scroll.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_handleScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final positions = _scroll.positions;
    if (positions.isEmpty) return;
    _applyMoreToReach(positions.first);
  }

  bool _handleMetrics(ScrollMetricsNotification notification) {
    _applyMoreToReach(notification.metrics);
    return false;
  }

  void _applyMoreToReach(ScrollMetrics metrics) {
    final more =
        metrics.maxScrollExtent > 0.5 &&
        metrics.pixels < metrics.maxScrollExtent - 0.5;
    if (more != _moreToReach) {
      setState(() => _moreToReach = more);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      child: Padding(
        padding: widget.padding,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _handleMetrics,
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final child in widget.children)
                      Padding(
                        padding: const EdgeInsets.only(right: AppGap.sm),
                        child: child,
                      ),
                  ],
                ),
              ),
              if (_moreToReach)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: 24,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            theme.colorScheme.surface.withValues(alpha: 0),
                            theme.colorScheme.surface,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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

/// Keeps a small, stateful disclosure alive while a lazy list scrolls it away.
///
/// A [ListView] evicts the elements it scrolls far past. A calculator's
/// secondary inputs ([CalculatorAdvancedSection]) and its "Details" subtree
/// ([_DetailsSection]) are [ExpansionTile]s, so eviction silently collapses a
/// section the user just opened - and re-expanding it to read a value is
/// exactly the friction this kit exists to remove.
///
/// [AutomaticKeepAliveClientMixin] tells the list's own delegate to retain
/// precisely this subtree, so the open/closed state survives real viewport
/// eviction. Only these two small sections opt in: the device/AR previews and
/// other heavy surfaces are never kept alive by it.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin<_KeepAlive> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// A collapsed group of secondary inputs.
///
/// Photographers act on two or three numbers per calculator; everything else is
/// a convention or a preference. Keeping those fields behind one expander
/// leaves the default screen readable without removing any control. The group
/// keeps its open state while it is scrolled out of view.
class CalculatorAdvancedSection extends StatelessWidget {
  const CalculatorAdvancedSection({
    required this.children,
    this.title = 'More settings',
    this.subtitle,
    this.initiallyExpanded = false,
    super.key,
  });

  final List<Widget> children;
  final String title;

  /// Optional one-line explanation of what the group holds.
  final String? subtitle;

  /// Open on first build - for a screen whose secondary group is the point.
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => _KeepAlive(
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4),
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: initiallyExpanded,
        leading: const Icon(Icons.tune),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        children: children,
      ),
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
    this.stale = false,
    this.staleNotice = 'Inputs changed. Recalculate to refresh this result.',
    this.actions = const <Widget>[],
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

  /// Set when the inputs have moved on since this result was produced. The card
  /// then says so instead of presenting numbers that no longer describe them.
  final bool stale;
  final String staleNotice;

  /// Extra actions rendered under the save/reset row.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '$title calculation result'
          '${stale ? ' (out of date)' : ''}: ${highlight.$1} ${highlight.$2}'
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
                if (stale) ...<Widget>[
                  const SizedBox(height: AppGap.sm),
                  _StaleNotice(notice: staleNotice),
                ],
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
                if (actions.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppGap.sm),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppGap.sm,
                    runSpacing: AppGap.xs,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Says plainly that the numbers below no longer describe the current inputs.
class _StaleNotice extends StatelessWidget {
  const _StaleNotice({required this.notice});

  final String notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.update, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppGap.sm),
        Expanded(
          child: Text(
            notice,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
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
    return _KeepAlive(
      child: Container(
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
