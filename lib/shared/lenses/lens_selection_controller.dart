import 'package:camera_assistant/data/lenses/lens_repository.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/shared/lenses/lens_selection_state.dart';

class LensSelectionController {
  LensSelectionController({
    required LensRepository repository,
  }) : _repository = repository;

  final LensRepository _repository;

  LensSelectionState _state = const LensSelectionState();

  LensSelectionState get state => _state;

  Future<LensSelectionState> load() async {
    _state = _state.copyWith(loading: true);
    final lenses = await _repository.getLenses();
    final selectedExists =
        lenses.any((lens) => lens.id == _state.selectedLensId);

    _state = LensSelectionState(
      lenses: lenses,
      selectedLensId: selectedExists ? _state.selectedLensId : null,
    );
    return _state;
  }

  LensSelectionState clearSelection() {
    _state = _state.copyWith(clearSelectedLensId: true);
    return _state;
  }

  LensSelectionState selectLens(Lens lens) {
    _state = _state.copyWith(selectedLensId: lens.id);
    return _state;
  }

  Lens? lensById(int id) {
    for (final lens in _state.lenses) {
      if (lens.id == id) {
        return lens;
      }
    }
    return null;
  }

  double clampFocalLength(Lens lens, double value) {
    return value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
  }

  double minApertureAtFocal(Lens lens, double focalMm) {
    return lens.minApertureAtFocal(focalMm);
  }

  double clampApertureAtFocal(
    Lens lens, {
    required double focalMm,
    required double aperture,
  }) {
    final minAtFocal = minApertureAtFocal(lens, focalMm);
    return aperture.clamp(minAtFocal, lens.maxAperture);
  }
}
