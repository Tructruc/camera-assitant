import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/features/astro/astro_screen.dart';
import 'package:flutter/material.dart';

class AstroCalculatorScreen extends StatelessWidget {
  const AstroCalculatorScreen({
    super.key,
    this.settings = const AppSettings(),
  });

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AstroScreen(settings: settings);
  }
}
