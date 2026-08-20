/// Root application composition for the Photography Assistant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/repositories/preferences_repository.dart';
import '../features/equipment/presentation/equipment_list_screen.dart';
import '../features/saved_calculations/presentation/saved_calculations_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'calculator_catalog.dart';
import 'navigation.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

class PhotographyAssistantApp extends ConsumerWidget {
  const PhotographyAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider).valueOrNull;
    final selectedTheme = preferences?.themeMode ?? AppThemeMode.system;
    final lowLight = selectedTheme == AppThemeMode.lowLight;

    return AppErrorBoundary(
      child: MaterialApp(
        darkTheme: lowLight ? AppTheme.lowLight : AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const AppShell(),
        theme: lowLight ? AppTheme.lowLight : AppTheme.light,
        themeMode: _materialThemeMode(selectedTheme),
        title: 'Photography Assistant',
      ),
    );
  }
}

ThemeMode _materialThemeMode(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark || AppThemeMode.lowLight => ThemeMode.dark,
};

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final destination = AppDestination.values[_selectedIndex];
    return Scaffold(
      appBar: AppBar(title: Text(destination.label)),
      body: SafeArea(child: _screen(destination)),
      bottomNavigationBar: NavigationBar(
        destinations: AppDestination.values
            .map((item) => item.toNavigationDestination())
            .toList(growable: false),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        selectedIndex: _selectedIndex,
      ),
    );
  }

  Widget _screen(AppDestination destination) => switch (destination) {
    AppDestination.calculators => const CalculatorCatalogScreen(),
    AppDestination.equipment => const EquipmentListScreen(),
    AppDestination.saved => const SavedCalculationsScreen(),
    AppDestination.settings => const SettingsScreen(),
  };
}

class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({required this.child, super.key});
  final Widget child;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  late final ErrorWidgetBuilder _previousBuilder;
  late final ErrorWidgetBuilder _errorBuilder;

  @override
  void initState() {
    super.initState();
    _previousBuilder = ErrorWidget.builder;
    _errorBuilder = (details) => const AppErrorView();
    ErrorWidget.builder = _errorBuilder;
  }

  @override
  void dispose() {
    if (identical(ErrorWidget.builder, _errorBuilder)) {
      ErrorWidget.builder = _previousBuilder;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Semantics(
        container: true,
        label: 'Application error',
        liveRegion: true,
        child: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.error_outline, size: 48),
                  SizedBox(height: 16),
                  Text('Something went wrong'),
                  SizedBox(height: 8),
                  Text('Please restart the app. Your local data is preserved.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
