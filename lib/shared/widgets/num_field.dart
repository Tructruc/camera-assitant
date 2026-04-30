import 'package:flutter/material.dart';
import 'package:camera_assistant/shared/widgets/info_help_button.dart';

class NumField extends StatelessWidget {
  const NumField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.allowFractions = false,
    this.helpText,
    this.helpTitle,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool allowFractions;
  final String? helpText;
  final String? helpTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: allowFractions
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          suffixIcon: helpText == null
              ? null
              : InfoHelpButton(
                  title: helpTitle ?? label,
                  message: helpText!,
                  tooltip: label,
                ),
          suffixStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
