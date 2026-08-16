import 'package:camera_assistant/app/tools/tool_catalog.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/screens/home/home_screen.dart';
import 'package:camera_assistant/screens/lenses/lens_manager_screen.dart';
import 'package:camera_assistant/screens/settings/settings_screen.dart';
import 'package:camera_assistant/shared/widgets/tool_scaffold.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const lenses = '/lenses';

  static String tool(String id) => '/tools/$id';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AppSettings appSettings,
    ValueChanged<AppSettings> onSettingsChanged,
  ) {
    final name = settings.name;

    if (name == home) {
      return MaterialPageRoute(
        builder: (_) => HomeScreen(
          settings: appSettings,
          onSettingsChanged: onSettingsChanged,
        ),
        settings: settings,
      );
    }

    if (name == settings) {
      return MaterialPageRoute(
        builder: (_) => ToolScaffold(
          title: 'Settings',
          child: SettingsScreen(
            settings: appSettings,
            onSettingsChanged: onSettingsChanged,
          ),
        ),
        settings: settings,
      );
    }

    if (name == lenses) {
      return MaterialPageRoute(
        builder: (_) => const ToolScaffold(
          title: 'Lens Library',
          child: LensManagerScreen(),
        ),
        settings: settings,
      );
    }

    if (name != null && name.startsWith('/tools/')) {
      final toolId = name.replaceFirst('/tools/', '');
      final tool = ToolCatalog.tools.where((t) => t.id == toolId).firstOrNull;

      if (tool != null) {
        return MaterialPageRoute(
          builder: (context) => ToolScaffold(
            title: tool.title,
            child: tool.builder(context, appSettings),
          ),
          settings: settings,
        );
      }
    }

    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('No route defined for ${settings.name}')),
      ),
    );
  }
}
