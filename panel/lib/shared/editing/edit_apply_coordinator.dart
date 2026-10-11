import "package:typewriter_panel/typewriter_panel.dart";

/// An opaque preparation request into one common workspace lane.
abstract interface class EditApplyRequest {
  Object get identity;
  Object get lane;
  LocalWorkCommands get submissions;
  Future<void> get idle;
  WorkLease? claim();
  EditingStageHold holdStage();
  Set<Object> get reservations;
  Future<void> observe();
  EditPreparedApply? capture();
  void reject(Object cause);
}

/// A captured real request. Starting it uses the workspace settlement path.
abstract interface class EditPreparedApply {
  Set<Object> get resources;
  Future<void> start(MutationReservation reservation);
}

/// Prepares every member before starting any independent server request.
/// A reservation is transferred into shared leases, without claiming atomic writes.
final class EditApplyCoordinator {
  const EditApplyCoordinator();
  Future<void> apply(Iterable<EditApplyRequest> requests) async {
    final unique = <Object, EditApplyRequest>{
      for (final request in requests) request.identity: request,
    }.values.toList();
    if (unique.isEmpty) return;
    final session = unique.first.submissions;
    if (unique.any((request) => !identical(request.submissions, session))) {
      throw StateError("Selection edits must belong to one work session");
    }
    final claims = <WorkLease>[];
    MutationReservation? reservation;
    try {
      final lanes = {for (final request in unique) request.lane: request}.values
          .toList();
      while (true) {
        await Future.wait(lanes.map((request) => request.idle));
        for (final request in lanes) {
          final claim = request.claim();
          if (claim == null) break;
          claims.add(claim);
        }
        if (claims.length == lanes.length) break;
        for (final claim in claims.reversed) {
          claim.release();
        }
        claims.clear();
      }
      while (true) {
        final keys = {for (final request in unique) ...request.reservations};
        reservation = await session.reserve(keys);
        for (final request in unique) {
          await request.observe();
        }
        final widened = {for (final request in unique) ...request.reservations};
        if (!keys.containsAll(widened)) {
          reservation.release();
          reservation = null;
          continue;
        }
        final holds = unique.map((request) => request.holdStage()).toList();
        try {
          final captured = [
            for (final request in unique)
              if (request.capture() case final prepared?)
                (lane: request.lane, prepared: prepared),
          ];
          if (captured.any(
            (capture) => !keys.containsAll(capture.prepared.resources),
          )) {
            throw StateError(
              "The prepared request changed its reserved resources",
            );
          }
          if (captured.isEmpty) return;
          final transfers = reservation.share(
            captured.map((capture) => capture.prepared.resources),
          );
          reservation = null;
          final tails = <Object, Future<void>>{};
          final running = <Future<void>>[];
          for (final (index, capture) in captured.indexed) {
            final next = (tails[capture.lane] ?? Future<void>.value()).then(
              (_) => capture.prepared.start(transfers[index]),
            );
            tails[capture.lane] = next;
            running.add(next);
          }
          for (final hold in holds) {
            hold.release();
          }
          await Future.wait(running);
          return;
        } finally {
          for (final hold in holds) {
            hold.release();
          }
        }
      }
    } on Object catch (error, stack) {
      if (error is! EditPreparationFailure) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: "shared editing",
            context: ErrorDescription("while preparing changes"),
          ),
        );
      }
      for (final request in unique) {
        request.reject(error);
      }
    } finally {
      reservation?.release();
      for (final claim in claims.reversed) {
        claim.release();
      }
    }
  }
}
