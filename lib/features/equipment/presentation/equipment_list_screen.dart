/// Accessible equipment inventory list and recovery states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/equipment.dart';
import 'equipment_controller.dart';
import 'equipment_editor_screen.dart';

class EquipmentListScreen extends ConsumerWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(equipmentControllerProvider);
    final controller = ref.read(equipmentControllerProvider.notifier);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: <Widget>[
                    FilterChip(
                      label: const Text('All'),
                      selected: state.selectedKind == null,
                      onSelected: (_) => controller.setKind(null),
                    ),
                    const SizedBox(width: 8),
                    for (final kind in EquipmentKind.values) ...<Widget>[
                      FilterChip(
                        label: Text(_kindPlural(kind)),
                        selected: state.selectedKind == kind,
                        onSelected: (_) => controller.setKind(kind),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilterChip(
                      label: const Text('Archived'),
                      selected: state.includeArchived,
                      onSelected: controller.setIncludeArchived,
                    ),
                  ],
                ),
              ),
              Expanded(child: _content(state, controller)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  button: true,
                  label: 'Add equipment',
                  child: FilledButton.icon(
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

  Widget _content(EquipmentState state, EquipmentController controller) {
    return switch (state.status) {
      EquipmentLoadStatus.loading => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading equipment'),
      ),
      EquipmentLoadStatus.error => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Equipment could not be loaded.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      EquipmentLoadStatus.ready when state.items.isEmpty => ListView(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 96),
        children: const <Widget>[
          Icon(Icons.camera_alt_outlined, size: 48),
          SizedBox(height: 12),
          Center(child: Text('No equipment yet')),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Add a camera, lens, filter, tube, or converter for faster calculations.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      EquipmentLoadStatus.ready => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: state.items.length,
        itemBuilder: (context, index) => _EquipmentCard(
          entry: state.items[index],
          onArchive: () => controller.archive(state.items[index]),
          onRestore: () => controller.restore(state.items[index]),
        ),
      ),
    };
  }

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
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.entry,
    required this.onArchive,
    required this.onRestore,
  });

  final EquipmentListEntry entry;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final archived = entry.item.isArchived;
    return Semantics(
      container: true,
      label: '${_kindLabel(entry.kind)} ${entry.item.name}',
      child: Card(
        child: ListTile(
          leading: Icon(_kindIcon(entry.kind)),
          title: Text(entry.item.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${_kindLabel(entry.kind)} · '
                '${_sourceLabel(entry.item.provenance.source)}',
              ),
              if (entry.item.provenance.note case final note?) Text(note),
              if (archived) const Text('Archived'),
            ],
          ),
          trailing: IconButton(
            tooltip: archived
                ? 'Restore ${entry.item.name}'
                : 'Archive ${entry.item.name}',
            onPressed: archived ? onRestore : onArchive,
            icon: Icon(archived ? Icons.restore : Icons.archive_outlined),
          ),
        ),
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
