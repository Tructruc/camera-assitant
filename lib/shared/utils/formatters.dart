// Format shutter time as fraction when under a second
String formatFractionalSeconds(double seconds) {
  if (seconds <= 0) {
    return '0 s';
  }

  if (seconds < 1) {
    final denom = (1 / seconds).round();
    if (denom > 0) {
      return '1/$denom s';
    }
  }

  return '${seconds.toStringAsFixed(2)} s';
}

// Format seconds for editable fields without appending units.
String formatSecondsInput(double seconds) {
  if (seconds <= 0) {
    return '0';
  }

  if (seconds < 1) {
    final denom = (1 / seconds).round();
    if (denom > 0) {
      return '1/$denom';
    }
  }

  if (seconds == seconds.roundToDouble()) {
    return seconds.toStringAsFixed(0);
  }

  return seconds.toStringAsFixed(2);
}

// Format seconds to human-readable string (always show fractions for < 1 second)
String formatSeconds(double seconds) {
  if (seconds < 1) {
    final denom = (1 / seconds).round();
    if (denom > 0) {
      return '1/$denom s';
    }
  }

  final total = seconds.round();
  if (total < 60) {
    return '${seconds.toStringAsFixed(2)} s';
  }

  final m = total ~/ 60;
  final s = total % 60;
  return '${m}m ${s}s';
}

// Format time with 12/24 hour format
String formatTime(DateTime time, {bool use12Hour = true}) {
  if (use12Hour) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  } else {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Parse text to double, returns null if invalid
double? parseDouble(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) {
    return null;
  }

  final fractionParts = cleaned.split('/');
  if (fractionParts.length == 2) {
    final numerator = double.tryParse(fractionParts[0].trim());
    final denominator = double.tryParse(fractionParts[1].trim());
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }

  return double.tryParse(cleaned);
}
