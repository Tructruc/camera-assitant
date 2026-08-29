import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/core/presentation/formatters/conventional_shutter_formatter.dart';

void main() {
  test('quantizes long shutters to the selected stop increment', () {
    expect(formatConventionalShutter(20, FractionStep.whole), '16 s');
    expect(formatConventionalShutter(20, FractionStep.half), '22.6 s');
    expect(formatConventionalShutter(20, FractionStep.third), '20.2 s');
  });

  test('uses familiar reciprocal shutter notation', () {
    expect(formatConventionalShutter(1 / 100, FractionStep.third), '1/100 s');
    expect(formatConventionalShutter(1 / 100, FractionStep.whole), '1/125 s');
  });

  test('rejects non-physical shutter durations', () {
    expect(
      () => formatConventionalShutter(0, FractionStep.third),
      throwsArgumentError,
    );
    expect(
      () => formatConventionalShutter(double.nan, FractionStep.third),
      throwsArgumentError,
    );
  });
}
