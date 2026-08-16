import 'package:camera_assistant/core/parsing/parse_result.dart';

double? parseDouble(String text) {
  final result = parseDoubleResult(text);
  return switch (result) {
    ParseSuccess<double>(:final value) => value,
    ParseFailure<double>() => null,
  };
}

ParseResult<double> parseDoubleResult(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) {
    return const ParseFailure('Enter a number.');
  }

  final fractionParts = cleaned.split('/');
  if (fractionParts.length == 2) {
    final numerator = double.tryParse(fractionParts[0].trim());
    final denominator = double.tryParse(fractionParts[1].trim());
    if (numerator == null || denominator == null) {
      return const ParseFailure('Enter a valid fraction.');
    }
    if (denominator == 0) {
      return const ParseFailure('Fraction denominator cannot be zero.');
    }
    return ParseSuccess(numerator / denominator);
  }

  if (fractionParts.length > 2) {
    return const ParseFailure('Enter a valid number.');
  }

  final value = double.tryParse(cleaned);
  if (value == null) {
    return const ParseFailure('Enter a valid number.');
  }
  return ParseSuccess(value);
}
