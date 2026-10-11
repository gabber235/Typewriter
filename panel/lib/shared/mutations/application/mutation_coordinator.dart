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
    if (_disposed) {
      return Future.error(StateError("Mutation session ended"));
    }
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
        MutationReservation._(request.resources, (released) {
          _held.removeAll(released);
          if (!_disposed) {
            _drain();
          }
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
  MutationReservation._(this.resources, this._release);
  final Set<Object> resources;
  final void Function(Set<Object>) _release;
  bool _released = false;

  /// Transfers reserved keys to the requests that actually captured them.
  /// Overlapping keys stay held until every request using that key settles.
  List<MutationReservation> share(Iterable<Set<Object>> members) {
    final portions = members
        .map(Set<Object>.unmodifiable)
        .toList();
    if (_released ||
        portions.isEmpty ||
        portions.any((member) => !resources.containsAll(member))) {
      throw StateError(
        "Every request must own a subset of the live reservation",
      );
    }
    _released = true;
    final counts = <Object, int>{};
    for (final portion in portions) {
      for (final resource in portion) {
        counts.update(resource, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    _release(resources.difference(counts.keys.toSet()));
    return [
      for (final portion in portions)
        MutationReservation._(portion, (released) {
          final settled = <Object>{};
          for (final resource in released) {
            final remaining = counts[resource]! - 1;
            if (remaining == 0) {
              counts.remove(resource);
              settled.add(resource);
            } else {
              counts[resource] = remaining;
            }
          }
          _release(settled);
        }),
    ];
  }

  /// Releases the held resources and advances compatible queued requests.
  void release() {
    if (_released) {
      return;
    }
    _released = true;
    _release(resources);
  }
}
