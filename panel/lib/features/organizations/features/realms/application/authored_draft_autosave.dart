part of "authoring_session.dart";

final class AuthoredDraftAutosave extends ChangeNotifier {
  AuthoredDraftAutosave({
    required this.resource,
    required AuthoredDraft baseline,
    required this.policy,
    required this._commit,
    required this._awaitSnapshot,
    required this._currentRecoveryRevision,
    required this._reload,
    required this._onSettled,
  }) : _draft = baseline.fork();

  static const debounce = Duration(milliseconds: 250);

  final skir.ResourceId resource;
  final EditorCommitPolicy policy;
  final Future<skir.CommitPreparedEditResponse> Function(skir.PreparedEdit edit)
  _commit;
  final Future<skir.AuthoringSnapshot> Function(
    skir.SnapshotId snapshot,
    int sinceRecovery,
  )
  _awaitSnapshot;
  final int Function() _currentRecoveryRevision;
  final Future<void> Function() _reload;
  final VoidCallback _onSettled;

  AuthoredDraft _draft;
  Timer? _debounce;
  _AuthoredSaveBatch? _pending;
  AuthoredDraft? _pendingBaseline;
  AuthoredDraft? _latestBaseline;
  Future<void>? _active;
  String? _status;
  bool _blocked = false;
  bool _detached = false;
  bool _flushRequested = false;
  bool _closed = false;
  bool _acceptedPrefixNeedsRecovery = false;

  AuthoredDraft get draft => _draft;
  String? get status => _status;
  bool get blocked => _blocked;
  bool get saving => _active != null;
  bool get detached => _detached;
  bool get dirty => _draft.intents.isNotEmpty;
  bool get canRetry => _blocked && _pending != null;
  bool get canUseLatest => _blocked && _pending == null;
  bool get settled => !dirty && _pending == null && _active == null;

  void attach() {
    _detached = false;
  }

  void detach() {
    _detached = true;
    if (policy == EditorCommitPolicy.autosaveChanges && dirty && !_blocked) {
      flush();
    }
    _releaseIfSettled();
  }

  void stage(AuthoredDraft draft) {
    if (_closed) return;
    _draft = draft;
    if (!_acceptedPrefixNeedsRecovery) {
      _status = null;
      if (_blocked && _pending == null) _blocked = false;
    }
    _notify();
    if (policy == EditorCommitPolicy.autosaveChanges) schedule();
  }

  void acceptBaseline(AuthoredDraft baseline) {
    if (_closed ||
        (baseline.snapshot == _draft.snapshot &&
            baseline.generation == _draft.generation)) {
      return;
    }
    _latestBaseline = baseline;
    if (_active != null || _acceptedPrefixNeedsRecovery) {
      _pendingBaseline = baseline;
      return;
    }
    _adoptBaseline(baseline);
  }

  void schedule() {
    if (_closed || _blocked || !dirty) return;
    _debounce?.cancel();
    _debounce = Timer(debounce, flush);
  }

  Future<void> flush() {
    if (_closed || _blocked || !dirty) return Future.value();
    _debounce?.cancel();
    _debounce = null;
    _flushRequested = true;
    final active = _active;
    if (active != null) return active;
    late final Future<void> operation;
    operation = _drain().whenComplete(() {
      if (identical(_active, operation)) _active = null;
      _notify();
      if (_flushRequested && !_blocked && dirty) {
        flush();
      } else {
        _releaseIfSettled();
      }
    });
    _active = operation;
    _notify();
    return operation;
  }

  Future<void> retry() {
    if (_pending == null) return Future.value();
    _blocked = false;
    _status = null;
    return flush();
  }

  Future<void> useLatest() async {
    if (!canUseLatest) return;
    if (_latestBaseline == null) await _reload();
    final latest = _latestBaseline;
    if (latest == null) {
      _status = "The latest Realm value is not available yet";
      _notify();
      return;
    }
    _debounce?.cancel();
    _debounce = null;
    _pending = null;
    _pendingBaseline = null;
    _draft = latest.fork();
    _blocked = false;
    _acceptedPrefixNeedsRecovery = false;
    _status = "Local changes discarded. Using the latest Realm value";
    _notify();
    _releaseIfSettled();
  }

  void reportStatus(String message) {
    _status = message;
    _notify();
  }

  void discard(AuthoredDraft baseline) {
    _debounce?.cancel();
    _debounce = null;
    _pending = null;
    _pendingBaseline = null;
    _latestBaseline = baseline;
    _draft = baseline.fork();
    _blocked = false;
    _acceptedPrefixNeedsRecovery = false;
    _status = "Local edits discarded";
    _notify();
    _releaseIfSettled();
  }

  Future<void> _drain() async {
    while (_flushRequested && !_blocked && dirty && !_closed) {
      _flushRequested = false;
      await _saveBatch();
    }
  }

  Future<void> _saveBatch() async {
    final batch = _pending ??= _AuthoredSaveBatch(
      prepared: _draft.prepare(skir.BatchId(value: "panel:${uuid.v4()}")),
      acceptedIntentCount: _draft.intents.length,
      recoveryRevision: _currentRecoveryRevision(),
    );
    _status = "Saving";
    _notify();
    try {
      final response = await _commit(batch.prepared);
      switch (response) {
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_committedWrapper(:final value),
        ):
          await _acceptCommitted(batch, value.snapshot, value.changed);
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_conflictWrapper(),
        ):
          _pending = null;
          _blocked = true;
          _status = "The resource changed before this edit was saved";
          await _reload();
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_rejectedWrapper(),
        ):
          _pending = null;
          _blocked = true;
          _status = response.rejectionMessage;
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_catalogChangedWrapper(),
        ):
          _pending = null;
          _blocked = true;
          _status = "The editor catalog changed";
          await _reload();
        default:
          _blocked = true;
          _status = "The save result is unavailable. Retry the same edit";
      }
    } on Object {
      _blocked = true;
      _status = "The save did not complete. Retry the same edit";
    } finally {
      _applyPendingBaseline();
      _notify();
    }
  }

  Future<void> _acceptCommitted(
    _AuthoredSaveBatch batch,
    skir.SnapshotId snapshot,
    Iterable<skir.InputIdentity> changed,
  ) async {
    try {
      final adopted = await _awaitSnapshot(snapshot, batch.recoveryRevision);
      final baseline = AuthoredDraft.fromSnapshot(
        adopted,
        catalog: _draft.catalog,
      );
      switch (_draft.rebaseTailOnto(
        baseline,
        acceptedIntentCount: batch.acceptedIntentCount,
        acceptedChanges: changed,
      )) {
        case AuthoredDraftRebased(:final draft):
          _draft = draft;
          _pending = null;
          _blocked = false;
          _acceptedPrefixNeedsRecovery = false;
          _status = dirty ? "Saved. More changes are pending" : "Saved";
        case AuthoredDraftRebaseFailed(:final message):
          _pending = null;
          _blocked = true;
          _status =
              "The saved edit was accepted, but later changes need attention: $message";
        case AuthoredDraftRebaseConflict():
          _pending = null;
          _blocked = true;
          _status = "The saved edit was accepted, but later changes conflict with the adopted value";
      }
    } on Object {
      _pending = null;
      _blocked = true;
      _acceptedPrefixNeedsRecovery = true;
      _status = "The edit was saved, but its exact adopted snapshot is unavailable. Later changes remain local";
    }
    if (!_blocked && dirty && policy == EditorCommitPolicy.autosaveChanges) {
      schedule();
    }
  }

  void _applyPendingBaseline() {
    final pendingBaseline = _pendingBaseline;
    _pendingBaseline = null;
    if (pendingBaseline != null &&
        !_acceptedPrefixNeedsRecovery &&
        _pending == null) {
      _adoptBaseline(pendingBaseline);
    }
  }

  void _adoptBaseline(AuthoredDraft baseline) {
    if (!dirty) {
      _draft = baseline.fork();
      _pending = null;
      _blocked = false;
      _acceptedPrefixNeedsRecovery = false;
      _status = null;
      _notify();
      return;
    }
    switch (_draft.rebaseOnto(baseline)) {
      case AuthoredDraftRebased(:final draft):
        _draft = draft;
        _pending = null;
        _blocked = false;
        _acceptedPrefixNeedsRecovery = false;
        _status = "The Realm changed. Your local edits remain";
        if (policy == EditorCommitPolicy.autosaveChanges) schedule();
      case AuthoredDraftRebaseFailed(:final message):
        _pending = null;
        _blocked = true;
        _status = "The Realm changed and this edit needs attention: $message";
      case AuthoredDraftRebaseConflict():
        _pending = null;
        _blocked = true;
        _status = "The resource changed in the Realm. Your conflicting local edit remains available";
    }
    _notify();
  }

  void _releaseIfSettled() {
    if (_detached && settled) _onSettled();
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _debounce?.cancel();
    _debounce = null;
    super.dispose();
  }
}

final class _AuthoredSaveBatch {
  const _AuthoredSaveBatch({
    required this.prepared,
    required this.acceptedIntentCount,
    required this.recoveryRevision,
  });

  final skir.PreparedEdit prepared;
  final int acceptedIntentCount;
  final int recoveryRevision;
}
