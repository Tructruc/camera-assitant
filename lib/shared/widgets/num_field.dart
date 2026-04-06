import 'package:flutter/material.dart';

class NumField extends StatelessWidget {
  const NumField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.allowFractions = false,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool allowFractions;

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
          suffixStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          helperText: allowFractions ? 'You can enter values like 1/100' : null,
        ),
      ),
    );
  }
}
