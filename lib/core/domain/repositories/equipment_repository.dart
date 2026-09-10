/// Storage boundary for reusable equipment entities.
///
/// Equipment is stored through the concrete repository in
/// `lib/features/equipment/data/drift_equipment_repository.dart`, whose
/// kind-specific operations (`createCamera`, `listLenses`, ...) are what the
/// controllers and screens actually depend on. The generic per-entity
/// interface that used to live here had no implementer and no caller, so it was
/// removed rather than kept as a second, drifting contract. `AppDatabase.inMemory()`
/// is the deterministic test double for that boundary.
library;

/// The effect an equipment mutation has on saved records.
final class EquipmentReferenceImpact {
  const EquipmentReferenceImpact({required this.snapshotCount});

  final int snapshotCount;
  bool get isReferenced => snapshotCount > 0;
}
