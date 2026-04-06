import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:flutter/material.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/screens/home/home_screen.dart';

class CameraAssistantApp extends StatefulWidget {
  const CameraAssistantApp({super.key});

  @override
  State<CameraAssistantApp> createState() => _CameraAssistantAppState();
}

class _CameraAssistantAppState extends State<CameraAssistantApp> {
  final _db = LensDatabase.instance;
  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _db.getAppSettings();
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
    _db.saveAppSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Assistant',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(isDark: false),
      darkTheme: _buildTheme(isDark: true),
      themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: _loaded
          ? HomeScreen(
              settings: _settings,
              onSettingsChanged: _updateSettings,
            )
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }

  ThemeData _buildTheme({required bool isDark}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    final surface = isDark ? const Color(0xFF061114) : const Color(0xFFF5F7F2);
    final card = isDark ? const Color(0xFF0E1D22) : const Color(0xFFFFFCF7);
    final border = isDark ? const Color(0xFF274149) : const Color(0xFFDAE2D6);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Trebuchet MS',
      textTheme:
          ThemeData(brightness: isDark ? Brightness.dark : Brightness.light)
              .textTheme
              .apply(
                bodyColor: scheme.onSurface,
                displayColor: scheme.onSurface,
              ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF102127)
            : Colors.white.withValues(alpha: 0.9),
        indicatorColor: scheme.tertiaryContainer.withValues(alpha: 0.9),
        height: 76,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: border,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF12252B) : const Color(0xFFFFFEFB),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark ? const Color(0xFF12252B) : const Color(0xFFFFFEFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(BorderSide(color: border)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
