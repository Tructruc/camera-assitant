/// Immutable physical quantities normalized for deterministic calculations.
library;

double _positiveFinite(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive and finite');
  }
  return value;
}

double _finite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'must be finite');
  }
  return value;
}

/// A positive length stored canonically in millimetres.
final class Length {
  Length.millimetres(double value)
    : millimetres = _positiveFinite(value, 'millimetres');

  Length.centimetres(double value) : this.millimetres(value * 10);

  Length.metres(double value) : this.millimetres(value * 1000);

  Length.inches(double value) : this.millimetres(value * 25.4);

  Length.feet(double value) : this.inches(value * 12);

  final double millimetres;

  double get metres => millimetres / 1000;
  double get inches => millimetres / 25.4;
  double get feet => inches / 12;

  @override
  bool operator ==(Object other) =>
      other is Length && other.millimetres == millimetres;

  @override
  int get hashCode => millimetres.hashCode;
}

/// A focus distance, including an explicit infinity state.
final class FocusDistance {
  FocusDistance.millimetres(double value)
    : millimetres = _positiveFinite(value, 'millimetres');

  const FocusDistance._infinity() : millimetres = double.infinity;

  static const FocusDistance infinity = FocusDistance._infinity();

  final double millimetres;
  bool get isInfinite => millimetres.isInfinite;
}

/// A positive lens aperture expressed as an f-number.
final class Aperture {
  Aperture(double value) : fNumber = _positiveFinite(value, 'fNumber');
  final double fNumber;
}

/// A positive exposure duration stored in seconds.
final class ExposureTime {
  ExposureTime.seconds(double value)
    : seconds = _positiveFinite(value, 'seconds');
  final double seconds;
}

/// A positive ISO sensitivity.
final class Sensitivity {
  Sensitivity.iso(double value) : iso = _positiveFinite(value, 'iso');
  final double iso;
}

/// A signed exposure difference measured in base-2 stops.
final class StopDifference {
  StopDifference(double value) : stops = _finite(value, 'stops');
  final double stops;
}

/// A non-negative neutral-density filter strength in stops.
final class FilterStrength {
  FilterStrength(double value) : stops = _validate(value);

  final double stops;

  static double _validate(double value) {
    final finite = _finite(value, 'stops');
    if (finite < 0) {
      throw ArgumentError.value(value, 'stops', 'must be non-negative');
    }
    return finite;
  }
}

/// A positive circle of confusion stored in millimetres.
final class CircleOfConfusion {
  CircleOfConfusion.millimetres(double value)
    : millimetres = _positiveFinite(value, 'millimetres');
  final double millimetres;
}
