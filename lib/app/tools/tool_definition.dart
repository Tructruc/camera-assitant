import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:flutter/material.dart';

typedef ToolWidgetBuilder = Widget Function(
  BuildContext context,
  AppSettings settings,
);

class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final ToolWidgetBuilder builder;
}
