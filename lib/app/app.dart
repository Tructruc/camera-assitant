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
import 'theme/design_tokens.dart';

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

  /// Destinations are built the first time they are opened and then kept alive,
  /// so scrolling, a search query and a half-filled form all survive a trip to
  /// another destination. Later destinations stay unbuilt until they are used.
  late final List<bool> _visited = List<bool>.generate(
    AppDestination.values.length,
    (index) => index == 0,
  );

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _visited[index] = true;
    });
  }

  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text(AppBarActions.settingsLabel)),
          body: const SafeArea(child: AppContentFrame(child: SettingsScreen())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = AppDestination.values[_selectedIndex];
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= appRailBreakpoint;
        return Scaffold(
          appBar: AppBar(
            title: Text(destination.label),
            actions: <Widget>[
              IconButton(
                tooltip: AppBarActions.settingsLabel,
                icon: const Icon(AppBarActions.settingsIcon),
                onPressed: _openSettings,
              ),
            ],
          ),
          body: useRail
              ? Row(
                  children: <Widget>[
                    _rail(constraints.maxWidth),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(child: _content()),
                  ],
                )
              : _content(),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  destinations: AppDestination.values
                      .map((item) => item.toNavigationDestination())
                      .toList(growable: false),
                  onDestinationSelected: _selectDestination,
                  selectedIndex: _selectedIndex,
                ),
        );
      },
    );
  }

  Widget _rail(double width) {
    final extended = width >= appExtendedRailBreakpoint;
    return SafeArea(
      // The app bar already consumed the status bar inset.
      top: false,
      child: NavigationRail(
        destinations: AppDestination.values
            .map((item) => item.toNavigationRailDestination())
            .toList(growable: false),
        extended: extended,
        // An extended rail labels every destination beside its icon and rejects
        // an explicit label type; the compact rail always shows its labels.
        labelType: extended ? null : NavigationRailLabelType.all,
        onDestinationSelected: _selectDestination,
        selectedIndex: _selectedIndex,
      ),
    );
  }

  Widget _content() =>
      SafeArea(child: AppContentFrame(child: _destinationStack()));

  Widget _destinationStack() => IndexedStack(
    index: _selectedIndex,
    sizing: StackFit.expand,
    children: <Widget>[
      for (var index = 0; index < AppDestination.values.length; index++)
        if (_visited[index])
          _screen(AppDestination.values[index])
        else
          const SizedBox.shrink(),
    ],
  );

  Widget _screen(AppDestination destination) => switch (destination) {
    AppDestination.plan => PlanHubScreen(
      onOpenTools: () => _selectDestination(AppDestination.tools.index),
    ),
    AppDestination.tools => const CalculatorCatalogScreen(),
    AppDestination.kit => const EquipmentListScreen(),
    AppDestination.saved => const SavedCalculationsScreen(),
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
