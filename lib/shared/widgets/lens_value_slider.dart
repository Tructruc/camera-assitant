import 'package:flutter/material.dart';

class LensValueSlider extends StatelessWidget {
  const LensValueSlider({
    super.key,
    required this.label,
    required this.minLabel,
    required this.maxLabel,
    required this.min,
    required this.max,
    required this.value,
    required this.controller,
    required this.onChanged,
    this.suffix = '',
    this.enabled = true,
    this.divisions = 180,
  });

  final String label;
  final String minLabel;
  final String maxLabel;
  final double min;
  final double max;
  final double value;
  final TextEditingController controller;
  final bool enabled;
  final String suffix;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    suffixText: suffix,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
          ),
          Row(
            children: [
              Text(minLabel, style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text(maxLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
