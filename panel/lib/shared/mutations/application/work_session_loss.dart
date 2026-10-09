import "package:typewriter_panel/typewriter_panel.dart";

part "work_session_loss.g.dart";

/// Shares one session loss decision owner across account and route actions.
@Riverpod(keepAlive: true)
WorkSessionLossController workSessionLoss(Ref ref) {
  final controller = WorkSessionLossController(
    () => ref.read(localWorkScopeProvider),
    () => ref.read(localWorkProvider).blocksNavigation,
  );
  ref.onDispose(controller.dispose);
  return controller;
}

/// Decides whether an operation may destroy the current local work session.
///
/// The controller reads the current scope and work state at request time. It
/// shares one confirmation between duplicate requests for the same transition
/// and rejects a different transition while that decision remains pending.
final class WorkSessionLossController {
  WorkSessionLossController(this._currentScope, this._blocksNavigation);

  final LocalWorkScope Function() _currentScope;
  final bool Function() _blocksNavigation;
  _PendingWorkSessionLoss? _pending;
  bool _closed = false;

  /// Returns the owner of the local work session at the moment of access.
  LocalWorkScope get currentScope {
    if (_closed) throw StateError("Session loss coordination is disposed");
    return _currentScope();
  }

  /// Returns whether [destination] may replace the current work scope.
  ///
  /// Forced scope loss always proceeds. Ordinary requests proceed without a
  /// dialog when the scope stays equal or no protected work exists.
  Future<bool> allowScopeLoss({
    required LocalWorkScope destination,
    required Future<bool> Function() confirm,
    bool forced = false,
  }) {
    if (_closed) return Future.value(false);
    final request = _WorkSessionLossRequest(
      source: _currentScope(),
      destination: destination,
    );
    if (forced) {
      final pending = _pending;
      _pending = null;
      pending?.invalidate();
      return Future.value(true);
    }
    if (request.preservesScope || !_blocksNavigation()) {
      return Future.value(true);
    }

    final pending = _pending;
    if (pending != null) {
      return pending.request == request ? pending.result : Future.value(false);
    }

    final created = _PendingWorkSessionLoss(request);
    _pending = created;
    unawaited(_confirm(created, confirm));
    return created.result;
  }

  /// Invalidates pending consent before the owning provider releases its Ref.
  void dispose() {
    if (_closed) return;
    _closed = true;
    final pending = _pending;
    _pending = null;
    pending?.invalidate();
  }

  Future<void> _confirm(
    _PendingWorkSessionLoss pending,
    Future<bool> Function() confirm,
  ) async {
    try {
      final confirmed = await confirm();
      pending.complete(
        !_closed && confirmed && _currentScope() == pending.request.source,
      );
    } on Object catch (error, stackTrace) {
      pending.completeError(error, stackTrace);
    } finally {
      if (identical(_pending, pending)) _pending = null;
    }
  }
}

final class _WorkSessionLossRequest {
  const _WorkSessionLossRequest({
    required this.source,
    required this.destination,
  });

  final LocalWorkScope source;
  final LocalWorkScope destination;

  bool get preservesScope => source == destination;

  @override
  bool operator ==(Object other) =>
      other is _WorkSessionLossRequest &&
      source == other.source &&
      destination == other.destination;

  @override
  int get hashCode => Object.hash(source, destination);
}

final class _PendingWorkSessionLoss {
  _PendingWorkSessionLoss(this.request);

  final _WorkSessionLossRequest request;
  final Completer<bool> _completer = Completer<bool>();
  Future<bool> get result => _completer.future;

  void invalidate() => complete(false);

  void complete(bool value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!_completer.isCompleted) _completer.completeError(error, stackTrace);
  }
}
