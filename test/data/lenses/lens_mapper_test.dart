import 'package:camera_assistant/data/lenses/lens_mapper.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LensMapper', () {
    test('loads legacy rows with safe defaults for new fields', () {
      final lens = LensMapper.fromRow({
        'id': 1,
        'name': 'Legacy 50',
        'min_aperture': 1.8,
        'min_aperture_tele': 1.8,
        'max_aperture': 16.0,
        'variable_aperture': 0,
        'min_focal_mm': 50.0,
        'max_focal_mm': 50.0,
        'min_focus_m': 0.45,
      });

      expect(lens.name, 'Legacy 50');
      expect(lens.brand, isNull);
      expect(lens.mount, isNull);
      expect(lens.focusType, LensFocusType.manual);
      expect(lens.stabilization, LensStabilization.none);
      expect(lens.ownershipStatus, LensOwnershipStatus.owned);
      expect(lens.condition, isNull);
      expect(lens.purchaseDate, isNull);
    });

    test('stores extended metadata fields', () {
      final lens = Lens(
        id: 2,
        name: 'Macro Lens',
        brand: 'Tamron',
        model: '90mm F2.8',
        serialNumber: 'SN123',
        mount: 'Sony E',
        minApertureWide: 2.8,
        minApertureTele: 2.8,
        maxAperture: 32.0,
        variableAperture: false,
        minFocalLengthMm: 90.0,
        maxFocalLengthMm: 90.0,
        minFocusDistanceM: 0.29,
        filterThreadMm: 55.0,
        apertureBlades: 9,
        focusType: LensFocusType.both,
        stabilization: LensStabilization.optical,
        weightG: 610.0,
        lengthMm: 122.9,
        diameterMm: 79.2,
        notes: 'Sharp copy',
        purchaseDate: DateTime(2024, 6, 1),
        purchasePrice: 499.99,
        condition: LensCondition.excellent,
        ownershipStatus: LensOwnershipStatus.owned,
      );

      final row = LensMapper.toRow(lens);

      expect(row['brand'], 'Tamron');
      expect(row['model'], '90mm F2.8');
      expect(row['serial_number'], 'SN123');
      expect(row['mount'], 'Sony E');
      expect(row['filter_thread_mm'], 55.0);
      expect(row['aperture_blades'], 9);
      expect(row['focus_type'], 'both');
      expect(row['stabilization'], 'optical');
      expect(row['weight_g'], 610.0);
      expect(row['length_mm'], 122.9);
      expect(row['diameter_mm'], 79.2);
      expect(row['notes'], 'Sharp copy');
      expect(row['purchase_date'], '2024-06-01');
      expect(row['purchase_price'], 499.99);
      expect(row['condition'], 'excellent');
      expect(row['ownership_status'], 'owned');
    });
  });
}
