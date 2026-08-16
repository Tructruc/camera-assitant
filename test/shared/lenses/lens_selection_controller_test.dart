import 'package:camera_assistant/data/lenses/lens_repository.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/shared/lenses/lens_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final zoom = Lens(
    id: 1,
    name: 'Travel Zoom',
    minApertureWide: 3.5,
    minApertureTele: 5.6,
    maxAperture: 22,
    variableAperture: true,
    minFocalLengthMm: 24,
    maxFocalLengthMm: 70,
    minFocusDistanceM: 0.4,
  );

  test('loads lenses from repository', () async {
    final controller = LensSelectionController(
      repository: _FakeLensRepository([zoom]),
    );

    final state = await controller.load();

    expect(state.lenses, [zoom]);
    expect(state.selectedLens, isNull);
  });

  test('clears selected lens when a refresh no longer contains it', () async {
    final repository = _FakeLensRepository([zoom]);
    final controller = LensSelectionController(repository: repository);

    await controller.load();
    controller.selectLens(zoom);
    repository.lenses = const [];

    final state = await controller.load();

    expect(state.lenses, isEmpty);
    expect(state.selectedLensId, isNull);
  });

  test('clamps focal length and aperture to selected lens range', () {
    final controller = LensSelectionController(
      repository: _FakeLensRepository([zoom]),
    );

    expect(controller.clampFocalLength(zoom, 10), 24);
    expect(controller.clampFocalLength(zoom, 100), 70);
    expect(
      controller.clampApertureAtFocal(
        zoom,
        focalMm: 70,
        aperture: 2.8,
      ),
      closeTo(5.6, 0.01),
    );
    expect(
      controller.clampApertureAtFocal(
        zoom,
        focalMm: 70,
        aperture: 32,
      ),
      22,
    );
  });
}

class _FakeLensRepository implements LensRepository {
  _FakeLensRepository(this.lenses);

  List<Lens> lenses;

  @override
  Future<List<Lens>> getLenses() async => lenses;

  @override
  Future<void> deleteLens(int id) {
    throw UnimplementedError();
  }

  @override
  Future<String> exportLensLibrary() {
    throw UnimplementedError();
  }

  @override
  Future<int> importLensLibrary(
    String raw, {
    bool replaceExisting = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Lens> insertLens(Lens lens) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateLens(Lens lens) {
    throw UnimplementedError();
  }
}
