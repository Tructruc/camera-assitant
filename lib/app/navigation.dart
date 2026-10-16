/// Primary navigation destinations and their accessible metadata.
///
/// The app is a field workbench with four destinations: plan the shot, open a
/// tool, check the kit, or reopen something saved. Settings is deliberately not
/// one of them - it is an app-bar action so it never competes with the work a
/// photographer came out to do.
library;

import 'package:flutter/material.dart';

export 'calculator_catalog.dart' show CalculatorDestination;

/// Width at or above which the shell shows a navigation rail instead of the
/// bottom navigation bar. Phones (including landscape phones) keep the bar.
const double appRailBreakpoint = 720;

/// Width at or above which the rail also labels every destination beside its
/// icon (the extended rail), which needs the extra room a desktop window has.
const double appExtendedRailBreakpoint = 1080;

enum AppDestination {
  plan(
    label: 'Plan',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  tools(
    label: 'Tools',
    icon: Icons.calculate_outlined,
    selectedIcon: Icons.calculate,
  ),
  kit(
    label: 'Kit',
    icon: Icons.camera_alt_outlined,
    selectedIcon: Icons.camera_alt,
  ),
  saved(
    label: 'Saved',
    icon: Icons.bookmark_border,
    selectedIcon: Icons.bookmark,
  );

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// The one accessible name a destination carries in both navigators.
  String get semanticLabel => '$label, primary navigation';

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: Semantics(label: semanticLabel, child: Icon(icon)),
      selectedIcon: Semantics(label: semanticLabel, child: Icon(selectedIcon)),
      label: label,
      tooltip: semanticLabel,
    );
  }

  NavigationRailDestination toNavigationRailDestination() {
    return NavigationRailDestination(
      icon: Semantics(label: semanticLabel, child: Icon(icon)),
      selectedIcon: Semantics(label: semanticLabel, child: Icon(selectedIcon)),
      label: Text(label, semanticsLabel: semanticLabel),
    );
  }
}

/// App-bar actions every destination shares.
abstract final class AppBarActions {
  /// Tooltip, and therefore the accessible name, of the settings action.
  static const String settingsLabel = 'Settings';
  static const IconData settingsIcon = Icons.settings_outlined;
}
