import 'package:camera_assistant/data/database/lens_library_transfer.dart';
import 'package:camera_assistant/data/lenses/lens_dao.dart';
import 'package:camera_assistant/data/lenses/lens_repository.dart';
import 'package:camera_assistant/domain/models/lens.dart';

class SqliteLensRepository implements LensRepository {
  SqliteLensRepository({
    LensDao? lensDao,
  }) : _lensDao = lensDao ?? LensDao();

  final LensDao _lensDao;

  @override
  Future<List<Lens>> getLenses() {
    return _lensDao.getLenses();
  }

  @override
  Future<Lens> insertLens(Lens lens) {
    return _lensDao.insertLens(lens);
  }

  @override
  Future<void> updateLens(Lens lens) {
    return _lensDao.updateLens(lens);
  }

  @override
  Future<void> deleteLens(int id) {
    return _lensDao.deleteLens(id);
  }

  @override
  Future<String> exportLensLibrary() async {
    final lenses = await _lensDao.getLenses();
    return LensLibraryTransfer.encode(lenses);
  }

  @override
  Future<int> importLensLibrary(
    String raw, {
    bool replaceExisting = true,
  }) async {
    final lenses = LensLibraryTransfer.decode(raw);
    await _lensDao.replaceLenses(lenses, replaceExisting: replaceExisting);
    return lenses.length;
  }
}
