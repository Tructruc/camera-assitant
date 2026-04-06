import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/screens/dof/dof_calculator_screen.dart';
import 'package:camera_assistant/screens/macro/macro_calculator_screen.dart';
import 'package:flutter/material.dart';

enum _OpticsTool { dof, macro }

class OpticsScreen extends StatefulWidget {
  const OpticsScreen({super.key});

  @override
  State<OpticsScreen> createState() => _OpticsScreenState();
}

class _OpticsScreenState extends State<OpticsScreen> {
  _OpticsTool _tool = _OpticsTool.dof;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: scheme.surfaceContainerLow.withValues(alpha: 0.75),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optics Workspace',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Depth of field and macro calculations live here so the bottom navigation stays usable on phones.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<_OpticsTool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<_OpticsTool>(
                      value: _OpticsTool.dof,
                      label: Text('DOF'),
                      icon: Icon(Icons.filter_center_focus),
                    ),
                    ButtonSegment<_OpticsTool>(
                      value: _OpticsTool.macro,
                      label: Text('Macro'),
                      icon: Icon(Icons.center_focus_strong),
                    ),
                  ],
                  selected: {_tool},
                  onSelectionChanged: (selection) {
                    setState(() => _tool = selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tool.index,
            children: [
              DofCalculatorScreen(),
              MacroCalculatorScreen(
                settings: const AppSettings(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
