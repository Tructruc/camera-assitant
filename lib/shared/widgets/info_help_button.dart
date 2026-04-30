import 'package:flutter/material.dart';

class InfoHelpButton extends StatelessWidget {
  const InfoHelpButton({
    super.key,
    required this.message,
    this.title,
    this.tooltip,
    this.iconSize = 16,
  });

  final String message;
  final String? title;
  final String? tooltip;
  final double iconSize;

  Future<void> _showHelp(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: title == null ? null : Text(title!),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip ?? title ?? 'Help',
      child: SizedBox(
        width: 22,
        height: 22,
        child: InkResponse(
          radius: 16,
          onTap: () => _showHelp(context),
          child: Icon(
            Icons.info_outline,
            size: iconSize,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
