import 'package:camera_assistant/domain/models/lens.dart';

class LensSelectionState {
  const LensSelectionState({
    this.lenses = const [],
    this.selectedLensId,
    this.loading = false,
  });

  final List<Lens> lenses;
  final int? selectedLensId;
  final bool loading;

  Lens? get selectedLens {
    final id = selectedLensId;
    if (id == null) {
      return null;
    }

    for (final lens in lenses) {
      if (lens.id == id) {
        return lens;
      }
    }
    return null;
  }

  LensSelectionState copyWith({
    List<Lens>? lenses,
    int? selectedLensId,
    bool clearSelectedLensId = false,
    bool? loading,
  }) {
    return LensSelectionState(
      lenses: lenses ?? this.lenses,
      selectedLensId:
          clearSelectedLensId ? null : selectedLensId ?? this.selectedLensId,
      loading: loading ?? this.loading,
    );
  }
}
