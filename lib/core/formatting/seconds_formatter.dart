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

  final minutes = total ~/ 60;
  final remainingSeconds = total % 60;
  return '${minutes}m ${remainingSeconds}s';
}
