import "package:typewriter_panel/typewriter_panel.dart";

/// Serializes mutations that touch overlapping resource identities.
///
/// A request reserves its complete resource set atomically. Requests with
/// disjoint sets proceed together, while overlapping requests wait in arrival
/// order behind earlier overlapping work. The owner must release each returned
/// reservation exactly when the submission no longer needs its resources.
final class MutationCoordinator {
  final Set<Object> _held = {};
  final List<({Set<Object> resources, Completer<MutationReservation> ready})>
  _waiting = [];
  bool _disposed = false;

  /// Waits until [resources] can be held without overlap.
  Future<MutationReservation> reserve(Set<Object> resources) {
    if (_disposed) return Future.error(StateError("Mutation session ended"));
    final ready = Completer<MutationReservation>();
    _waiting.add((resources: Set.unmodifiable(resources), ready: ready));
    _drain();
    return ready.future;
  }

  void _drain() {
    final preceding = <Object>{};
    for (final request in List.of(_waiting)) {
      if (request.resources.any(_held.contains) ||
          request.resources.any(preceding.contains)) {
        preceding.addAll(request.resources);
        continue;
      }
      _waiting.remove(request);
      _held.addAll(request.resources);
      request.ready.complete(
        MutationReservation._(() {
          _held.removeAll(request.resources);
          if (!_disposed) _drain();
        }),
      );
    }
  }

  /// Rejects queued requests and releases coordinator state.
  void dispose() {
    _disposed = true;
    for (final request in _waiting) {
      request.ready.completeError(StateError("Mutation session ended"));
    }
    _waiting.clear();
    _held.clear();
  }
}

/// Idempotent ownership token for one coordinator reservation.
final class MutationReservation {
  MutationReservation._(this._release);
  final void Function() _release;
  bool _released = false;

  /// Releases the held resources and advances compatible queued requests.
  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}
