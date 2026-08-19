/// Storage boundary for reusable equipment entities.
library;

/// The effect an equipment mutation has on saved records.
final class EquipmentReferenceImpact {
  const EquipmentReferenceImpact({required this.snapshotCount});

  final int snapshotCount;
  bool get isReferenced => snapshotCount > 0;
}

/// CRUD and lifecycle operations for one equipment entity type.
abstract interface class EquipmentRepository<T> {
  Stream<List<T>> watch({bool includeArchived = false});
  Future<List<T>> list({bool includeArchived = false});
  Future<T?> getById(String id);
  Future<void> create(T item);
  Future<void> update(T item);
  Future<void> archive(String id);
  Future<void> restore(String id);
  Future<EquipmentReferenceImpact> referenceImpact(String id);
}
