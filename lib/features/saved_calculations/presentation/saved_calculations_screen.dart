import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/domain/repositories/snapshot_repository.dart';

class SavedCalculationsScreen extends ConsumerWidget {
  const SavedCalculationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(savedSnapshotsProvider)
        .when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading saved calculations',
            ),
          ),
          error: (_, _) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Saved calculations could not be loaded. Your data remains on this device.',
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.bookmark_border, size: 48),
                      SizedBox(height: 12),
                      Text('No saved calculations yet'),
                      SizedBox(height: 8),
                      Text('Calculate a photograph, then choose Save result.'),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => switch (items[index]) {
                SupportedSnapshot(snapshot: final snapshot) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text(snapshot.title),
                    subtitle: Text(
                      '${_calculatorLabel(snapshot.calculatorId)} · ${_date(snapshot.createdAt)}',
                    ),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SavedCalculationDetailScreen(snapshot: snapshot),
                      ),
                    ),
                  ),
                ),
                UnreadableSnapshot(reason: final reason) => Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: const Text('Saved calculation needs recovery'),
                    subtitle: Text(
                      '$reason\nThe original stored data was preserved.',
                    ),
                  ),
                ),
              },
            );
          },
        );
  }
}

class SavedCalculationDetailScreen extends ConsumerStatefulWidget {
  const SavedCalculationDetailScreen({required this.snapshot, super.key});
  final CalculationSnapshot snapshot;

  @override
  ConsumerState<SavedCalculationDetailScreen> createState() =>
      _SavedCalculationDetailScreenState();
}

class _SavedCalculationDetailScreenState
    extends ConsumerState<SavedCalculationDetailScreen> {
  late CalculationSnapshot _snapshot = widget.snapshot;

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
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(_snapshot.title, style: Theme.of(context).textTheme.headlineSmall),
        if (_snapshot.notes case final notes?) ...[
          const SizedBox(height: 8),
          Text(notes),
        ],
        const SizedBox(height: 16),
        _section(context, 'Original inputs', _snapshot.canonicalInputs),
        _section(context, 'Original results', _snapshot.canonicalOutputs),
        _section(context, 'Display context', _snapshot.displayContext),
        if (_snapshot.equipment.isNotEmpty) ...<Widget>[
          Text(
            'Applied equipment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final item in _snapshot.equipment)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('${item.source} · ${_mapText(item.values)}'),
            ),
        ],
        if (_snapshot.assumptions.isNotEmpty) ...<Widget>[
          Text('Assumptions', style: Theme.of(context).textTheme.titleMedium),
          for (final item in _snapshot.assumptions)
            Text('• ${item.key}: ${item.value}'),
        ],
        const SizedBox(height: 16),
        const Text(
          'This saved result is immutable and is not recalculated when equipment or settings change.',
        ),
      ],
    ),
  );

  Widget _section(
    BuildContext context,
    String title,
    Map<String, Object?> values,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in values.entries)
            Text('${entry.key}: ${entry.value}'),
        ],
      ),
    ),
  );

  Future<void> _edit() async {
    final title = TextEditingController(text: _snapshot.title);
    final notes = TextEditingController(text: _snapshot.notes);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit saved calculation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    if (save == true && title.text.trim().isNotEmpty) {
      final newNotes = notes.text.trim().isEmpty ? null : notes.text;
      await ref
          .read(snapshotRepositoryProvider)
          .updateMetadata(_snapshot.id, title: title.text, notes: newNotes);
      if (mounted) {
        setState(
          () => _snapshot = _snapshot.withMetadata(
            title: title.text,
            notes: newNotes,
          ),
        );
      }
    }
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
    if (confirmed == true) {
      await ref.read(snapshotRepositoryProvider).delete(_snapshot.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

String _calculatorLabel(String id) => switch (id) {
  'depth_of_field' => 'Depth of field',
  'exposure_comparison' => 'Exposure comparison',
  'long_exposure_nd' => 'Long exposure / ND',
  _ => id,
};
String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _mapText(Map<String, Object?> values) =>
    values.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ');
