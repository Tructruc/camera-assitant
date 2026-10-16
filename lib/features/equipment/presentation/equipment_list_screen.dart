/// Accessible equipment inventory list and recovery states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/domain/repositories/equipment_repository.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../domain/equipment.dart';
import 'equipment_controller.dart';
import 'equipment_editor_screen.dart';
import 'equipment_specs.dart';

class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() =>
      _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  /// What a fixed inset used to reserve, kept as the value for the first frame.
  static const double _fallbackReservedBottom = 96;

  final GlobalKey _addButtonKey = GlobalKey();

  /// Space the list must leave clear at its end so the floating add button
  /// never sits on the last row.
  ///
  /// The button is overlaid on the list rather than laid out beside it, and its
  /// height follows the system text scale: at 200% text on a gesture-bar phone
  /// it is 80px tall inside 16px of padding above a 34px safe area, which the
  /// fixed 96px this used to reserve does not cover - the last row's subtitle
  /// ended up 18px behind the button. It is measured per layout instead of
  /// guessed, and written only when the value really moves, so it settles after
  /// one frame.
  double _reservedBottom = _fallbackReservedBottom;

  void _measureAddButton() {
    final button = _addButtonKey.currentContext?.findRenderObject();
    if (button is! RenderBox || !button.hasSize) return;
    final reserved =
        button.size.height + MediaQuery.paddingOf(context).bottom + 32;
    if ((reserved - _reservedBottom).abs() < 0.5) return;
    setState(() => _reservedBottom = reserved);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(equipmentControllerProvider);
    final controller = ref.read(equipmentControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAddButton());
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              _InventoryFilterBar(
                state: state,
                onKindSelected: controller.setKind,
                onIncludeArchivedChanged: controller.setIncludeArchived,
              ),
              Expanded(child: _content(state, controller, ref)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppGap.lg),
                child: Semantics(
                  button: true,
                  label: 'Add equipment',
                  child: FilledButton.icon(
                    key: _addButtonKey,
                    onPressed: () => _chooseKind(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add equipment'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(
    EquipmentState state,
    EquipmentController controller,
    WidgetRef ref,
  ) {
    return switch (state.status) {
      // The skeleton measures itself against the space it is given and never
      // overflows, so it is laid out directly rather than through _scrollable:
      // a sliver asks its child for an intrinsic height, which a builder
      // cannot answer.
      EquipmentLoadStatus.loading => const Center(
        child: LoadingSkeleton(label: 'Loading equipment'),
      ),
      EquipmentLoadStatus.error => _scrollable(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppGap.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Equipment could not be loaded.'),
                const SizedBox(height: AppGap.md),
                OutlinedButton(
                  onPressed: controller.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      // Nothing saved at all, and a filter that happens to match nothing, are
      // different answers: the second one must not claim the shelf is empty
      // while gear sits behind another category.
      EquipmentLoadStatus.ready when state.allItems.isEmpty => _scrollable(
        const EmptyState(
          icon: Icons.camera_alt_outlined,
          title: 'No equipment yet',
          description:
              'Add a camera, lens, filter, tube, or converter for faster calculations.',
        ),
      ),
      EquipmentLoadStatus.ready
          when state.items.isEmpty && state.selectedKind != null =>
        _scrollable(
          EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'Nothing in ${_kindPlural(state.selectedKind!)}',
            description:
                'Another category holds the rest of the kit. '
                'Show every item again, or add one here.',
            action: OutlinedButton(
              onPressed: () => controller.setKind(null),
              child: const Text('Show all equipment'),
            ),
          ),
        ),
      EquipmentLoadStatus.ready => ListView.builder(
        // The floating add button covers the tail of this list, so its measured
        // height plus the safe area is reserved here (see _reservedBottom).
        padding: EdgeInsets.fromLTRB(
          AppGap.lg,
          AppGap.sm,
          AppGap.lg,
          _reservedBottom,
        ),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final entry = state.items[index];
          return _EquipmentCard(
            entry: entry,
            onEdit: () =>
                _openEditor(context, ref, entry, checkReferences: true),
            onDuplicate: () =>
                _openEditor(context, ref, entry, duplicate: true),
            onArchive: () => _archive(context, ref, entry),
            onDelete: () => _remove(context, ref, entry),
            onRestore: () => _restore(context, ref, entry),
          );
        },
      ),
    };
  }

  /// A message or first-run state that scrolls rather than overflowing when the
  /// system text scale is at its largest. A sliver, not a nested scroll view:
  /// the one horizontal scroller on this screen stays the only
  /// [SingleChildScrollView] the filter row owns.
  Widget _scrollable(Widget child) => CustomScrollView(
    slivers: <Widget>[SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  Future<void> _chooseKind(BuildContext context) async {
    final kind = await showModalBottomSheet<EquipmentKind>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: EquipmentKind.values
              .map(
                (item) => ListTile(
                  leading: Icon(_kindIcon(item)),
                  title: Text('Add ${_kindLabel(item).toLowerCase()}'),
                  onTap: () => Navigator.pop(context, item),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (kind != null && context.mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Add ${_kindLabel(kind).toLowerCase()}'),
            ),
            body: EquipmentEditorScreen(kind: kind),
          ),
        ),
      );
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    EquipmentListEntry entry, {
    bool duplicate = false,
    bool checkReferences = false,
  }) async {
    if (checkReferences &&
        !await _confirmReferencedMutation(context, ref, entry, 'edit')) {
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              duplicate
                  ? 'Duplicate ${_kindLabel(entry.kind).toLowerCase()}'
                  : 'Edit ${_kindLabel(entry.kind).toLowerCase()}',
            ),
          ),
          body: EquipmentEditorScreen(
            kind: entry.kind,
            item: entry.item,
            duplicate: duplicate,
          ),
        ),
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    EquipmentListEntry entry,
  ) async {
    final repository = ref.read(equipmentRepositoryProvider);
    final EquipmentReferenceImpact impact;
    try {
      impact = await repository.referenceImpact(entry.item.id);
    } on Object {
      if (context.mounted) _reportMutationFailure(context);
      return;
    }
    if (!context.mounted) return;
    if (impact.isReferenced) {
      final archive = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Archive referenced equipment?'),
          content: Text(
            '${entry.item.name} cannot be permanently deleted because it is used by ${impact.snapshotCount} saved ${impact.snapshotCount == 1 ? 'result or plan' : 'results or plans'}. Archiving hides it from active equipment while saved snapshots keep their original applied values and will not be recalculated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Archive anyway'),
            ),
          ],
        ),
      );
      if (archive == true && context.mounted) {
        // The reference warning was already shown above, so archive directly
        // instead of asking a second time.
        final archived = await ref
            .read(equipmentControllerProvider.notifier)
            .archive(entry);
        if (!archived && context.mounted) _reportMutationFailure(context);
      }
      return;
    }
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete equipment?'),
        content: Text(
          '${entry.item.name} is not used by a saved result or plan. This permanently removes it from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (delete == true) {
      final deleted = await ref
          .read(equipmentControllerProvider.notifier)
          .delete(entry);
      if (!deleted && context.mounted) _reportMutationFailure(context);
    }
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    EquipmentListEntry entry,
  ) async {
    if (!await _confirmReferencedMutation(context, ref, entry, 'archive')) {
      return;
    }
    if (!context.mounted) return;
    final archived = await ref
        .read(equipmentControllerProvider.notifier)
        .archive(entry);
    if (!archived && context.mounted) _reportMutationFailure(context);
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    EquipmentListEntry entry,
  ) async {
    final restored = await ref
        .read(equipmentControllerProvider.notifier)
        .restore(entry);
    if (!restored && context.mounted) _reportMutationFailure(context);
  }

  /// One recovery message for every equipment mutation that fails, so a
  /// database error never reaches the user as an unhandled exception (FR-021).
  void _reportMutationFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The equipment change could not be saved. Nothing was changed; check the values and try again.',
        ),
      ),
    );
  }

  Future<bool> _confirmReferencedMutation(
    BuildContext context,
    WidgetRef ref,
    EquipmentListEntry entry,
    String action,
  ) async {
    final EquipmentReferenceImpact impact;
    try {
      impact = await ref
          .read(equipmentRepositoryProvider)
          .referenceImpact(entry.item.id);
    } on Object {
      // Failing to determine the impact must not fall through to a permanent
      // delete; treat it as a refusal and say why.
      if (context.mounted) _reportMutationFailure(context);
      return false;
    }
    if (!impact.isReferenced || !context.mounted) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              '${action == 'edit' ? 'Edit' : 'Archive'} referenced equipment?',
            ),
            content: Text(
              '${entry.item.name} is used by ${impact.snapshotCount} saved ${impact.snapshotCount == 1 ? 'result or plan' : 'results or plans'}. Saved snapshots keep their original applied values and will not be recalculated.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  action == 'edit' ? 'Edit anyway' : 'Archive anyway',
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// The count summary and the category filters of the inventory.
///
/// Every chip carries the number of items it would show, so the shelf can be
/// read before it is filtered instead of after a guess.
class _InventoryFilterBar extends StatelessWidget {
  const _InventoryFilterBar({
    required this.state,
    required this.onKindSelected,
    required this.onIncludeArchivedChanged,
  });

  final EquipmentState state;
  final ValueChanged<EquipmentKind?> onKindSelected;
  final ValueChanged<bool> onIncludeArchivedChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = <EquipmentKind, int>{
      for (final kind in EquipmentKind.values)
        kind: state.allItems.where((entry) => entry.kind == kind).length,
    };
    final summary = _summary(state);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppGap.lg, AppGap.md, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // A shelf with nothing on it needs no count: the empty state below
          // already says so, and the row is not spent at any text scale.
          if (summary != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(right: AppGap.lg),
              child: Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppGap.sm),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: AppGap.lg, bottom: AppGap.xs),
            child: Row(
              children: <Widget>[
                FilterChip(
                  label: Text('All (${state.allItems.length})'),
                  selected: state.selectedKind == null,
                  onSelected: (_) => onKindSelected(null),
                ),
                const SizedBox(width: AppGap.sm),
                for (final kind in EquipmentKind.values) ...<Widget>[
                  FilterChip(
                    label: Text('${_kindPlural(kind)} (${counts[kind] ?? 0})'),
                    selected: state.selectedKind == kind,
                    onSelected: (_) => onKindSelected(kind),
                  ),
                  const SizedBox(width: AppGap.sm),
                ],
                FilterChip(
                  label: const Text('Include archived'),
                  selected: state.includeArchived,
                  onSelected: onIncludeArchivedChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// How many items the current filter shows, or `null` when there are none to
  /// count.
  static String? _summary(EquipmentState state) {
    if (state.items.isEmpty) return null;
    final kind = state.selectedKind;
    final shown = state.items.length;
    final label = kind == null
        ? '$shown ${shown == 1 ? 'item' : 'items'}'
        : '$shown ${_kindPlural(kind).toLowerCase()}';
    return state.includeArchived ? '$label · archived shown' : label;
  }
}

enum _EquipmentAction { duplicate, archive, delete, restore }

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.entry,
    required this.onEdit,
    required this.onDuplicate,
    required this.onArchive,
    required this.onDelete,
    required this.onRestore,
  });

  final EquipmentListEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archived = entry.item.isArchived;
    final spec = equipmentSpecSummary(entry);
    final note = equipmentNotes(entry.item);
    final identity = Text(
      '${_kindLabel(entry.kind)} · '
      '${_sourceLabel(entry.item.provenance.source)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return Semantics(
      container: true,
      label: '${_kindLabel(entry.kind)} ${entry.item.name}',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppGap.sm),
        child: InkWell(
          // An archived row is deliberately not an edit target: its action menu
          // offers restore, and the overflow still holds the destructive ones.
          onTap: archived ? null : onEdit,
          borderRadius: AppRadius.controlAll,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppGap.md,
              AppGap.md,
              AppGap.sm,
              AppGap.sm,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = <Widget>[
                  _KindBadge(kind: entry.kind),
                  const SizedBox(width: AppGap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.item.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (spec != null) ...<Widget>[
                          const SizedBox(height: AppGap.xs),
                          Text(spec, style: theme.textTheme.bodyMedium),
                        ],
                        const SizedBox(height: AppGap.xs),
                        identity,
                        if (entry.item.provenance.note case final text?) ...[
                          const SizedBox(height: AppGap.xs),
                          Text(text, style: theme.textTheme.bodySmall),
                        ],
                        if (archived) ...<Widget>[
                          const SizedBox(height: AppGap.xs),
                          Text(
                            'Archived',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (note != null) ...<Widget>[
                          const SizedBox(height: AppGap.xs),
                          Text(note, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ];
                // On a phone, or at a large text scale where the labels need
                // the room, the labelled Edit action moves under the details
                // instead of squeezing the name into a column of single words.
                final stacked = constraints.maxWidth < 420;
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[...content, _overflowMenu(archived)],
                      ),
                      if (!archived)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _editButton(),
                        ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ...content,
                    if (!archived) _editButton(),
                    _overflowMenu(archived),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _editButton() => TextButton.icon(
    onPressed: onEdit,
    icon: const Icon(Icons.edit_outlined, size: 18),
    label: const Text('Edit'),
  );

  Widget _overflowMenu(bool archived) => PopupMenuButton<_EquipmentAction>(
    tooltip: 'Actions for ${entry.item.name}',
    onSelected: (action) {
      switch (action) {
        case _EquipmentAction.duplicate:
          onDuplicate();
        case _EquipmentAction.archive:
          onArchive();
        case _EquipmentAction.delete:
          onDelete();
        case _EquipmentAction.restore:
          onRestore();
      }
    },
    itemBuilder: (context) => <PopupMenuEntry<_EquipmentAction>>[
      const PopupMenuItem<_EquipmentAction>(
        value: _EquipmentAction.duplicate,
        child: Text('Duplicate'),
      ),
      if (!archived)
        const PopupMenuItem<_EquipmentAction>(
          value: _EquipmentAction.archive,
          child: Text('Archive'),
        ),
      PopupMenuItem<_EquipmentAction>(
        value: archived ? _EquipmentAction.restore : _EquipmentAction.delete,
        child: Text(archived ? 'Restore' : 'Delete'),
      ),
    ],
  );
}

/// The tinted category badge that leads a row.
class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});

  final EquipmentKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.controlAll,
      ),
      child: Icon(
        _kindIcon(kind),
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

String _kindLabel(EquipmentKind kind) => switch (kind) {
  EquipmentKind.camera => 'Camera',
  EquipmentKind.lens => 'Lens',
  EquipmentKind.filter => 'ND filter',
  EquipmentKind.accessory => 'Optical accessory',
};

String _kindPlural(EquipmentKind kind) => switch (kind) {
  EquipmentKind.camera => 'Cameras',
  EquipmentKind.lens => 'Lenses',
  EquipmentKind.filter => 'ND filters',
  EquipmentKind.accessory => 'Accessories',
};

IconData _kindIcon(EquipmentKind kind) => switch (kind) {
  EquipmentKind.camera => Icons.camera_alt_outlined,
  EquipmentKind.lens => Icons.camera_outlined,
  EquipmentKind.filter => Icons.filter_alt_outlined,
  EquipmentKind.accessory => Icons.extension_outlined,
};

String _sourceLabel(EquipmentSource source) => switch (source) {
  EquipmentSource.user => 'User entered',
  EquipmentSource.bundled => 'Bundled',
  EquipmentSource.userOverride => 'User override',
};
