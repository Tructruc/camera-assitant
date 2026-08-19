/// Equipment inventory loading, filtering, and lifecycle presentation state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/drift_equipment_repository.dart';
import '../domain/equipment.dart';

enum EquipmentKind { camera, lens, filter }

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
    this.selectedKind,
    this.includeArchived = false,
    this.error,
  });

  final EquipmentLoadStatus status;
  final List<EquipmentListEntry> items;
  final EquipmentKind? selectedKind;
  final bool includeArchived;
  final Object? error;

  EquipmentState copyWith({
    EquipmentLoadStatus? status,
    List<EquipmentListEntry>? items,
    EquipmentKind? selectedKind,
    bool clearSelectedKind = false,
    bool? includeArchived,
    Object? error,
    bool clearError = false,
  }) => EquipmentState(
    status: status ?? this.status,
    items: items ?? this.items,
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
      final items =
          results.expand((group) => group).where((entry) {
            return state.selectedKind == null ||
                entry.kind == state.selectedKind;
          }).toList()..sort(
            (left, right) =>
                left.item.normalizedName.compareTo(right.item.normalizedName),
          );
      state = state.copyWith(
        status: EquipmentLoadStatus.ready,
        items: List.unmodifiable(items),
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

  Future<void> create(EquipmentItem item) async {
    switch (item) {
      case CameraBody():
        await _repository.createCamera(item);
      case Lens():
        await _repository.createLens(item);
      case NdFilter():
        await _repository.createFilter(item);
    }
    await load();
  }

  Future<void> archive(EquipmentListEntry entry) async {
    switch (entry.kind) {
      case EquipmentKind.camera:
        await _repository.archiveCamera(entry.item.id);
      case EquipmentKind.lens:
        await _repository.archiveLens(entry.item.id);
      case EquipmentKind.filter:
        await _repository.archiveFilter(entry.item.id);
    }
    await load();
  }

  Future<void> restore(EquipmentListEntry entry) async {
    switch (entry.kind) {
      case EquipmentKind.camera:
        await _repository.restoreCamera(entry.item.id);
      case EquipmentKind.lens:
        await _repository.restoreLens(entry.item.id);
      case EquipmentKind.filter:
        await _repository.restoreFilter(entry.item.id);
    }
    await load();
  }
}
