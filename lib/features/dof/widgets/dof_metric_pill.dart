import 'package:camera_assistant/shared/widgets/info_help_button.dart';
import 'package:flutter/material.dart';

class DofMetricPill extends StatelessWidget {
  const DofMetricPill({
    super.key,
    required this.label,
    required this.value,
    this.helpText,
  });

  final String label;
  final String value;
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.labelMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (helpText != null) ...[
            const SizedBox(width: 6),
            InfoHelpButton(
              title: label,
              message: helpText!,
              tooltip: label,
            ),
          ],
        ],
      ),
    );
  }
}
