/// Layout tokens shared by every screen.
///
/// The values are deliberately few: a 4-pt spacing ramp, three corner radii and
/// two motion durations cover every surface in the app, which is what keeps the
/// screens looking like one instrument instead of a pile of default widgets.
library;

import 'package:flutter/material.dart';

/// Spacing ramp. Use these instead of raw numbers in new layout code.
abstract final class AppGap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii used by cards, tiles and controls.
abstract final class AppRadius {
  static const double control = 12;
  static const double card = 16;
  static const double sheet = 24;

  static BorderRadius get controlAll => BorderRadius.circular(control);
  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get sheetAll => BorderRadius.circular(sheet);
}

/// Motion used for reveals and state changes.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 220);
}

/// Typography helpers that keep measurements legible in columns.
extension AppTextStyles on TextStyle {
  /// Digits share a column width, so stacked numbers stop jittering.
  TextStyle get tabular =>
      copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]);
}

/// Centres and caps the width of a screen's content.
///
/// Phone layouts are unaffected; on a tablet or desktop window a form or result
/// card stops stretching to the full width and stays readable.
class AppContentFrame extends StatelessWidget {
  const AppContentFrame({required this.child, this.maxWidth = 760, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
