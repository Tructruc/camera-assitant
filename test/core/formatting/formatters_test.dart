import 'package:camera_assistant/core/formatting/length_formatter.dart';
import 'package:camera_assistant/core/formatting/seconds_formatter.dart';
import 'package:camera_assistant/core/formatting/time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats fractional and long seconds', () {
    expect(formatFractionalSeconds(1 / 60), '1/60 s');
    expect(formatSecondsInput(1 / 125), '1/125');
    expect(formatSeconds(75), '1m 15s');
  });

  test('formats date time in 12 and 24 hour modes', () {
    final time = DateTime(2026, 5, 4, 14, 5);

    expect(formatTime(time), '02:05 PM');
    expect(formatTime(time, use12Hour: false), '14:05');
  });

  test('formats meter values using readable units', () {
    expect(formatLengthMeters(2), '2.00 m');
    expect(formatLengthMeters(0.25), '25.0 cm');
    expect(formatLengthMeters(0.005), '5.00 mm');
    expect(formatLengthMeters(0.000004), '4 \u03bcm');
  });
}
