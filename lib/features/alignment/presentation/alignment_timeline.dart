import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../planning/domain/planning_time_context.dart';
import '../domain/alignment_calculator.dart';

class AlignmentTimeline extends StatelessWidget {
  const AlignmentTimeline({
    required this.candidates,
    required this.timeZoneId,
    super.key,
  });

  final List<AlignmentCandidate> candidates;
  final String timeZoneId;

  @override
  Widget build(BuildContext context) {
    final time = PlanningTimeContext.parse(timeZoneId);
    final ordered = [...candidates]
      ..sort((a, b) => a.instantUtc.compareTo(b.instantUtc));
    final groups = <String, List<AlignmentCandidate>>{};
    for (final candidate in ordered) {
      final local = time.localCivilTime(candidate.instantUtc);
      groups
          .putIfAbsent(DateFormat('yyyy-MM-dd').format(local), () => [])
          .add(candidate);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final candidate in entry.value)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: Text(time.format(candidate.instantUtc)),
              subtitle: Text(
                'Az ${candidate.azimuthDegrees.toStringAsFixed(1)}° · alt ${candidate.altitudeDegrees.toStringAsFixed(1)}° · ${candidate.aboveHorizon ? 'above horizon' : 'below horizon'}',
              ),
              trailing: Text(
                '${candidate.angularErrorDegrees.toStringAsFixed(2)}° error',
              ),
            ),
        ],
      ],
    );
  }
}
