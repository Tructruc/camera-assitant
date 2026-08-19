/// Accessible visual themes for daylight, dark, and low-light use.
library;

import 'package:flutter/material.dart';

/// Application theme definitions with field-friendly control sizing.
abstract final class AppTheme {
  static final ThemeData light = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xff006a6a),
      brightness: Brightness.light,
      contrastLevel: 0.25,
    ),
  );

  static final ThemeData dark = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xff4fd8d8),
      brightness: Brightness.dark,
      contrastLevel: 0.25,
    ),
  );

  static final ThemeData lowLight = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xffff5449),
      brightness: Brightness.dark,
      contrastLevel: 0.5,
    ).copyWith(
      surface: Colors.black,
      onSurface: const Color(0xffffdad6),
      primary: const Color(0xffffb4ab),
      onPrimary: const Color(0xff690005),
    ),
  );

  static ThemeData _build(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: colorScheme.surface,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
    );
  }
}
