import 'dart:convert';

import 'package:camera_assistant/data/database/lens_library_transfer.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LensLibraryTransfer', () {
    final lens = Lens(
      name: 'Macro 90',
      brand: 'Tamron',
      model: '90mm F2.8',
      serialNumber: 'SN123',
      mount: 'Sony E',
      minApertureWide: 2.8,
      minApertureTele: 2.8,
      maxAperture: 32,
      variableAperture: false,
      minFocalLengthMm: 90,
      maxFocalLengthMm: 90,
      minFocusDistanceM: 0.29,
      filterThreadMm: 55,
      apertureBlades: 9,
      focusType: LensFocusType.both,
      stabilization: LensStabilization.optical,
      weightG: 610,
      lengthMm: 122.9,
      diameterMm: 79.2,
      notes: 'Sharp copy',
      purchaseDate: DateTime(2024, 6, 1),
      purchasePrice: 499.99,
      condition: LensCondition.excellent,
      ownershipStatus: LensOwnershipStatus.owned,
    );

    test('encodes metadata and lenses without database ids', () {
      final json = LensLibraryTransfer.encode(
        [lens],
        exportedAt: DateTime.utc(2026, 4, 30, 12),
      );
      final payload = jsonDecode(json) as Map<String, dynamic>;

      expect(payload['type'], LensLibraryTransfer.backupType);
      expect(payload['version'], LensLibraryTransfer.currentVersion);
      expect(payload['lens_count'], 1);
      expect(payload['exported_at'], '2026-04-30T12:00:00.000Z');

      final lenses = payload['lenses'] as List<dynamic>;
      expect(lenses, hasLength(1));
      expect((lenses.first as Map<String, dynamic>).containsKey('id'), isFalse);
      expect(
        (lenses.first as Map<String, dynamic>).containsKey('default_focal_mm'),
        isFalse,
      );
    });

    test('round-trips a backup payload into importable lenses', () {
      final imported = LensLibraryTransfer.decode(
        LensLibraryTransfer.encode([lens]),
      );

      expect(imported, hasLength(1));
      expect(imported.single.id, isNull);
      expect(imported.single.name, lens.name);
      expect(imported.single.brand, lens.brand);
      expect(imported.single.serialNumber, lens.serialNumber);
      expect(imported.single.minFocusDistanceM, lens.minFocusDistanceM);
      expect(imported.single.focusType, lens.focusType);
      expect(imported.single.purchaseDate, lens.purchaseDate);
    });

    test('accepts a raw JSON lens array during import', () {
      final imported = LensLibraryTransfer.decode(jsonEncode([
        {
          'name': 'Prime 50',
          'min_aperture': 1.8,
          'min_aperture_tele': 1.8,
          'max_aperture': 16.0,
          'variable_aperture': 0,
          'min_focal_mm': 50.0,
          'max_focal_mm': 50.0,
          'min_focus_m': 0.45,
        },
      ]));

      expect(imported, hasLength(1));
      expect(imported.single.name, 'Prime 50');
      expect(imported.single.id, isNull);
    });

    test('rejects payloads without a lens list', () {
      expect(
        () => LensLibraryTransfer.decode(jsonEncode({'type': 'wrong'})),
        throwsFormatException,
      );
    });
  });
}
