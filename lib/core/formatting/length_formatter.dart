import 'package:camera_assistant/core/units/length_units.dart';

String formatLengthMeters(double meters) {
  final absolute = meters.abs();
  if (absolute >= 1) {
    return '${meters.toStringAsFixed(2)} ${LengthUnits.meter}';
  }
  if (absolute >= 0.01) {
    return '${(meters * 100).toStringAsFixed(1)} ${LengthUnits.centimeter}';
  }
  if (absolute >= 0.001) {
    return '${(meters * 1000).toStringAsFixed(2)} ${LengthUnits.millimeter}';
  }
  return '${(meters * 1000000).toStringAsFixed(0)} ${LengthUnits.micrometer}';
}
