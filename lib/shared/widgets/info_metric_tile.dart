import 'package:camera_assistant/shared/widgets/info_help_button.dart';
import 'package:flutter/material.dart';

class InfoMetricTile extends StatelessWidget {
  const InfoMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.helpText,
    this.helpTitle,
    this.width = 164,
  });

  final String label;
  final String value;
  final String? helpText;
  final String? helpTitle;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (helpText != null) ...[
                const SizedBox(width: 4),
                InfoHelpButton(
                  title: helpTitle ?? label,
                  message: helpText!,
                  tooltip: label,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
