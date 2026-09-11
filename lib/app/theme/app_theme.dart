/// Accessible visual themes for daylight, dark, and low-light use.
///
/// The palette is deliberate rather than seeded: neutral graphite surfaces, one
/// warm amber accent (the colour of a camera's own displays and of the safety
/// markings on field gear), and semantic amber/red for limitations. Measurements
/// use tabular figures so numbers line up in columns.
library;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A tinted pair used to colour-code a tool family.
class AccentPair {
  const AccentPair({required this.container, required this.onContainer});

  final Color container;
  final Color onContainer;
}

/// Per-family accents so the catalog and every screen header carry the same
/// colour for the same kind of work (planning, optics, exposure, capture,
/// macro) instead of one grey icon tile everywhere.
class AppAccents extends ThemeExtension<AppAccents> {
  const AppAccents({
    required this.planning,
    required this.optics,
    required this.exposure,
    required this.capture,
    required this.macro,
  });

  final AccentPair planning;
  final AccentPair optics;
  final AccentPair exposure;
  final AccentPair capture;
  final AccentPair macro;

  static const AppAccents light = AppAccents(
    planning: AccentPair(
      container: Color(0xffd7e6f5),
      onContainer: Color(0xff12314a),
    ),
    optics: AccentPair(
      container: Color(0xffffe2be),
      onContainer: Color(0xff3a2000),
    ),
    exposure: AccentPair(
      container: Color(0xffffdcc7),
      onContainer: Color(0xff3d1b00),
    ),
    capture: AccentPair(
      container: Color(0xffcde8e4),
      onContainer: Color(0xff0e3531),
    ),
    macro: AccentPair(
      container: Color(0xffd6e8ce),
      onContainer: Color(0xff17300f),
    ),
  );

  static const AppAccents dark = AppAccents(
    planning: AccentPair(
      container: Color(0xff14344a),
      onContainer: Color(0xffcbe4f7),
    ),
    optics: AccentPair(
      container: Color(0xff4a2e00),
      onContainer: Color(0xffffdfb9),
    ),
    exposure: AccentPair(
      container: Color(0xff4a2400),
      onContainer: Color(0xffffd9bf),
    ),
    capture: AccentPair(
      container: Color(0xff123b36),
      onContainer: Color(0xffbee7e1),
    ),
    macro: AccentPair(
      container: Color(0xff1e3a16),
      onContainer: Color(0xffcbe8bf),
    ),
  );

  /// Night mode keeps every accent in the red family so no tile emits blue or
  /// green light at a dark-adapted eye.
  static const AppAccents lowLight = AppAccents(
    planning: AccentPair(
      container: Color(0xff241012),
      onContainer: Color(0xffeec7c2),
    ),
    optics: AccentPair(
      container: Color(0xff2e1512),
      onContainer: Color(0xfff2cdc7),
    ),
    exposure: AccentPair(
      container: Color(0xff301613),
      onContainer: Color(0xfff4cfc9),
    ),
    capture: AccentPair(
      container: Color(0xff221110),
      onContainer: Color(0xffecc5c0),
    ),
    macro: AccentPair(
      container: Color(0xff281410),
      onContainer: Color(0xfff0cac4),
    ),
  );

  static AppAccents of(BuildContext context) =>
      Theme.of(context).extension<AppAccents>() ?? light;

  @override
  AppAccents copyWith({
    AccentPair? planning,
    AccentPair? optics,
    AccentPair? exposure,
    AccentPair? capture,
    AccentPair? macro,
  }) => AppAccents(
    planning: planning ?? this.planning,
    optics: optics ?? this.optics,
    exposure: exposure ?? this.exposure,
    capture: capture ?? this.capture,
    macro: macro ?? this.macro,
  );

  @override
  AppAccents lerp(covariant AppAccents? other, double t) {
    if (other == null) return this;
    AccentPair mix(AccentPair a, AccentPair b) => AccentPair(
      container: Color.lerp(a.container, b.container, t)!,
      onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
    );
    return AppAccents(
      planning: mix(planning, other.planning),
      optics: mix(optics, other.optics),
      exposure: mix(exposure, other.exposure),
      capture: mix(capture, other.capture),
      macro: mix(macro, other.macro),
    );
  }
}

/// The accent for a screen, matched by the tool icon the catalog already uses.
///
/// Keeping the lookup here means a header and its catalog tile can never
/// disagree about which family a tool belongs to.
AccentPair accentForIcon(IconData icon, AppAccents accents) => switch (icon) {
  Icons.location_on_outlined ||
  Icons.align_horizontal_left ||
  Icons.nightlight_round => accents.planning,
  Icons.center_focus_strong ||
  Icons.aspect_ratio ||
  Icons.blur_circular ||
  Icons.layers_outlined => accents.optics,
  Icons.exposure ||
  Icons.timer_outlined ||
  Icons.flash_on_outlined => accents.exposure,
  Icons.movie_creation_outlined ||
  Icons.panorama_horizontal_outlined => accents.capture,
  Icons.local_florist_outlined => accents.macro,
  _ => accents.optics,
};

/// Application theme definitions with field-friendly control sizing.
abstract final class AppTheme {
  static final ThemeData light = _build(
    _lightScheme,
    _textTheme(_lightScheme),
    AppAccents.light,
  );
  static final ThemeData dark = _build(
    _darkScheme,
    _textTheme(_darkScheme),
    AppAccents.dark,
  );
  static final ThemeData lowLight = _build(
    _lowLightScheme,
    _textTheme(_lowLightScheme),
    AppAccents.lowLight,
  );

  // ---------------------------------------------------------------- palette

  static const Color _amber = Color(0xff9a4e00);
  static const Color _amberDark = Color(0xffffb868);
  static const Color _nightRed = Color(0xffff6f61);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _amber,
    onPrimary: Colors.white,
    primaryContainer: Color(0xffffddb8),
    onPrimaryContainer: Color(0xff2e1500),
    secondary: Color(0xff4a5a61),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xffdde6ea),
    onSecondaryContainer: Color(0xff10191d),
    tertiary: Color(0xff7a5900),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xffffe08a),
    onTertiaryContainer: Color(0xff241a00),
    error: Color(0xffb3261e),
    onError: Colors.white,
    errorContainer: Color(0xfff9dedc),
    onErrorContainer: Color(0xff410e0b),
    surface: Color(0xfff6f6f4),
    onSurface: Color(0xff101416),
    onSurfaceVariant: Color(0xff4c5559),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xfffbfbfa),
    surfaceContainer: Color(0xfff0f0ed),
    surfaceContainerHigh: Color(0xffe8e8e4),
    surfaceContainerHighest: Color(0xffe1e1dd),
    outline: Color(0xff767e82),
    outlineVariant: Color(0xffc6cbc8),
    shadow: Color(0x1a101416),
    scrim: Color(0x99101416),
    inverseSurface: Color(0xff2b3134),
    onInverseSurface: Color(0xfff0f1f1),
    inversePrimary: _amberDark,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _amberDark,
    onPrimary: Color(0xff3a1d00),
    primaryContainer: Color(0xff5a3200),
    onPrimaryContainer: Color(0xffffddb8),
    secondary: Color(0xffa9c0c8),
    onSecondary: Color(0xff18282e),
    secondaryContainer: Color(0xff2c3d43),
    onSecondaryContainer: Color(0xffd6e5ea),
    tertiary: Color(0xffffd479),
    onTertiary: Color(0xff2e2100),
    tertiaryContainer: Color(0xff5b4300),
    onTertiaryContainer: Color(0xffffe7ad),
    error: Color(0xffffb4ab),
    onError: Color(0xff690005),
    errorContainer: Color(0xff93000a),
    onErrorContainer: Color(0xffffdad6),
    surface: Color(0xff0f1214),
    onSurface: Color(0xffe7eaeb),
    onSurfaceVariant: Color(0xffa8b3b7),
    surfaceContainerLowest: Color(0xff0a0c0d),
    surfaceContainerLow: Color(0xff14181a),
    surfaceContainer: Color(0xff181d1f),
    surfaceContainerHigh: Color(0xff202629),
    surfaceContainerHighest: Color(0xff282f33),
    outline: Color(0xff6e7a7e),
    outlineVariant: Color(0xff394347),
    shadow: Color(0xff000000),
    scrim: Color(0xcc000000),
    inverseSurface: Color(0xffe7eaeb),
    onInverseSurface: Color(0xff1b2022),
    inversePrimary: _amber,
  );

  /// True-black surfaces with red-only accents so a night shooter keeps dark
  /// adaptation: nothing here emits blue or green light.
  static const ColorScheme _lowLightScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _nightRed,
    onPrimary: Color(0xff3a0a06),
    primaryContainer: Color(0xff4a0f0b),
    onPrimaryContainer: Color(0xffffd9d4),
    secondary: Color(0xffd0a5a0),
    onSecondary: Color(0xff2c1512),
    secondaryContainer: Color(0xff3a1c18),
    onSecondaryContainer: Color(0xfff0d3cf),
    tertiary: Color(0xffff9a8c),
    onTertiary: Color(0xff3a0c07),
    tertiaryContainer: Color(0xff4a120d),
    onTertiaryContainer: Color(0xffffd9d4),
    error: Color(0xffffb4ab),
    onError: Color(0xff3a0a06),
    errorContainer: Color(0xff5c130d),
    onErrorContainer: Color(0xffffdad6),
    // Pure black: the field surface must emit no light of its own.
    surface: Color(0xff000000),
    onSurface: Color(0xffe3c7c3),
    onSurfaceVariant: Color(0xffbb9b9a),
    surfaceContainerLowest: Color(0xff000000),
    surfaceContainerLow: Color(0xff0b0808),
    surfaceContainer: Color(0xff120c0b),
    surfaceContainerHigh: Color(0xff1a1110),
    surfaceContainerHighest: Color(0xff231615),
    outline: Color(0xff7a5a56),
    outlineVariant: Color(0xff3d2a27),
    shadow: Color(0xff000000),
    scrim: Color(0xcc000000),
    inverseSurface: Color(0xffe3c7c3),
    onInverseSurface: Color(0xff1b1110),
    inversePrimary: Color(0xffb3261e),
  );

  // ------------------------------------------------------------- typography

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = Typography.material2021().black;
    TextStyle? tabular(TextStyle? style) => style?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return base
        .copyWith(
          displaySmall: tabular(
            base.displaySmall?.copyWith(
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
            ),
          ),
          headlineMedium: tabular(
            base.headlineMedium?.copyWith(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
            ),
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 19,
            height: 1.25,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleMedium: tabular(
            base.titleMedium?.copyWith(
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.42),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.42),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12.5,
            height: 1.35,
            color: scheme.onSurfaceVariant,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  // ------------------------------------------------------------------ theme

  static ThemeData _build(
    ColorScheme scheme,
    TextTheme text,
    AppAccents accents,
  ) {
    final outline = scheme.outlineVariant;
    return ThemeData(
      colorScheme: scheme,
      extensions: <ThemeExtension<Object?>>[accents],
      textTheme: text,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: outline),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppGap.lg,
          vertical: AppGap.md,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.labelLarge?.copyWith(color: scheme.primary),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppGap.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppGap.lg),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppGap.md),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          highlightColor: scheme.surfaceContainerHighest,
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppGap.lg),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      expansionTileTheme: ExpansionTileThemeData(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppGap.sm),
        shape: const Border(),
        collapsedShape: const Border(),
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        showCheckmark: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(text.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetAll),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll<Color>(scheme.surfaceContainer),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        elevation: const WidgetStatePropertyAll<double>(0),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            side: BorderSide(color: outline),
          ),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle?>(text.bodyLarge),
        hintStyle: WidgetStatePropertyAll<TextStyle?>(
          text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
          side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: outline)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        textStyle: text.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppGap.sm),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
