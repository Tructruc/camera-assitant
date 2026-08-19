import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/domain/validation/validation.dart';

void main() {
  CalculationSnapshot snapshot() => CalculationSnapshot(
    id: 'snapshot-1',
    calculatorId: 'depth_of_field',
    formulaVersion: 1,
    createdAt: DateTime.utc(2026, 8, 20, 10),
    title: 'Portrait depth of field',
    notes: 'Focus on the near eye',
    canonicalInputs: const <String, Object?>{
      'focalLengthMm': 85.0,
      'nested': <String, Object?>{'aperture': 2.0},
    },
    canonicalOutputs: const <String, Object?>{'nearLimitMm': 1960.0},
    displayContext: const <String, Object?>{'length': 'metric'},
    assumptions: const <CalculationAssumption>[
      CalculationAssumption(key: 'lensModel', value: 'thinLens'),
    ],
    warnings: const <CalculationWarning>[
      CalculationWarning(code: 'close_focus', messageKey: 'warning.close'),
    ],
    equipment: <AppliedEquipmentSnapshot>[
      AppliedEquipmentSnapshot(
        id: 'lens-1',
        type: SnapshotEquipmentType.lens,
        name: '85 mm prime',
        source: 'user',
        values: <String, Object?>{'focalLengthMm': 85.0},
      ),
    ],
  );

  test('round-trips every versioned canonical field without loss', () {
    final original = snapshot();
    final decoded = CalculationSnapshot.fromJson(original.toJson());

    expect(decoded.id, original.id);
    expect(decoded.payloadVersion, CalculationSnapshot.currentPayloadVersion);
    expect(decoded.canonicalInputs, original.canonicalInputs);
    expect(decoded.canonicalOutputs, original.canonicalOutputs);
    expect(decoded.displayContext, original.displayContext);
    expect(decoded.assumptions.single.key, 'lensModel');
    expect(decoded.warnings.single.code, 'close_focus');
    expect(decoded.equipment.single.values['focalLengthMm'], 85.0);
  });

  test('deeply freezes payloads and equipment values', () {
    final saved = snapshot();

    expect(() => saved.canonicalInputs['new'] = true, throwsUnsupportedError);
    expect(
      () => (saved.canonicalInputs['nested']! as Map<String, Object?>)['x'] = 1,
      throwsUnsupportedError,
    );
    expect(
      () => saved.equipment.single.values['changed'] = true,
      throwsUnsupportedError,
    );
  });

  test('metadata edits preserve immutable calculation payload identity', () {
    final original = snapshot();
    final renamed = original.withMetadata(title: 'Renamed', notes: 'New note');

    expect(renamed.title, 'Renamed');
    expect(renamed.notes, 'New note');
    expect(
      identical(renamed.canonicalInputs, original.canonicalInputs),
      isTrue,
    );
    expect(
      identical(renamed.canonicalOutputs, original.canonicalOutputs),
      isTrue,
    );
    expect(identical(renamed.equipment, original.equipment), isTrue);
  });

  test('rejects unsupported payload versions and invalid identity', () {
    final json = snapshot().toJson();
    json['payloadVersion'] = 99;

    expect(
      () => CalculationSnapshot.fromJson(json),
      throwsA(isA<UnsupportedSnapshotVersionException>()),
    );
    expect(
      () => CalculationSnapshot(
        id: ' ',
        calculatorId: 'depth_of_field',
        formulaVersion: 1,
        createdAt: DateTime.utc(2026),
        title: 'Result',
        canonicalInputs: const {},
        canonicalOutputs: const {},
        displayContext: const {},
      ),
      throwsArgumentError,
    );
  });
}
