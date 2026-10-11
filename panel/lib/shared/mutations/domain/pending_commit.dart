import "package:typewriter_panel/typewriter_panel.dart";

/// Defers request capture until its resource reservation is acquired.
///
/// [resources] is the fixed consistency boundary. [prepare] must read current
/// local state, create an immutable [PreparedCommit], and return the same
/// participants. This is the bridge between draft ownership and delivery.
final class PendingCommit<T> {
  PendingCommit({required Set<Object> resources, required this.prepare})
    : resources = Set.unmodifiable(resources);

  /// Captures this commit and transfers [reservation] to the session.
  ///
  /// The generic type keeps the response associated with this pending commit
  /// when heterogeneous transactions are collected together.
  MutationSubmission<T> start(
    ScopedWorkSession workspace,
    MutationReservation reservation,
  ) {
    PreparedCommit<T>? captured;
    try {
      captured = prepare();
      if (!setEquals(captured.resources, resources)) {
        throw StateError("Preparation changed the reserved participants");
      }
      return workspace.start<T>(captured, reservation: reservation);
    } on Object {
      captured?.dispose?.call();
      rethrow;
    }
  }

  final Set<Object> resources;
  final PreparedCommit<T> Function() prepare;
}
