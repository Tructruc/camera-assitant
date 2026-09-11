import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../data/device_planning_service.dart';
import '../domain/planning_capabilities.dart';
import '../domain/planning_time_context.dart';
import '../domain/saved_location.dart';

class SavedLocationsScreen extends ConsumerWidget {
  const SavedLocationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(savedLocationsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CalculatorHeader(
          icon: Icons.location_on_outlined,
          description:
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
                          '${_coordinate(location.latitudeDegrees, 'N', 'S')}, '
                          '${_coordinate(location.longitudeDegrees, 'E', 'W')} · '
                          '${location.timeZoneId}',
                        ),
                        // Destructive actions stay one deliberate step away
                        // from a row that is also tapped to edit.
                        trailing: PopupMenuButton<_LocationAction>(
                          tooltip: 'Actions for ${location.name}',
                          onSelected: (action) => switch (action) {
                            _LocationAction.edit => _edit(
                              context,
                              ref,
                              location: location,
                            ),
                            _LocationAction.delete => _delete(
                              context,
                              ref,
                              location,
                            ),
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _LocationAction.edit,
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: _LocationAction.delete,
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                        onTap: () => _edit(context, ref, location: location),
                      ),
                    ),
                ],
          loading: () => [
            const LoadingSkeleton(label: 'Loading saved locations'),
          ],
          error: (_, _) => [const Text('Saved locations could not be loaded.')],
        ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SavedLocation location,
  ) async {
    try {
      await ref.read(savedLocationRepositoryProvider).delete(location.id);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The saved location could not be deleted. It is still stored; try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _fromDevice(BuildContext context, WidgetRef ref) async {
    try {
      // Read the service from the provider so the device path is injectable and
      // consistent with the capability detection that uses the same instance.
      final service = ref.read(devicePlanningServiceProvider);
      // Report the capability state before asking. Checking status does not
      // prompt, so a denied or absent service explains the fallback instead of
      // failing a request the user cannot complete (FR-012, FR-017).
      final status = await service.locationStatus();
      if (!context.mounted) return;
      final blocked = switch (status) {
        CapabilityStatus.unsupported =>
          'Location services are unavailable on this device. Add the coordinates manually.',
        CapabilityStatus.denied =>
          'Location permission is denied for this app. Enable it in system settings, or add the coordinates manually.',
        _ => null,
      };
      if (blocked != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(blocked)));
        return;
      }
      final reading = await service.requestCurrentLocation();
      if (!context.mounted) return;
      await _edit(context, ref, reading: reading);
    } on Object {
      // A raw platform exception is not actionable. Explain the fallback the
      // user still has instead (FR-017).
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Current location is unavailable. Check that location services are on and the permission is granted, or add the coordinates manually.',
            ),
          ),
        );
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
    // Default a new site to the device's real offset instead of UTC, so its
    // local planning times are not silently wrong (FR-013).
    final timezone = TextEditingController(
      text:
          location?.timeZoneId ??
          deviceTimeZoneId(DateTime.now().timeZoneOffset),
    );
    final errors = <String, String>{};
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            location == null ? 'Add saved location' : 'Edit saved location',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: errors['name'],
                  ),
                ),
                TextField(
                  controller: latitude,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    errorText: errors['latitude'],
                  ),
                ),
                TextField(
                  controller: longitude,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    errorText: errors['longitude'],
                  ),
                ),
                TextField(
                  controller: elevation,
                  decoration: InputDecoration(
                    labelText: 'Elevation (m, optional)',
                    errorText: errors['elevation'],
                  ),
                ),
                TextField(
                  controller: timezone,
                  decoration: InputDecoration(
                    labelText: 'Time zone ID',
                    errorText: errors['timeZoneId'],
                  ),
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
              // Ignore repeat taps while the duplicate check is in flight, so a
              // second pop cannot close the screen behind the dialog.
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final found = validateLocationDraft(
                        name: name.text,
                        latitude: latitude.text,
                        longitude: longitude.text,
                        elevation: elevation.text,
                        timeZoneId: timezone.text,
                      );
                      if (found.isEmpty) {
                        // The database enforces unique names, but a raw constraint
                        // error is not actionable; check first and name the field.
                        final existing = await ref
                            .read(savedLocationRepositoryProvider)
                            .listAll();
                        final duplicate = existing.any(
                          (site) =>
                              site.normalizedName ==
                                  name.text.trim().toLowerCase() &&
                              site.id != location?.id,
                        );
                        if (duplicate) {
                          found['name'] =
                              'A saved location with this name exists.';
                        }
                      }
                      if (found.isNotEmpty) {
                        setDialogState(() {
                          saving = false;
                          errors
                            ..clear()
                            ..addAll(found);
                        });
                        return;
                      }
                      if (context.mounted) Navigator.pop(context, true);
                    },
              child: const Text('Save'),
            ),
          ],
        ),
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
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The location could not be saved. Check the values and try again; nothing was changed.',
              ),
            ),
          );
        }
      }
    }
  }
}

/// Field-keyed recovery guidance for a location draft, empty when it is valid.
/// Pure so the rules are unit-testable without a dialog (FR-002).
Map<String, String> validateLocationDraft({
  required String name,
  required String latitude,
  required String longitude,
  required String elevation,
  required String timeZoneId,
}) {
  final errors = <String, String>{};
  if (name.trim().isEmpty) errors['name'] = 'Enter a name.';

  double? number(String text) => double.tryParse(text.trim());
  final parsedLatitude = number(latitude);
  if (parsedLatitude == null || !parsedLatitude.isFinite) {
    errors['latitude'] = 'Enter a number.';
  } else if (parsedLatitude < -90 || parsedLatitude > 90) {
    errors['latitude'] = 'Latitude must be between -90 and 90.';
  }
  final parsedLongitude = number(longitude);
  if (parsedLongitude == null || !parsedLongitude.isFinite) {
    errors['longitude'] = 'Enter a number.';
  } else if (parsedLongitude < -180 || parsedLongitude > 180) {
    errors['longitude'] = 'Longitude must be between -180 and 180.';
  }
  if (elevation.trim().isNotEmpty) {
    final parsedElevation = number(elevation);
    if (parsedElevation == null || !parsedElevation.isFinite) {
      errors['elevation'] = 'Enter a number or leave this blank.';
    }
  }
  if (timeZoneId.trim().isEmpty) {
    errors['timeZoneId'] = 'Enter a time zone ID such as Europe/London or UTC.';
  }
  return errors;
}

/// The deliberate actions behind a saved-location row's overflow menu.
enum _LocationAction { edit, delete }

/// Formats a signed coordinate the way a place is read: `51.48°N, 0.00°E`.
String _coordinate(double value, String positive, String negative) =>
    '${value.abs().toStringAsFixed(2)}°${value < 0 ? negative : positive}';
