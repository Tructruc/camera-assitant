/// Primary navigation destinations and their accessible metadata.
library;

import 'package:flutter/material.dart';

enum AppDestination {
  calculators(
    label: 'Calculators',
    icon: Icons.calculate_outlined,
    selectedIcon: Icons.calculate,
  ),
  equipment(
    label: 'Equipment',
    icon: Icons.camera_alt_outlined,
    selectedIcon: Icons.camera_alt,
  ),
  saved(
    label: 'Saved',
    icon: Icons.bookmark_border,
    selectedIcon: Icons.bookmark,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: Semantics(label: '$label, primary navigation', child: Icon(icon)),
      selectedIcon: Semantics(
        label: '$label, primary navigation',
        child: Icon(selectedIcon),
      ),
      label: label,
      tooltip: '$label, primary navigation',
    );
  }
}
