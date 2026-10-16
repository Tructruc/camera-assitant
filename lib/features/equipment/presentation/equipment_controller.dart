/// Equipment inventory loading, filtering, and lifecycle presentation state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/drift_equipment_repository.dart';
import '../domain/equipment.dart';

enum EquipmentKind { camera, lens, filter, accessory }

enum EquipmentLoadStatus { loading, ready, error }

final class EquipmentListEntry {
  const EquipmentListEntry({required this.kind, required this.item});
  final EquipmentKind kind;
  final EquipmentItem item;
}

final class EquipmentState {
  const EquipmentState({
    this.status = EquipmentLoadStatus.loading,
    this.items = const <EquipmentListEntry>[],
    this.allItems = const <EquipmentListEntry>[],
    this.selectedKind,
    this.includeArchived = false,
    this.error,
  });

  final EquipmentLoadStatus status;

  /// The entries matching [selectedKind] (every entry when no kind is chosen).
  final List<EquipmentListEntry> items;

  /// Every loaded entry before the kind filter is applied, so the inventory can
  /// label each category with a truthful count. Additive: existing readers keep
  /// using [items] and see exactly the same list as before.
  final List<EquipmentListEntry> allItems;

  final EquipmentKind? selectedKind;
  final bool includeArchived;
  final Object? error;

  /// Every loaded entry that can currently be chosen: [allItems] with the
  /// archived ones removed.
  ///
  /// Pickers read this, never [items]. [items] answers the inventory's own
  /// "show me one category" question, so it carries the Kit kind filter — and
  /// once that filter is persisted by the kept-alive shell, a calculator that
  /// read [items] would lose the saved lenses or ND filters it needs the moment
  /// the photographer parks the inventory on another category. It is also
  /// independent of [includeArchived]: toggling archived items on is a
  /// housekeeping view, and an archived item is never a valid choice for a new
  /// calculation.
  ///
  /// The list is unfiltered by kind, so callers still narrow it themselves
  /// ([EquipmentKind.lens] here, [EquipmentKind.filter] there); only the two
  /// axes that must not leak into a calculation — category and archived state —
  /// are settled once, here.
  List<EquipmentListEntry> get activeItems =>
      allItems.where((entry) => !entry.item.isArchived).toList(growable: false);

  EquipmentState copyWith({
    EquipmentLoadStatus? status,
    List<EquipmentListEntry>? items,
    List<EquipmentListEntry>? allItems,
    EquipmentKind? selectedKind,
    bool clearSelectedKind = false,
    bool? includeArchived,
    Object? error,
    bool clearError = false,
  }) => EquipmentState(
    status: status ?? this.status,
    items: items ?? this.items,
    allItems: allItems ?? this.allItems,
    selectedKind: clearSelectedKind ? null : selectedKind ?? this.selectedKind,
    includeArchived: includeArchived ?? this.includeArchived,
    error: clearError ? null : error ?? this.error,
  );
}

final equipmentControllerProvider =
    StateNotifierProvider.autoDispose<EquipmentController, EquipmentState>((
      ref,
    ) {
      final controller = EquipmentController(
        ref.watch(equipmentRepositoryProvider),
      );
      controller.load();
      return controller;
    });

final class EquipmentController extends StateNotifier<EquipmentState> {
  EquipmentController(this._repository) : super(const EquipmentState());
  final DriftEquipmentRepository _repository;

  Future<void> load() async {
    state = state.copyWith(
      status: EquipmentLoadStatus.loading,
      clearError: true,
    );
    try {
      final results = await Future.wait(<Future<List<EquipmentListEntry>>>[
        _repository
            .listCameras(includeArchived: state.includeArchived)
            .then(
              (items) => items
                  .map(
                    (item) => EquipmentListEntry(
                      kind: EquipmentKind.camera,
                      item: item,
                    ),
                  )
                  .toList(),
            ),
        _repository
            .listAccessories(includeArchived: state.includeArchived)
            .then(
              (items) => items
                  .map(
                    (item) => EquipmentListEntry(
                      kind: EquipmentKind.accessory,
                      item: item,
                    ),
                  )
                  .toList(),
            ),
        _repository
            .listLenses(includeArchived: state.includeArchived)
            .then(
              (items) => items
                  .map(
                    (item) => EquipmentListEntry(
                      kind: EquipmentKind.lens,
                      item: item,
                    ),
                  )
                  .toList(),
            ),
        _repository
            .listFilters(includeArchived: state.includeArchived)
            .then(
              (items) => items
                  .map(
                    (item) => EquipmentListEntry(
                      kind: EquipmentKind.filter,
                      item: item,
                    ),
                  )
                  .toList(),
            ),
      ]);
      final all = results.expand((group) => group).toList()
        ..sort(
          (left, right) =>
              left.item.normalizedName.compareTo(right.item.normalizedName),
        );
      final selectedKind = state.selectedKind;
      final items = selectedKind == null
          ? all
          : all.where((entry) => entry.kind == selectedKind).toList();
      state = state.copyWith(
        status: EquipmentLoadStatus.ready,
        items: List.unmodifiable(items),
        allItems: List.unmodifiable(all),
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(status: EquipmentLoadStatus.error, error: error);
    }
  }

  Future<void> setKind(EquipmentKind? kind) async {
    state = state.copyWith(selectedKind: kind, clearSelectedKind: kind == null);
    await load();
  }

  Future<void> setIncludeArchived(bool value) async {
    state = state.copyWith(includeArchived: value);
    await load();
  }

  /// Mutations report success instead of throwing, so every screen can show
  /// its own recovery message and no failure escapes to the framework
  /// (FR-021). A failure leaves the loaded list untouched.
  Future<bool> create(EquipmentItem item) => _mutate(() async {
    switch (item) {
      case CameraBody():
        await _repository.createCamera(item);
      case Lens():
        await _repository.createLens(item);
      case NdFilter():
        await _repository.createFilter(item);
      case OpticalAccessory():
        await _repository.createAccessory(item);
    }
  });

  Future<bool> update(EquipmentItem item) => _mutate(() async {
    switch (item) {
      case CameraBody():
        await _repository.updateCamera(item);
      case Lens():
        await _repository.updateLens(item);
      case NdFilter():
        await _repository.updateFilter(item);
      case OpticalAccessory():
        await _repository.updateAccessory(item);
    }
  });

  Future<bool> archive(EquipmentListEntry entry) => _mutate(() async {
    switch (entry.kind) {
      case EquipmentKind.camera:
        await _repository.archiveCamera(entry.item.id);
      case EquipmentKind.lens:
        await _repository.archiveLens(entry.item.id);
      case EquipmentKind.filter:
        await _repository.archiveFilter(entry.item.id);
      case EquipmentKind.accessory:
        await _repository.archiveAccessory(entry.item.id);
    }
  });

  Future<bool> delete(EquipmentListEntry entry) => _mutate(() async {
    switch (entry.kind) {
      case EquipmentKind.camera:
        await _repository.deleteCamera(entry.item.id);
      case EquipmentKind.lens:
        await _repository.deleteLens(entry.item.id);
      case EquipmentKind.filter:
        await _repository.deleteFilter(entry.item.id);
      case EquipmentKind.accessory:
        await _repository.deleteAccessory(entry.item.id);
    }
  });

  Future<bool> restore(EquipmentListEntry entry) => _mutate(() async {
    switch (entry.kind) {
      case EquipmentKind.camera:
        await _repository.restoreCamera(entry.item.id);
      case EquipmentKind.lens:
        await _repository.restoreLens(entry.item.id);
      case EquipmentKind.filter:
        await _repository.restoreFilter(entry.item.id);
      case EquipmentKind.accessory:
        await _repository.restoreAccessory(entry.item.id);
    }
  });

  Future<bool> _mutate(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // The screen owns the user-facing message; the list stays as it was.
      return false;
    }
    await load();
    return true;
  }
}
