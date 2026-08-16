import 'package:camera_assistant/core/parsing/number_parser.dart';
import 'package:camera_assistant/core/parsing/parse_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseDouble parses decimals and fractions', () {
    expect(parseDouble('2.5'), 2.5);
    expect(parseDouble('1/125'), closeTo(0.008, 0.00001));
  });

  test('parseDouble returns null for invalid input', () {
    expect(parseDouble(''), isNull);
    expect(parseDouble('1/0'), isNull);
    expect(parseDouble('abc'), isNull);
  });

  test('parseDoubleResult exposes failure reasons', () {
    final result = parseDoubleResult('1/0');

    expect(result, isA<ParseFailure<double>>());
    expect(
      (result as ParseFailure<double>).message,
      'Fraction denominator cannot be zero.',
    );
  });
}
