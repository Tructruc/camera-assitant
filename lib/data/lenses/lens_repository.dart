import 'package:camera_assistant/domain/models/lens.dart';

abstract class LensRepository {
  Future<List<Lens>> getLenses();

  Future<Lens> insertLens(Lens lens);

  Future<void> updateLens(Lens lens);

  Future<void> deleteLens(int id);

  Future<String> exportLensLibrary();

  Future<int> importLensLibrary(
    String raw, {
    bool replaceExisting = true,
  });
}
