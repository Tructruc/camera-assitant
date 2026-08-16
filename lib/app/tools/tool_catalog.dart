import 'package:camera_assistant/app/tools/tool_definition.dart';
import 'package:camera_assistant/screens/astro/astro_calculator_screen.dart';
import 'package:camera_assistant/screens/dof/dof_calculator_screen.dart';
import 'package:camera_assistant/screens/exposure/exposure_calculator_screen.dart';
import 'package:camera_assistant/screens/focus_stacking/focus_stacking_planner_screen.dart';
import 'package:camera_assistant/screens/long_exposure/long_exposure_screen.dart';
import 'package:camera_assistant/screens/macro/macro_calculator_screen.dart';
import 'package:camera_assistant/screens/panorama/panorama_planner_screen.dart';
import 'package:camera_assistant/screens/sun_planner/sun_planner_screen.dart';
import 'package:flutter/material.dart';

class ToolCatalog {
  ToolCatalog._();

  static final List<ToolDefinition> tools = List.unmodifiable([
    ToolDefinition(
      id: 'exposure',
      title: 'Exposure',
      subtitle: 'Match one exposure to another.',
      icon: Icons.exposure,
      builder: (context, settings) => const ExposureCalculatorScreen(),
    ),
    ToolDefinition(
      id: 'dof',
      title: 'DOF',
      subtitle: 'Check depth of field and focus range.',
      icon: Icons.filter_center_focus,
      builder: (context, settings) => DofCalculatorScreen(settings: settings),
    ),
    ToolDefinition(
      id: 'focus_stacking',
      title: 'Focus Stacking',
      subtitle: 'Plan focus positions and frame count for a stack.',
      icon: Icons.layers_outlined,
      builder: (context, settings) =>
          FocusStackingPlannerScreen(settings: settings),
    ),
    ToolDefinition(
      id: 'panorama_planner',
      title: 'Panorama Planner',
      subtitle: 'Plan frames and overlap for a panorama.',
      icon: Icons.crop_landscape,
      builder: (context, settings) => PanoramaPlannerScreen(settings: settings),
    ),
    ToolDefinition(
      id: 'extension_tubes',
      title: 'Extension Tubes',
      subtitle: 'See close-focus range and magnification.',
      icon: Icons.add_circle_outline,
      builder: (context, settings) => MacroCalculatorScreen(settings: settings),
    ),
    ToolDefinition(
      id: 'reverse_lens',
      title: 'Reverse Lens',
      subtitle: 'Estimate magnification and focus distance.',
      icon: Icons.sync_alt,
      builder: (context, settings) => MacroCalculatorScreen(
        settings: settings,
        initialMode: MacroToolMode.reverseLens,
      ),
    ),
    ToolDefinition(
      id: 'dual_lens_macro',
      title: 'Dual Lens Macro',
      subtitle: 'Estimate stacked-lens magnification and exposure loss.',
      icon: Icons.join_inner,
      builder: (context, settings) => MacroCalculatorScreen(
        settings: settings,
        initialMode: MacroToolMode.dualLens,
      ),
    ),
    ToolDefinition(
      id: 'sun_planner',
      title: 'Sun Planner',
      subtitle: 'Plan sunrise, sunset, and golden hour.',
      icon: Icons.wb_sunny_outlined,
      builder: (context, settings) => SunPlannerScreen(settings: settings),
    ),
    ToolDefinition(
      id: 'astro_shutter',
      title: 'Astro Tools',
      subtitle: 'Simulate Moon/Sun framing and check star-trailing limits.',
      icon: Icons.nights_stay_outlined,
      builder: (context, settings) => AstroCalculatorScreen(settings: settings),
    ),
    ToolDefinition(
      id: 'long_exposure',
      title: 'Long Exposure',
      subtitle: 'Convert ND filters and estimate motion blur.',
      icon: Icons.shutter_speed,
      builder: (context, settings) => const LongExposureScreen(),
    ),
  ]);

  static Set<String> get toolIds => tools.map((tool) => tool.id).toSet();
}
