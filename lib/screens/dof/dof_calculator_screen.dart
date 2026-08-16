import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/features/dof/dof_screen.dart';
import 'package:flutter/material.dart';

class DofCalculatorScreen extends StatelessWidget {
  const DofCalculatorScreen({
    super.key,
    this.settings = const AppSettings(),
  });

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return DofScreen(settings: settings);
  }
}
