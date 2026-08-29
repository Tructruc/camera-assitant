import 'package:flutter/material.dart';

class PlanningContextCard extends StatelessWidget {
  const PlanningContextCard({required this.entries, super.key});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Planning context',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final (label, value) in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Semantics(
                label: '$label: $value',
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 112,
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
