import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../data/device_planning_service.dart';
import '../domain/saved_location.dart';

class SavedLocationsScreen extends ConsumerWidget {
  const SavedLocationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(savedLocationsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Saved locations',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Coordinates stay on this device and remain available offline.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _edit(context, ref),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Add location'),
        ),
        OutlinedButton.icon(
          onPressed: () => _fromDevice(context, ref),
          icon: const Icon(Icons.my_location),
          label: const Text('Use current location'),
        ),
        ...locations.when(
          data: (items) => items.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      'No saved locations yet. Add coordinates manually or request the current position.',
                    ),
                  ),
                ]
              : [
                  for (final location in items)
                    Card(
                      child: ListTile(
                        title: Text(location.name),
                        subtitle: Text(
                          '${location.latitudeDegrees.toStringAsFixed(5)}, ${location.longitudeDegrees.toStringAsFixed(5)} • ${location.timeZoneId}${location.accuracyMetres == null ? '' : ' • ±${location.accuracyMetres!.round()} m'}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete ${location.name}',
                          onPressed: () => ref
                              .read(savedLocationRepositoryProvider)
                              .delete(location.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        onTap: () => _edit(context, ref, location: location),
                      ),
                    ),
                ],
          loading: () => [const Center(child: CircularProgressIndicator())],
          error: (_, _) => [const Text('Saved locations could not be loaded.')],
        ),
      ],
    );
  }

  Future<void> _fromDevice(BuildContext context, WidgetRef ref) async {
    try {
      final reading = await const DevicePlanningService()
          .requestCurrentLocation();
      if (!context.mounted) return;
      await _edit(context, ref, reading: reading);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    SavedLocation? location,
    DeviceLocationReading? reading,
  }) async {
    final name = TextEditingController(
      text: location?.name ?? (reading == null ? '' : 'Current location'),
    );
    final latitude = TextEditingController(
      text: (location?.latitudeDegrees ?? reading?.latitude)?.toString() ?? '',
    );
    final longitude = TextEditingController(
      text:
          (location?.longitudeDegrees ?? reading?.longitude)?.toString() ?? '',
    );
    final elevation = TextEditingController(
      text:
          (location?.elevationMetres ?? reading?.elevationMetres)?.toString() ??
          '',
    );
    final timezone = TextEditingController(text: location?.timeZoneId ?? 'UTC');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          location == null ? 'Add saved location' : 'Edit saved location',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: latitude,
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: longitude,
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              TextField(
                controller: elevation,
                decoration: const InputDecoration(
                  labelText: 'Elevation (m, optional)',
                ),
              ),
              TextField(
                controller: timezone,
                decoration: const InputDecoration(labelText: 'Time zone ID'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        final now = DateTime.now().toUtc();
        await ref
            .read(savedLocationRepositoryProvider)
            .save(
              SavedLocation(
                id: location?.id ?? const Uuid().v4(),
                name: name.text,
                latitudeDegrees: double.parse(latitude.text),
                longitudeDegrees: double.parse(longitude.text),
                elevationMetres: elevation.text.trim().isEmpty
                    ? null
                    : double.parse(elevation.text),
                timeZoneId: timezone.text,
                source: reading == null
                    ? LocationSource.manual
                    : LocationSource.device,
                accuracyMetres:
                    reading?.accuracyMetres ?? location?.accuracyMetres,
                createdAt: location?.createdAt ?? now,
                updatedAt: now,
              ),
            );
      } on Object catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Location not saved: $error')));
        }
      }
    }
  }
}
