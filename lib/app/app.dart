import 'package:camera_assistant/app/app_dependencies.dart';
import 'package:camera_assistant/app/app_theme.dart';
import 'package:camera_assistant/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';

class CameraAssistantApp extends StatefulWidget {
  const CameraAssistantApp({
    super.key,
    required this.dependencies,
  });

  final AppDependencies dependencies;

  @override
  State<CameraAssistantApp> createState() => _CameraAssistantAppState();
}

class _CameraAssistantAppState extends State<CameraAssistantApp> {
  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.dependencies.settings.getAppSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _loaded = true;
    });
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() => _settings = newSettings);
    widget.dependencies.settings.saveAppSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return MaterialApp(
        theme: AppTheme.build(isDark: false),
        darkTheme: AppTheme.build(isDark: true),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppDependenciesScope(
      dependencies: widget.dependencies,
      child: MaterialApp(
        title: 'Camera Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(isDark: false),
        darkTheme: AppTheme.build(isDark: true),
        themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,
        initialRoute: AppRoutes.home,
        onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
          settings,
          _settings,
          _updateSettings,
        ),
      ),
    );
  }
}
