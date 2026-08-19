/// Storage boundary for immutable calculation snapshots.
library;

/// A supported snapshot, or preserved bytes requiring recovery.
sealed class SnapshotReadResult<T> {
  const SnapshotReadResult();
}

final class SupportedSnapshot<T> extends SnapshotReadResult<T> {
  const SupportedSnapshot(this.snapshot);
  final T snapshot;
}

final class UnreadableSnapshot<T> extends SnapshotReadResult<T> {
  const UnreadableSnapshot({
    required this.rawPayload,
    required this.reason,
    this.id,
  });
  final String? id;
  final String rawPayload;
  final String reason;
}

/// Persistence operations that never recalculate or mutate saved payloads.
abstract interface class SnapshotRepository<T> {
  Stream<List<T>> watchNewestFirst();
  Future<List<T>> listNewestFirst();
  Future<SnapshotReadResult<T>?> getById(String id);
  Future<void> save(T snapshot);
  Future<void> updateMetadata(
    String id, {
    required String title,
    String? notes,
  });
  Future<void> delete(String id);
}
