import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/features/macro/macro_screen.dart';
import 'package:camera_assistant/features/macro/macro_state.dart'
    show MacroToolMode;
import 'package:flutter/material.dart';

export 'package:camera_assistant/features/macro/macro_state.dart'
    show MacroToolMode;

class MacroCalculatorScreen extends StatelessWidget {
  const MacroCalculatorScreen({
    super.key,
    required this.settings,
    this.initialMode = MacroToolMode.extensionTubes,
  });

  final AppSettings settings;
  final MacroToolMode initialMode;

  @override
  Widget build(BuildContext context) {
    return MacroScreen(
      settings: settings,
      initialMode: initialMode,
    );
  }
}
