import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/domain/repositories/snapshot_repository.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../planning/domain/planning_time_context.dart';
import 'saved_calculation_export.dart';

/// The saved workspace: everything already calculated, searchable by title,
/// tool or note, with the tool filter and the dates it was saved on visible.
class SavedCalculationsScreen extends ConsumerStatefulWidget {
  const SavedCalculationsScreen({super.key});

  @override
  ConsumerState<SavedCalculationsScreen> createState() =>
      _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState
    extends ConsumerState<SavedCalculationsScreen> {
  final _search = TextEditingController();

  /// The chosen calculator id, or null for every tool.
  String? _calculator;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(savedSnapshotsProvider)
        .when(
          // Directly laid out, not through _scrollable: the skeleton measures
          // itself against the space it is given, and a sliver would ask it for
          // an intrinsic height that a builder cannot answer.
          loading: () => const LoadingSkeleton(
            label: 'Loading saved calculations',
            rowHeight: 84,
            rows: 4,
          ),
          error: (_, _) => _scrollable(
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppGap.xl),
                child: Text(
                  'Saved calculations could not be loaded. Your data remains on this device.',
                ),
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _scrollable(
                const EmptyState(
                  icon: Icons.bookmark_border,
                  title: 'No saved calculations yet',
                  description:
                      'Calculate a photograph, then choose Save result.',
                ),
              );
            }
            return _library(context, items);
          },
        );
  }

  /// A message or empty state that scrolls rather than overflowing when the
  /// system text scale is at its largest.
  Widget _scrollable(Widget child) => CustomScrollView(
    slivers: <Widget>[SliverFillRemaining(hasScrollBody: false, child: child)],
  );

  Widget _library(
    BuildContext context,
    List<SnapshotReadResult<CalculationSnapshot>> items,
  ) {
    final supported = <CalculationSnapshot>[
      for (final item in items)
        if (item is SupportedSnapshot<CalculationSnapshot>) item.snapshot,
    ];
    // A record whose payload cannot be read is preserved, not filtered away:
    // recovery has to stay reachable whatever the search says.
    final unreadable = <UnreadableSnapshot<CalculationSnapshot>>[
      for (final item in items)
        if (item is UnreadableSnapshot<CalculationSnapshot>) item,
    ];
    final tools = <String>{
      for (final snapshot in supported) snapshot.calculatorId,
    };
    final sortedTools = tools.toList()
      ..sort(
        (left, right) => savedCalculationToolLabel(
          left,
        ).compareTo(savedCalculationToolLabel(right)),
      );
    // A filter left pointing at a tool that no longer has saved rows is
    // dropped, so a deleted result can never leave the workspace stuck.
    final activeTool = tools.contains(_calculator) ? _calculator : null;
    final matches = <CalculationSnapshot>[
      for (final snapshot in supported)
        if (_matches(snapshot, activeTool)) snapshot,
    ];

    final rows = <Widget>[
      _LibraryHeader(
        search: _search,
        // A filter with a single option is noise; it appears once the library
        // actually holds more than one kind of result.
        tools: sortedTools.length > 1 ? sortedTools : const <String>[],
        counts: <String, int>{
          for (final tool in tools)
            tool: supported.where((s) => s.calculatorId == tool).length,
        },
        selected: activeTool,
        onSelected: (tool) => setState(() => _calculator = tool),
        onQueryChanged: () => setState(() {}),
        onClear: _clearFilters,
      ),
    ];

    if (matches.isEmpty && unreadable.isEmpty) {
      rows.add(_NoMatches(onClear: _clearFilters));
    } else {
      DateTime? group;
      for (final snapshot in matches) {
        final day = DateTime.utc(
          snapshot.createdAt.year,
          snapshot.createdAt.month,
          snapshot.createdAt.day,
        );
        if (group != day) {
          group = day;
          rows.add(_DateHeader(label: _dateGroupLabel(day)));
        }
        rows.add(
          _SavedResultCard(
            snapshot: snapshot,
            onOpen: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SavedCalculationDetailScreen(snapshot: snapshot),
              ),
            ),
          ),
        );
      }
      if (unreadable.isNotEmpty) {
        rows.add(const _DateHeader(label: 'Needs recovery'));
        for (final item in unreadable) {
          rows.add(_RecoveryCard(item: item));
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppGap.lg,
        AppGap.md,
        AppGap.lg,
        AppGap.xl,
      ),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index],
    );
  }

  bool _matches(CalculationSnapshot snapshot, String? tool) {
    if (tool != null && snapshot.calculatorId != tool) {
      return false;
    }
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return snapshot.title.toLowerCase().contains(query) ||
        savedCalculationToolLabel(
          snapshot.calculatorId,
        ).toLowerCase().contains(query) ||
        (snapshot.notes ?? '').toLowerCase().contains(query);
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _calculator = null);
  }
}

/// Search and the visible tool filter, above the rows they narrow.
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.search,
    required this.tools,
    required this.counts,
    required this.selected,
    required this.onSelected,
    required this.onQueryChanged,
    required this.onClear,
  });

  final TextEditingController search;
  final List<String> tools;
  final Map<String, int> counts;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final VoidCallback onQueryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: search,
          onChanged: (_) => onQueryChanged(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Search saved results',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 20),
                  ),
          ),
        ),
        if (tools.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppGap.md),
          _toolFilter(),
        ],
        const SizedBox(height: AppGap.sm),
      ],
    );
  }

  /// The visible tool filter, with its counts, above the rows it narrows.
  ///
  /// A library holding a few tools wraps, so every choice is visible without a
  /// gesture. Once many tools are stored - a full catalog is a dozen and more -
  /// wrapping becomes a wall of chips that pushes the results off screen, so the
  /// same choices move to the app's standard sideways rail. Nothing is dropped
  /// either way: every chip keeps its label, its count and its 48dp target.
  Widget _toolFilter() {
    final chips = <Widget>[
      ChoiceChip(
        label: const Text('All tools'),
        selected: selected == null,
        onSelected: (_) => onSelected(null),
      ),
      for (final tool in tools)
        ChoiceChip(
          label: Text(
            '${savedCalculationToolLabel(tool)} (${counts[tool] ?? 0})',
          ),
          selected: selected == tool,
          onSelected: (_) => onSelected(tool),
        ),
    ];
    if (tools.length > _wrappedToolLimit) {
      return CalculatorChipRail(
        semanticsLabel: 'Filter saved results by tool',
        children: chips,
      );
    }
    return Wrap(spacing: AppGap.sm, runSpacing: AppGap.xs, children: chips);
  }
}

/// A date, so a long library reads as a timeline instead of a wall of rows.
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppGap.md, bottom: AppGap.xs),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SavedResultCard extends StatelessWidget {
  const _SavedResultCard({required this.snapshot, required this.onOpen});

  final CalculationSnapshot snapshot;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, value, _) = _heroFor(snapshot);
    final summary = label == 'Saved result' ? null : '$label: $value';
    final notes = snapshot.notes;
    return Card(
      margin: const EdgeInsets.only(bottom: AppGap.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppGap.md,
          vertical: AppGap.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: AppRadius.controlAll,
          ),
          child: Icon(_calculatorIcon(snapshot.calculatorId), size: 20),
        ),
        title: Text(snapshot.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${savedCalculationToolLabel(snapshot.calculatorId)} · '
              '${_date(snapshot.createdAt)}',
            ),
            if (summary != null) Text(summary),
            if (notes != null && notes.trim().isNotEmpty)
              Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: theme.colorScheme.outline,
        ),
        onTap: onOpen,
      ),
    );
  }
}

/// A preserved payload that needs recovery, never hidden by a filter.
///
/// The only action offered is an explicit delete, after a confirmation that
/// names the raw preserved payload. Nothing here fabricates a recovery or an
/// export, and the reason and preservation notice stay on the card until the
/// deletion is confirmed.
class _RecoveryCard extends ConsumerWidget {
  const _RecoveryCard({required this.item});

  final UnreadableSnapshot<CalculationSnapshot> item;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final id = item.id;
    // A record with no stored id cannot be deleted; the card stays informative
    // instead of offering a control that would do nothing.
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete unreadable saved record?'),
        content: Text(
          '${item.reason}\n\n'
          'The raw preserved record will be deleted. It cannot be recovered '
          'or exported afterwards.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(snapshotRepositoryProvider).delete(id);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The unreadable record could not be deleted. It is still stored; try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: AppGap.sm),
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.warning_amber),
      title: const Text('Saved calculation needs recovery'),
      subtitle: Text('${item.reason}\nThe original stored data was preserved.'),
      trailing: item.id == null
          ? null
          : IconButton(
              tooltip: 'Delete this unreadable record',
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
    ),
  );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppGap.xl),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppGap.md),
          Text(
            'No saved results match this search',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppGap.xs),
          Text(
            'Titles, tool names and notes are searched.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppGap.md),
          OutlinedButton(
            onPressed: onClear,
            child: const Text('Clear search and filters'),
          ),
        ],
      ),
    );
  }
}

class SavedCalculationDetailScreen extends ConsumerStatefulWidget {
  const SavedCalculationDetailScreen({
    required this.snapshot,
    this.copyText,
    super.key,
  });

  final CalculationSnapshot snapshot;

  /// Writes [text] to the platform clipboard.
  ///
  /// Production leaves this null and the widget uses `Clipboard.setData`, which
  /// needs no permission and no package. Widget tests inject a recorder here so
  /// no test ever writes the machine's real clipboard, and can make the write
  /// fail to prove the failure is reported honestly.
  final Future<void> Function(String text)? copyText;

  @override
  ConsumerState<SavedCalculationDetailScreen> createState() =>
      _SavedCalculationDetailScreenState();
}

class _SavedCalculationDetailScreenState
    extends ConsumerState<SavedCalculationDetailScreen> {
  /// Shown beside both copy actions and as their tooltip: a brief and a JSON
  /// copy are text, and a saved plan can carry a photographer's own words and a
  /// site's coordinates.
  static const String _copyPrivacy =
      'Saved plans can include site coordinates and your notes.';

  /// Input keys the observation block below already prints, so the brief does
  /// not repeat a site or an instant twice.
  static const Set<String> _observationInputKeys = <String>{
    'latitudeDegrees',
    'longitudeDegrees',
    'observerLatitudeDegrees',
    'observerLongitudeDegrees',
    'observerElevationMetres',
    'instantUtc',
    'startUtc',
    'endUtc',
    'startLocalDate',
    'endLocalDate',
  };

  late CalculationSnapshot _snapshot = widget.snapshot;
  late final Map<String, bool> _fieldChecklist = _readChecklist();

  bool get _isObservationPlan =>
      _snapshot.calculatorId == 'astronomy' ||
      _snapshot.calculatorId == 'sun_moon_alignment';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Saved calculation'),
      actions: <Widget>[
        IconButton(
          onPressed: _edit,
          tooltip: 'Edit title and notes',
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: _delete,
          tooltip: 'Delete saved calculation',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: AppContentFrame(
      child: ListView(
        padding: const EdgeInsets.all(AppGap.lg),
        children: <Widget>[
          Text(
            _snapshot.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (_snapshot.notes case final notes?) ...[
            const SizedBox(height: AppGap.sm),
            Text(notes),
          ],
          const SizedBox(height: AppGap.lg),
          _summaryCard(context),
          if (_isObservationPlan) _planSummary(context),
          if (_fieldChecklist.isNotEmpty) _actionableChecklist(context),
          // The stored provenance stays complete but stops competing with the
          // answer: each block opens only when a photographer asks for it.
          _ExpansionSection(
            title: 'Values used',
            entries: _snapshot.canonicalInputs,
          ),
          _ExpansionSection(
            title: 'Exact values',
            entries: Map<String, Object?>.of(_snapshot.canonicalOutputs)
              ..remove('fieldChecklist'),
            action: _exactJsonCopy(context),
          ),
          if (_snapshot.displayContext.isNotEmpty)
            _ExpansionSection(
              title: 'Display context',
              entries: _snapshot.displayContext,
            ),
          if (_snapshot.equipment.isNotEmpty)
            _ExpansionSection(
              title: 'Applied equipment',
              entries: <String, Object?>{
                for (final item in _snapshot.equipment)
                  item.name: '${item.source} · ${_mapText(item.values)}',
              },
            ),
          if (_snapshot.assumptions.isNotEmpty)
            _ExpansionSection(
              title: 'Model assumptions',
              entries: <String, Object?>{
                for (final item in _snapshot.assumptions) item.key: item.value,
              },
            ),
          const SizedBox(height: AppGap.lg),
          const Text(
            'This saved result is immutable and is not recalculated when equipment or settings change.',
          ),
        ],
      ),
    ),
  );

  /// The one answer this saved result exists to carry, in the same wording the
  /// live screen uses, with its warnings kept visible above it.
  Widget _summaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final (label, value, caption) = _heroFor(_snapshot);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppGap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${savedCalculationToolLabel(_snapshot.calculatorId)} · saved ${_date(_snapshot.createdAt)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_snapshot.warnings.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              _warningsBanner(context),
            ],
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (caption case final text?) ...<Widget>[
              const SizedBox(height: AppGap.xs),
              Text(text, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppGap.md),
            // The shareable form of this plan sits with the answer it carries,
            // not behind the exact-value disclosure: a photographer passing a
            // setup on should not have to open the raw payload first.
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: 'Copies a plain-text field brief. $_copyPrivacy',
                child: FilledButton.tonalIcon(
                  onPressed: _copyBrief,
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: const Text('Copy field brief'),
                ),
              ),
            ),
            const SizedBox(height: AppGap.xs),
            Text(
              _copyPrivacy,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The secondary copy action: the whole stored record, offered inside the
  /// exact-value disclosure it duplicates.
  Widget _exactJsonCopy(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Tooltip(
            message:
                'Copies the whole stored record as JSON text. $_copyPrivacy',
            child: OutlinedButton.icon(
              onPressed: _copyExactJson,
              icon: const Icon(Icons.data_object, size: 18),
              label: const Text('Copy exact JSON'),
            ),
          ),
          const SizedBox(height: AppGap.xs),
          Text(
            'Every stored value, id and version, exactly as saved.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Copies the readable brief.
  ///
  /// No confirmation is asked for a user-initiated copy: nothing is destroyed
  /// and the clipboard is replaced on the next copy.
  Future<void> _copyBrief() => _copyText(
    buildSavedCalculationBrief(_briefInput()),
    success: 'Field brief copied to the clipboard.',
    failure:
        'The field brief could not be copied. Nothing was written to the clipboard.',
  );

  /// Copies the record exactly as stored, so no canonical value is lost.
  ///
  /// The snapshot's own [CalculationSnapshot.toJson] is the source: the ticks a
  /// photographer makes on the on-screen checklist while reading are session
  /// state and are never part of it.
  Future<void> _copyExactJson() => _copyText(
    buildSavedCalculationExactJson(_snapshot),
    success: 'Exact JSON copied to the clipboard.',
    failure:
        'The exact JSON could not be copied. Nothing was written to the clipboard.',
  );

  /// Writes [text] and reports the outcome only after the platform answered.
  Future<void> _copyText(
    String text, {
    required String success,
    required String failure,
  }) async {
    try {
      await _writeClipboard(text);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success)));
  }

  Future<void> _writeClipboard(String text) async {
    final write = widget.copyText;
    if (write != null) {
      await write(text);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// The presentation strings the pure brief builder prints.
  ///
  /// The hero answer, the warning sentences and the zone wording are the ones
  /// the saved screen already shows, so a brief never restates the physics
  /// differently; the equipment is the record's own applied snapshot, not
  /// whatever the kit holds now.
  SavedCalculationBriefInput _briefInput() {
    final (label, value, caption) = _heroFor(_snapshot);
    return SavedCalculationBriefInput(
      title: _snapshot.title,
      toolLabel: savedCalculationToolLabel(_snapshot.calculatorId),
      savedDate: _date(_snapshot.createdAt),
      primaryLabel: label,
      primaryValue: value,
      primaryCaption: caption,
      notes: _snapshot.notes,
      recordedInputs: savedCalculationRecordedValues(
        _snapshot.canonicalInputs,
        skip: _isObservationPlan ? _observationInputKeys : const <String>{},
      ),
      warnings: <String>[
        for (final warning in _snapshot.warnings)
          calculationWarningText(warning.code),
      ],
      assumptions: <String>[
        for (final item in _snapshot.assumptions) '${item.key}: ${item.value}',
      ],
      observation: _isObservationPlan ? _observationBrief() : null,
      equipment: <String>[
        for (final item in _snapshot.equipment) _equipmentBrief(item),
      ],
    );
  }

  SavedCalculationObservationBrief _observationBrief() {
    final display = _snapshot.displayContext;
    final zone = display['timeZone'];
    final reference = display['northReference'] ?? display['azimuthReference'];
    return SavedCalculationObservationBrief(
      site: _observationSite(),
      time: _plannedTimeLabel(_snapshot.canonicalInputs),
      // The plan's own zone, and `UTC` when it recorded none: the brief never
      // borrows today's global preference for a plan saved in another place.
      zone: zone is String && zone.trim().isNotEmpty ? zone : 'UTC',
      reference: reference is String && reference.trim().isNotEmpty
          ? reference
          : null,
    );
  }

  String _observationSite() {
    final inputs = _snapshot.canonicalInputs;
    final display = _snapshot.displayContext;
    final latitude =
        inputs['observerLatitudeDegrees'] ?? inputs['latitudeDegrees'];
    final longitude =
        inputs['observerLongitudeDegrees'] ?? inputs['longitudeDegrees'];
    final elevation = inputs['observerElevationMetres'];
    final coordinates = latitude == null || longitude == null
        ? null
        : '$latitude, $longitude';
    final label = display['locationLabel'];
    final source = display['locationSource'];
    final parts = <String>[
      ?coordinates,
      if (elevation is num)
        'elevation ${savedCalculationValueText(elevation)} m',
      // A manual location's label is the coordinates again; naming them twice
      // would bury the provenance that is the useful part.
      if (label is String && label.trim().isNotEmpty && label != coordinates)
        label,
      if (source is String && source.trim().isNotEmpty) source,
    ];
    return parts.isEmpty ? 'Not recorded' : parts.join(' · ');
  }

  String _equipmentBrief(AppliedEquipmentSnapshot item) {
    final values = savedCalculationRecordedValues(item.values);
    final identity = '${item.name} (${item.type.name}) · ${item.source}';
    if (values.isEmpty) return identity;
    return '$identity\n  ${values.join(', ')}';
  }

  Widget _warningsBanner(BuildContext context) {
    final theme = Theme.of(context);
    final warnings = <String>[
      for (final item in _snapshot.warnings) calculationWarningText(item.code),
    ];
    return Semantics(
      container: true,
      label: 'Warnings: ${warnings.join('; ')}',
      child: Container(
        padding: const EdgeInsets.all(AppGap.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: AppRadius.controlAll,
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
                  Text(
                    'Warnings',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
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

  Widget _planSummary(BuildContext context) {
    final inputs = _snapshot.canonicalInputs;
    final latitude =
        inputs['observerLatitudeDegrees'] ?? inputs['latitudeDegrees'];
    final longitude =
        inputs['observerLongitudeDegrees'] ?? inputs['longitudeDegrees'];
    final elevation = inputs['observerElevationMetres'];
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: const Text('Offline observation plan'),
        subtitle: Text(
          <String>[
            'Location $latitude, $longitude'
                '${elevation == null ? '' : ' · elevation $elevation m'}',
            // Legacy payloads can omit the instant; never print "Time null".
            if (_plannedTimeLabel(inputs) case final time?) 'Time $time',
            '${_snapshot.displayContext['timeZone'] ?? 'UTC'} · '
                '${_snapshot.displayContext['northReference'] ?? _snapshot.displayContext['azimuthReference'] ?? 'true north'}',
          ].join('\n'),
        ),
      ),
    );
  }

  /// Prints the stored instants the way the planner that saved them did: local
  /// time in the plan's own zone, and the whole window when the snapshot
  /// carries one, so a multi-day search does not read as a single moment. The
  /// canonical UTC values stay in "Values used" for provenance.
  String? _plannedTimeLabel(Map<String, Object?> inputs) {
    final stored = inputs['startUtc'] ?? inputs['instantUtc'];
    if (stored is! String) return null;
    final start = _formatInstant(_snapshot, stored);
    // An unparseable payload is still shown, rather than hidden.
    if (start == null) return stored;
    final endRaw = inputs['endUtc'];
    final end = endRaw is String ? _formatInstant(_snapshot, endRaw) : null;
    if (end == null) return start;
    // A window names its zone once: both ends are formatted from this plan, so
    // the trailing zone label is the same on each.
    final zone = _trailingZone(start);
    return '${start.substring(0, start.length - zone.length)} to $end';
  }

  /// The trailing `' Zone'` token [PlanningTimeContext.format] appends, or `''`.
  static String _trailingZone(String formatted) {
    final boundary = formatted.lastIndexOf(' ');
    return boundary <= 0 ? '' : formatted.substring(boundary);
  }

  Widget _actionableChecklist(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppGap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field checklist',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'Session progress is temporary; the original saved snapshot remains immutable.',
          ),
          for (final entry in _fieldChecklist.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(entry.key),
              value: entry.value,
              onChanged: (value) =>
                  setState(() => _fieldChecklist[entry.key] = value ?? false),
            ),
        ],
      ),
    ),
  );

  Map<String, bool> _readChecklist() {
    final raw = _snapshot.canonicalOutputs['fieldChecklist'];
    if (raw is! List<Object?>) return {};
    return {
      for (final item in raw)
        if (item is Map<Object?, Object?> && item['task'] is String)
          item['task']! as String: item['complete'] == true,
    };
  }

  Future<void> _edit() async {
    final title = TextEditingController(text: _snapshot.title);
    final notes = TextEditingController(text: _snapshot.notes);
    final titleError = <String?>[null];
    var saveError = '';
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit saved calculation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                decoration: InputDecoration(
                  labelText: 'Title',
                  errorText: titleError.first,
                ),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              if (saveError.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppGap.md),
                Text(
                  saveError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty) {
                        setDialogState(() => titleError[0] = 'Enter a title.');
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        saveError = '';
                        titleError[0] = null;
                      });
                      final newNotes = notes.text.trim().isEmpty
                          ? null
                          : notes.text;
                      try {
                        await ref
                            .read(snapshotRepositoryProvider)
                            .updateMetadata(
                              _snapshot.id,
                              title: title.text,
                              notes: newNotes,
                            );
                      } on Object {
                        if (!context.mounted) return;
                        setDialogState(() {
                          saving = false;
                          saveError =
                              'The title and notes could not be saved. Your changes are still here; try again.';
                        });
                        return;
                      }
                      if (!mounted || !context.mounted) return;
                      setState(
                        () => _snapshot = _snapshot.withMetadata(
                          title: title.text,
                          notes: newNotes,
                        ),
                      );
                      Navigator.pop(context);
                    },
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved calculation?'),
        content: const Text('This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(snapshotRepositoryProvider).delete(_snapshot.id);
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The saved result could not be deleted. It is still stored; try again.',
            ),
          ),
        );
      }
    }
  }
}

/// The saved plan's headline value, using the same wording as the live result
/// card, or a plain fallback when a payload predates that key.
(String, String, String?) _heroFor(CalculationSnapshot snapshot) {
  final outputs = snapshot.canonicalOutputs;
  final inputs = snapshot.canonicalInputs;
  final display = _storedLengthDisplay(snapshot);
  String length(Object? value) =>
      value is num ? formatDisplayLength(value.toDouble(), display) : '—';

  switch (snapshot.calculatorId) {
    case 'depth_of_field':
      if (outputs['hyperfocalDistanceMm'] is num) {
        final near = outputs['nearLimitMm'];
        final far = outputs['farLimitMm'];
        return (
          'Hyperfocal distance',
          length(outputs['hyperfocalDistanceMm']),
          near is num && far is num
              ? 'Sharp from ${length(near)} to ${length(far)}.'
              : null,
        );
      }
      if (outputs['nearLimitMm'] is num) {
        return ('Near limit', length(outputs['nearLimitMm']), null);
      }
    case 'long_exposure_nd':
      final seconds = outputs['filteredTimeSeconds'];
      if (seconds is num) {
        final base = inputs['baseTimeSeconds'];
        return (
          'Filtered exposure time',
          _humanDuration(seconds.toDouble()),
          base is num ? 'Base ${_humanDuration(base.toDouble())}' : null,
        );
      }
    case 'flash_exposure':
      final aperture = outputs['recommendedAperture'];
      if (aperture is num) {
        final distance = inputs['subjectDistanceMetres'];
        return (
          'Recommended aperture',
          'f/${aperture.toStringAsFixed(1)}',
          distance is num ? 'At ${length(distance * 1000)}' : null,
        );
      }
    case 'field_of_view':
      final width = outputs['sceneWidthMm'];
      if (width is num) {
        final height = outputs['sceneHeightMm'];
        return (
          'Scene width at this distance',
          length(width),
          height is num ? 'Scene height ${length(height)}.' : null,
        );
      }
    case 'diffraction':
      final pixels = outputs['airyDiskPixels'];
      if (pixels is num) {
        final micrometres = outputs['airyDiskMicrometres'];
        return (
          'Airy disk on the sensor',
          '${pixels.toStringAsFixed(2)} pixels',
          micrometres is num
              ? '${micrometres.toStringAsFixed(2)} µm across'
              : null,
        );
      }
    case 'macro':
      final subject = outputs['subjectWidthMm'];
      if (subject is num) {
        final magnification = outputs['magnification'];
        return (
          'Subject width across frame',
          length(subject),
          magnification is num
              ? 'At ${magnification.toStringAsFixed(2)}× magnification.'
              : null,
        );
      }
    case 'timelapse':
    case 'focus_stacking':
    case 'panorama':
      final frames = outputs['frameCount'];
      if (frames is num) {
        final playback = outputs['playbackDurationSeconds'];
        final columns = outputs['columns'];
        final rows = outputs['rows'];
        return (
          snapshot.calculatorId == 'timelapse' ? 'Frames' : 'Frames to shoot',
          '${frames.round()}',
          playback is num
              ? 'Playback ${_humanDuration(playback.toDouble())}'
              : columns is num && rows is num
              ? '${columns.round()} columns × ${rows.round()} rows'
              : null,
        );
      }
    case 'exposure_comparison':
      final stops = outputs['totalDifferenceStops'];
      if (stops is num) {
        final value = stops.toDouble();
        final direction = outputs['direction'];
        return (
          'Total difference',
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} stops',
          direction is String ? 'Candidate is $direction' : null,
        );
      }
    case 'astronomy':
      final altitude = outputs['altitudeDegrees'];
      if (altitude is num) {
        final azimuth = outputs['azimuthDegrees'];
        return (
          'Target altitude',
          '${altitude.toStringAsFixed(0)}° '
              '${outputs['aboveHorizon'] == true ? 'above' : 'below'} the horizon',
          azimuth is num ? 'Azimuth ${azimuth.toStringAsFixed(0)}° true' : null,
        );
      }
    case 'sun_moon_alignment':
      final candidates = outputs['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final first = candidates.first;
        final instant = first is Map ? first['instantUtc'] : null;
        final formatted = instant is String
            ? _formatInstant(snapshot, instant)
            : null;
        if (formatted != null) {
          // The hero is the clock time; date, zone and the match count read
          // better as one caption line than as a wrapped headline.
          final parts = formatted.split(' ');
          final zone = snapshot.displayContext['timeZone'];
          return (
            'Best window',
            parts.length > 1 ? parts[1] : formatted,
            <String>[
              if (parts.isNotEmpty) parts.first,
              if (zone is String && zone.isNotEmpty) zone,
              '${candidates.length} matching '
                  'window${candidates.length == 1 ? '' : 's'}',
            ].join(' · '),
          );
        }
      }
      final altitude = outputs['desiredAltitudeDegrees'];
      if (altitude is num) {
        return ('Target altitude', '${altitude.toStringAsFixed(0)}°', null);
      }
  }
  return (
    'Saved result',
    savedCalculationToolLabel(snapshot.calculatorId),
    null,
  );
}

IconData _calculatorIcon(String id) => switch (id) {
  'depth_of_field' => Icons.center_focus_strong_outlined,
  'exposure_comparison' => Icons.exposure_outlined,
  'long_exposure_nd' => Icons.timer_outlined,
  'field_of_view' => Icons.aspect_ratio_outlined,
  'diffraction' => Icons.blur_circular_outlined,
  'focus_stacking' => Icons.layers_outlined,
  'flash_exposure' => Icons.flash_on_outlined,
  'timelapse' => Icons.movie_creation_outlined,
  'macro' => Icons.local_florist_outlined,
  'panorama' => Icons.panorama_horizontal_outlined,
  'astronomy' => Icons.nightlight_round,
  'sun_moon_alignment' => Icons.align_horizontal_left,
  _ => Icons.bookmark_outline,
};

/// How many stored tools may wrap onto several rows before the tool filter
/// moves to the app's standard sideways chip rail.
const int _wrappedToolLimit = 4;

/// The saved date a card and a brief both print.
String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

/// A saved date reads as a heading: today and yesterday in words, and the
/// stored calendar day otherwise.
String _dateGroupLabel(DateTime day) {
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return _date(day);
}

String _mapText(Map<String, Object?> values) =>
    values.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ');

/// The unit the result was saved in, so a reopened plan keeps the display it
/// was created with instead of silently switching to today's preference.
LengthDisplay _storedLengthDisplay(CalculationSnapshot snapshot) {
  final stored =
      snapshot.displayContext['distanceUnit'] ??
      snapshot.displayContext['lengthUnit'];
  return stored == LengthDisplay.imperial.name
      ? LengthDisplay.imperial
      : LengthDisplay.metric;
}

/// A saved instant rendered in the plan's own zone when one was recorded.
String? _formatInstant(CalculationSnapshot snapshot, String iso) {
  final instant = DateTime.tryParse(iso);
  if (instant == null) return null;
  final zone = snapshot.displayContext['timeZone'];
  // PlanningTimeContext labels the printed time honestly: the recorded zone
  // when it resolves offline, and `UTC` when it does not, so a plan never shows
  // a UTC clock under the name of a zone that was not applied.
  return PlanningTimeContext.parse(
    zone is String && zone.trim().isNotEmpty ? zone : 'UTC',
  ).format(instant.toUtc());
}

/// A duration a photographer reads at a glance, e.g. `4 min 16 s`.
String _humanDuration(double seconds) {
  if (!seconds.isFinite || seconds <= 0) return '—';
  if (seconds < 10) return '${seconds.toStringAsFixed(1)} s';
  if (seconds < 60) return '${seconds.toStringAsFixed(0)} s';
  if (seconds < 3600) {
    final minutes = seconds ~/ 60;
    final remainder = (seconds - minutes * 60).round();
    return remainder == 0 ? '$minutes min' : '$minutes min $remainder s';
  }
  final hours = seconds ~/ 3600;
  final minutes = ((seconds - hours * 3600) / 60).round();
  return minutes == 0 ? '$hours h' : '$hours h $minutes min';
}

/// One collapsed block of stored provenance.
///
/// [action] is an optional control that belongs to this block - the exact-value
/// block offers its JSON copy here - and is placed inside the disclosure, above
/// the rows it duplicates, so the raw payload still leads.
class _ExpansionSection extends StatelessWidget {
  const _ExpansionSection({
    required this.title,
    required this.entries,
    this.action,
  });

  final String title;
  final Map<String, Object?> entries;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty && action == null) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppGap.sm),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(title),
        children: <Widget>[
          if (action case final widget?) ...<Widget>[
            widget,
            const SizedBox(height: AppGap.sm),
          ],
          for (final entry in entries.entries)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppGap.xs),
                child: Text('${entry.key}: ${entry.value}'),
              ),
            ),
        ],
      ),
    );
  }
}
