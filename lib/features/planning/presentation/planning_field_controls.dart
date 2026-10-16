/// Shared field-workbench controls for the alignment and night-sky planners.
///
/// Both planners follow one workflow: site, then time, then the target, then an
/// explicit search. These widgets keep that shape consistent, keep the common
/// choices one tap away, and let the shortcut rows wrap instead of overflowing
/// on a narrow phone or at 200% text.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/design_tokens.dart';

/// The field workbench both planners return: one scrolling form with the
/// explicit action pinned beneath it.
///
/// The action is a sibling of the scroll view, not an overlay and not the last
/// item inside it, so it stays one tap away at every scroll offset while the
/// form above it keeps the whole viewport minus the action's natural height.
/// Nothing is covered and nothing is scrolled under: the strip is painted, not
/// floated over the fields.
class PlanningWorkbench extends StatelessWidget {
  const PlanningWorkbench({
    required this.body,
    required this.action,
    super.key,
  });

  /// The planner's scrolling form and result - normally a `CalculatorPage`.
  final Widget body;

  /// The explicit action, pinned at its natural height under [body].
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Expanded(child: body),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppGap.lg,
                vertical: AppGap.md,
              ),
              // The bar keeps the form's own width frame, so the action lines up
              // with the fields it acts on instead of stretching on a tablet.
              child: AppContentFrame(
                child: SizedBox(width: double.infinity, child: action),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One stage of the field workflow, with a live summary of its values.
class PlanningSectionHeader extends StatelessWidget {
  const PlanningSectionHeader({
    required this.icon,
    required this.title,
    this.summary,
    super.key,
  });

  final IconData icon;
  final String title;

  /// Live description of the section's current values, printed under the title
  /// so a collapsed or scrolled-away control still states what it holds.
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppGap.lg, bottom: AppGap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppGap.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
                if (summary case final widget?) ...<Widget>[
                  const SizedBox(height: AppGap.xs),
                  widget,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapped row of chips: the row re-flows instead of overflowing.
class PlanningChipRow extends StatelessWidget {
  const PlanningChipRow({required this.chips, super.key});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: AppGap.sm, runSpacing: AppGap.xs, children: chips);
}

/// A one-tap shortcut for a common value or range.
///
/// A [selected] value turns the chip into a persistent choice whose state is
/// announced; without one the chip stays a plain one-shot action.
class PlanningShortcutChip extends StatelessWidget {
  const PlanningShortcutChip({
    required this.label,
    required this.onPressed,
    this.selected,
    this.tooltip,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool? selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected;
    final Widget chip = isSelected == null
        ? ActionChip(label: Text(label), onPressed: onPressed)
        : ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onPressed(),
          );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// Text that follows input controllers without rebuilding the whole screen.
///
/// Section summaries read the same controllers the fields write, so a summary
/// can never disagree with the field above it.
class PlanningLiveText extends StatelessWidget {
  const PlanningLiveText({
    required this.controllers,
    required this.text,
    this.style,
    super.key,
  });

  final List<TextEditingController> controllers;
  final String Function() text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge(controllers),
    builder: (context, _) => Text(text(), style: style),
  );
}

/// A compact disclosure for a site's rarely adjusted values.
///
/// The collapsed row states the value the group holds - and any validation error
/// - so exact entry stays reachable without spending the viewport on a field
/// that is set once per trip. The coordinates that have to be exact stay on the
/// screen itself; only the elevation they rarely change lives in here.
class PlanningSiteDetails extends StatefulWidget {
  const PlanningSiteDetails({
    required this.summary,
    required this.children,
    this.title = 'Site details',
    this.errorText,
    super.key,
  });

  final String title;

  /// Live one-line statement of what the collapsed group holds.
  final Widget summary;

  /// Validation message for a field inside the group. A value that just became
  /// invalid opens the group, because a message about a hidden field is not a
  /// disclosure.
  final String? errorText;

  final List<Widget> children;

  @override
  State<PlanningSiteDetails> createState() => _PlanningSiteDetailsState();
}

class _PlanningSiteDetailsState extends State<PlanningSiteDetails> {
  final _expansion = ExpansibleController();

  @override
  void didUpdateWidget(PlanningSiteDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opening on a new error, but never closing when one clears: correcting the
    // value must not collapse the field that is being corrected. The move is
    // deferred by one frame so the group animates open after the rebuild that
    // carried the error, not in the middle of it.
    if (widget.errorText != null && oldWidget.errorText == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _expansion.expand();
      });
    }
  }

  @override
  void dispose() {
    _expansion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = widget.errorText;
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        controller: _expansion,
        initiallyExpanded: error != null,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: AppGap.xs),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.terrain_outlined),
        title: Text(widget.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            widget.summary,
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppGap.xs),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
        children: widget.children,
      ),
    );
  }
}

/// The tone of a [PlanningNote].
enum PlanningNoteTone { info, warning }

/// A short, honest note about the plan's current state.
class PlanningNote extends StatelessWidget {
  const PlanningNote({
    required this.message,
    this.tone = PlanningNoteTone.info,
    super.key,
  });

  final String message;
  final PlanningNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = tone == PlanningNoteTone.warning;
    final background = warning
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.secondaryContainer;
    final foreground = warning
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSecondaryContainer;
    return Semantics(
      container: true,
      label: message,
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(top: AppGap.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppGap.md,
          vertical: AppGap.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.controlAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              warning ? Icons.warning_amber_rounded : Icons.info_outline,
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: AppGap.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
