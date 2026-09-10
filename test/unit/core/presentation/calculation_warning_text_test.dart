import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/presentation/calculator/calculation_warning_text.dart';

/// Every `code: '...'` literal the library can attach to a result, read from
/// the source so a newly added code cannot silently reach users as the generic
/// fallback sentence just because nobody updated a hand-written list.
List<String> _codesInLibrary() {
  final codes = <String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    for (final match in RegExp(
      r"""code:\s*'([a-zA-Z_]+)'""",
    ).allMatches(entity.readAsStringSync())) {
      codes.add(match.group(1)!);
    }
  }
  return codes.toList()..sort();
}

void main() {
  test('the library really declares warning codes', () {
    // Guards the extraction itself: if the pattern or layout changes, this
    // fails instead of silently checking an empty set.
    expect(_codesInLibrary().length, greaterThanOrEqualTo(10));
  });

  test('every declared code has specific wording', () {
    for (final code in _codesInLibrary()) {
      final text = calculationWarningText(code);
      expect(text, isNotEmpty, reason: '$code must render');
      expect(
        text,
        isNot(contains('reported a limitation')),
        reason: '$code fell through to the generic sentence',
      );
      if (code.contains('_')) {
        // Underscored identifiers are internal; single-word codes such as
        // "range" or "sampling" can legitimately appear in prose.
        expect(
          text,
          isNot(contains(code)),
          reason: '$code leaked its internal code into user-facing text',
        );
      }
    }
  });

  test('safety-critical wording cannot regress', () {
    expect(
      calculationWarningText('solarSafety'),
      contains('certified solar filter'),
    );
    expect(calculationWarningText('frame_limit'), contains('1,000-frame'));
    expect(calculationWarningText('sampling_visible'), contains('Airy disk'));
    expect(
      calculationWarningText('milkyWayOrientationUndefined'),
      contains('zenith'),
    );
  });

  test('an unknown code still names itself instead of staying silent', () {
    final text = calculationWarningText('some_future_code');
    expect(text, contains('some_future_code'));
  });
}
