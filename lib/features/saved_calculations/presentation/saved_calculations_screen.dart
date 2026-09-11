import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/domain/repositories/snapshot_repository.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../planning/domain/planning_time_context.dart';

class SavedCalculationsScreen extends ConsumerWidget {
  const SavedCalculationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(savedSnapshotsProvider)
        .when(
          loading: () => const LoadingSkeleton(
            label: 'Loading saved calculations',
            rowHeight: 84,
            rows: 4,
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
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _calculatorIcon(snapshot.calculatorId),
                        size: 20,
                      ),
                    ),
                    title: Text(snapshot.title),
                    subtitle: Text(
                      '${_calculatorLabel(snapshot.calculatorId)} · ${_date(snapshot.createdAt)}',
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Theme.of(context).colorScheme.outline,
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
                  margin: const EdgeInsets.only(bottom: 8),
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
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            _snapshot.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (_snapshot.notes case final notes?) ...[
            const SizedBox(height: 8),
            Text(notes),
          ],
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${_calculatorLabel(_snapshot.calculatorId)} · saved ${_date(_snapshot.createdAt)}',
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
              const SizedBox(height: 4),
              Text(text, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
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
    final time = inputs['startUtc'] ?? inputs['instantUtc'];
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
            if (time != null) 'Time $time',
            '${_snapshot.displayContext['timeZone'] ?? 'UTC'} · '
                '${_snapshot.displayContext['northReference'] ?? _snapshot.displayContext['azimuthReference'] ?? 'true north'}',
          ].join('\n'),
        ),
      ),
    );
  }

  Widget _actionableChecklist(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
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

  /// The saved plan's headline value, using the same wording as the live
  /// result card, or a plain fallback when a payload predates that key.
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
            azimuth is num
                ? 'Azimuth ${azimuth.toStringAsFixed(0)}° true'
                : null,
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
    return ('Saved result', _calculatorLabel(snapshot.calculatorId), null);
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
                const SizedBox(height: 12),
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

String _calculatorLabel(String id) => switch (id) {
  'depth_of_field' => 'Depth of field',
  'exposure_comparison' => 'Exposure comparison',
  'long_exposure_nd' => 'Long exposure / ND',
  'field_of_view' => 'Field of view',
  'diffraction' => 'Diffraction guidance',
  'focus_stacking' => 'Focus stack planner',
  'flash_exposure' => 'Flash exposure',
  'timelapse' => 'Timelapse planner',
  'macro' => 'Macro planner',
  'panorama' => 'Panorama planner',
  'astronomy' => 'Night-sky planner',
  'sun_moon_alignment' => 'Sun & Moon alignment',
  _ => id,
};
String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
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
  if (zone is String && zone.isNotEmpty) {
    return PlanningTimeContext.parse(zone).format(instant.toUtc());
  }
  final utc = instant.toUtc().toIso8601String();
  return '${utc.substring(0, 10)} ${utc.substring(11, 16)} UTC';
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
class _ExpansionSection extends StatelessWidget {
  const _ExpansionSection({required this.title, required this.entries});

  final String title;
  final Map<String, Object?> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(title),
        children: <Widget>[
          for (final entry in entries.entries)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${entry.key}: ${entry.value}'),
              ),
            ),
        ],
      ),
    );
  }
}
