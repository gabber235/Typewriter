import "package:typewriter_panel/typewriter_panel.dart";

/// Joins the items of one batch contract that are prepared in the same turn
/// into one request.
///
/// A person's change to several resources is one change, so the server
/// applies it all or nothing. Every item joined before the batch seals (at the
/// end of the turn it opened in, or at its first send) travels in one request
/// built by the batch's prepare function. Each member stays its own
/// submission with its own identity, reservations and settlement, and reads
/// its own outcome from the shared reply.
///
/// A member's first send starts the request and later members of the same
/// attempt share its reply. Sending a member again sends the whole captured
/// request again; members that send again together share that attempt, so a
/// replayable batch contract must accept the identical request twice. The
/// batch request integrates each attempt's reply once, whichever member
/// integrates first.
final class PreparedBatches<I, R> {
  PreparedBatches(this._prepare);

  final PreparedCommit<R> Function(List<I> items) _prepare;
  _PreparedBatch<I, R>? _open;

  /// Adds [item] to the batch open in this turn and returns its member.
  PreparedCommit<R> join(
    I item, {
    required String label,
    Set<Object> resources = const {},
    SubmissionReplay replay = SubmissionReplay.unsupported,
  }) {
    final batch = _open ??= _openBatch();
    batch.items.add(item);
    var sends = 0;
    var lastAttempt = -1;
    return PreparedCommit<R>(
      id: uuid.v4(),
      label: label,
      resources: resources,
      replay: replay,
      send: () {
        final attempt = sends++;
        lastAttempt = attempt;
        if (identical(_open, batch)) _open = null;
        return batch.send(attempt);
      },
      integrate: (_) async {
        if (lastAttempt >= 0) await batch.integrate(lastAttempt);
      },
    );
  }

  _PreparedBatch<I, R> _openBatch() {
    final batch = _PreparedBatch<I, R>(_prepare);
    scheduleMicrotask(() {
      if (identical(_open, batch)) _open = null;
    });
    return batch;
  }
}

final class _PreparedBatch<I, R> {
  _PreparedBatch(this._prepare);

  final PreparedCommit<R> Function(List<I> items) _prepare;
  final items = <I>[];
  late final PreparedCommit<R> _commit = _prepare(List.unmodifiable(items));
  final _attempts = <int, Future<SubmissionResult<R>>>{};
  final _integrations = <int, Future<void>>{};

  Future<SubmissionResult<R>> send(int attempt) =>
      _attempts[attempt] ??= _commit.send();

  Future<void> integrate(int attempt) => _integrations[attempt] ??= () async {
    final result = await _attempts[attempt];
    if (result != null) await _commit.integrate?.call(result);
  }();
}
