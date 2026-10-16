/// Shared control vocabulary for the capture family.
///
/// Exposure comparison, long exposure, flash, timelapse and panorama are one
/// family the way the focus tools are: they share the live-answer signal and
/// the keyboard-free chips for the camera values a photographer says out loud
/// (`1/125`, `1/128 power`, `10 stops`), but no domain code. Keeping that
/// vocabulary in one library stops the chip rows and the live signal from
/// drifting apart between the five screens.
///
/// Everything here writes through the *same* canonical controller the field
/// edits, so a chip can never become a second source of truth.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/presentation/calculator/calculator_components.dart';

/// One-line signal that the answer on screen tracks the inputs live.
///
/// These five tools are cheap to evaluate, so there is no Calculate button:
/// every keystroke, chip, slider and orientation change recalculates.
class CaptureLiveHint extends StatelessWidget {
  const CaptureLiveHint({this.label = 'Updates as you adjust', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppGap.md),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.bolt_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppGap.xs),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet heading for one group of inputs (a scene side, a setup).
class CaptureSectionHeading extends StatelessWidget {
  const CaptureSectionHeading({
    required this.title,
    this.caption,
    this.action,
    super.key,
  });

  final String title;

  /// Optional one-line explanation printed under the title.
  final String? caption;

  /// Optional control placed with the title while there is room for both.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleSmall),
        if (caption case final text?)
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppGap.sm, bottom: AppGap.xs),
      child: action == null
          ? heading
          : LayoutBuilder(
              builder: (context, constraints) {
                // Below this width a trailing action squeezes the caption into
                // a column of single words (and two stop buttons no longer fit
                // beside it at 200 percent text), so the action drops onto its
                // own line instead of shrinking the text it sits beside.
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      heading,
                      if (action case final widget?)
                        Align(alignment: Alignment.centerLeft, child: widget),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: heading),
                    ?action,
                  ],
                );
              },
            ),
    );
  }
}

/// A row of camera-value chips.
///
/// A long parameter list - every full shutter stop, the whole flash dial, the
/// ND strengths - is one horizontally scrollable rail with the shared compact
/// language of the numeric fields' preset rails, so ten stops never wrap into
/// three rows. A short list (a mode, an orientation) still wraps: it fits, and
/// a rail there would only hide a choice behind a scroll for nothing.
class CaptureChipRow extends StatelessWidget {
  const CaptureChipRow({
    required this.chips,
    this.caption,
    this.trailing,
    this.rail,
    super.key,
  });

  /// Chip count at which a list stops fitting a phone row and becomes a rail.
  static const int railThreshold = 6;

  final List<Widget> chips;

  /// Optional quiet line above the row.
  final String? caption;

  /// Optional control at the end of the caption line.
  final Widget? trailing;

  /// Force a rail ([true]) or wrapping ([false]); omit to choose by length.
  final bool? rail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captionText = caption;
    final useRail = rail ?? chips.length >= railThreshold;
    final row = useRail
        ? CalculatorChipRail(
            semanticsLabel: captionText == null
                ? 'Preset values'
                : '$captionText presets',
            children: chips,
          )
        : Wrap(
            spacing: AppGap.sm,
            runSpacing: AppGap.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: chips,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppGap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (captionText != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppGap.xs),
              child: captionText == null
                  // Only an action: the row bounds it, so a label too wide for
                  // the line (200 percent text on a narrow phone) wraps inside
                  // the action instead of overflowing the row.
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        if (trailing case final action?)
                          Flexible(fit: FlexFit.loose, child: action),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            captionText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
            ),
          row,
        ],
      ),
    );
  }
}

/// A one-tap choice for a value written through the field's own controller.
///
/// [selected] marks the value the controller already holds, so the row doubles
/// as a readout of what is currently dialled in.
class CaptureChoiceChip<T> extends StatelessWidget {
  const CaptureChoiceChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
    this.tooltip,
    super.key,
  });

  final String label;
  final T value;
  final bool selected;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget chip = ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// The full-stop shutter times every camera offers, as RAW seconds.
///
/// These are the values a photographer reads off the dial, so they label the
/// shutter chips; the canonical controller still receives seconds.
const List<(String, double)> commonShutterStops = <(String, double)>[
  ('1/2000', 0.0005),
  ('1/1000', 0.001),
  ('1/500', 0.002),
  ('1/250', 0.004),
  ('1/125', 0.008),
  ('1/60', 1 / 60),
  ('1/30', 1 / 30),
  ('1/15', 1 / 15),
  ('1/8', 0.125),
  ('1/4', 0.25),
  ('1/2', 0.5),
  ('1 s', 1),
  ('2 s', 2),
  ('4 s', 4),
  ('8 s', 8),
  ('15 s', 15),
  ('30 s', 30),
];

/// Flash power as the fractions a speedlight shows, RAW fraction of full power.
const List<(String, double)> commonFlashPowerFractions = <(String, double)>[
  ('1/1', 1),
  ('1/2', 0.5),
  ('1/4', 0.25),
  ('1/8', 0.125),
  ('1/16', 0.0625),
  ('1/32', 0.03125),
  ('1/64', 0.015625),
  ('1/128', 0.0078125),
];

/// The stops a photographer stacks most often, in raw ND stops.
const List<double> commonNdStops = <double>[1, 2, 3, 4, 5, 6, 7, 10, 15];

/// A shutter time in the wording a photographer uses: `1/125`, `2`.
///
/// Only an exact full-stop fraction is named as one; anything else keeps its
/// precise decimal form rather than being rounded to a plausible fraction.
String familiarShutterValue(double seconds) {
  if (!seconds.isFinite || seconds <= 0) return '—';
  if (seconds >= 1) return textFromCanonicalValue(seconds);
  final reciprocal = 1 / seconds;
  final rounded = reciprocal.roundToDouble();
  if (rounded > 0 && (reciprocal - rounded).abs() <= reciprocal * 1e-9) {
    return '1/${rounded.toStringAsFixed(0)}';
  }
  return textFromCanonicalValue(seconds);
}

/// The shortest exact decimal text for a shutter-time controller.
///
/// Fields whose canonical unit is plain seconds (`0.008`, not `1/125`) get
/// this, so the value the calculator parses round-trips with no extra text.
String shutterSecondsText(double seconds) => textFromCanonicalValue(seconds);

/// The power wording a speedlight uses: `1/128`, or null when the fraction is
/// not one of the marked dial positions.
String? flashPowerValueLabel(double fraction) {
  if (!fraction.isFinite || fraction <= 0 || fraction > 1) return null;
  for (final (label, value) in commonFlashPowerFractions) {
    if (matchesValue(fraction, value)) return label;
  }
  return null;
}

/// True when [value] is the [expected] dial position, within float tolerance.
///
/// Chips write a shortened decimal, so exact `==` would drop the selected mark
/// from the value the user just chose.
bool matchesValue(double? value, double expected) {
  if (value == null || !value.isFinite || !expected.isFinite) return false;
  final scale = expected.abs() < 1 ? 1.0 : expected.abs();
  return (value - expected).abs() <= scale * 1e-9 + 1e-12;
}

/// The ND stop a chip adds or removes from a comma-separated stack.
///
/// The stack is a list, not a sum, so the chip toggles its own value: adding a
/// strength a photographer stacks twice (two 3-stop filters) is still allowed
/// by typing it, and no typed or invalid token is ever silently discarded.
List<String> toggledNdStack(String text, double stops) {
  final tokens = text
      .split(',')
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .toList();
  final label = textFromCanonicalValue(stops);
  for (var index = 0; index < tokens.length; index++) {
    final parsed = double.tryParse(tokens[index]);
    if (matchesValue(parsed, stops) || tokens[index] == label) {
      final remaining = <String>[...tokens];
      remaining.removeAt(index);
      return remaining;
    }
  }
  return <String>[...tokens, label];
}
