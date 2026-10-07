part of "authoring_session.dart";

final class AuthoredDraftAutosave extends ChangeNotifier {
  AuthoredDraftAutosave({
    required this.resource,
    required AuthoredDraft baseline,
    required this.policy,
    required this._commit,
    required this._fetchCurrent,
    required this._reload,
    required this._onSettled,
  }) : _draft = baseline.fork();

  static const debounce = Duration(milliseconds: 250);

  final skir.ResourceId resource;
  final EditorCommitPolicy policy;
  final Future<skir.CommitPreparedEditResponse> Function(skir.PreparedEdit edit)
  _commit;
  final Future<skir.AuthoringState> Function() _fetchCurrent;
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
  int? _savedPrefix;
  bool _uncertain = false;

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
    if (_savedPrefix == null && !_uncertain) {
      _status = null;
      if (_blocked && _pending == null) _blocked = false;
    }
    _notify();
    if (policy == EditorCommitPolicy.autosaveChanges) schedule();
  }

  void acceptBaseline(AuthoredDraft baseline) {
    if (_closed) return;
    _latestBaseline = baseline;
    if (_active != null || _uncertain) {
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
    _savedPrefix = null;
    _uncertain = false;
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
    _savedPrefix = null;
    _uncertain = false;
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
      prepared: _draft.prepare(),
      acceptedIntentCount: _draft.intents.length,
    );
    _status = "Saving";
    _notify();
    try {
      final response = await _commit(batch.prepared);
      switch (response) {
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult.committed,
        ):
          await _acceptCommitted(batch);
        case skir.CommitPreparedEditResponse_resultWrapper(
          value: skir.CommitResult_conflictWrapper(),
        ):
          _pending = null;
          _blocked = true;
          _status = "The resource changed before this edit was saved";
          await _refreshAfterRejection();
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
          await _refreshAfterRejection();
        default:
          _pending = null;
          _blocked = true;
          _uncertain = true;
          _status = "The save result is unknown. Fetching current Realm values. Your local edit remains available";
          await _reload();
      }
    } on Object {
      _pending = null;
      _blocked = true;
      _uncertain = true;
      _status = "The save result is unknown. Your local edit remains available for comparison with current Realm values";
      try {
        await _reload();
      } on Object {}
    } finally {
      _applyPendingBaseline();
      _notify();
    }
  }

  Future<void> _acceptCommitted(_AuthoredSaveBatch batch) async {
    try {
      final adopted = await _fetchCurrent();
      final baseline = AuthoredDraft.fromState(
        adopted,
        catalog: _draft.catalog,
      );
      _adoptSavedBaseline(baseline, batch.acceptedIntentCount);
    } on Object {
      _pending = null;
      _blocked = true;
      _savedPrefix = batch.acceptedIntentCount;
      _status = "The edit was saved, but current Realm values are unavailable. Later changes remain local";
    }
    if (!_blocked && dirty && policy == EditorCommitPolicy.autosaveChanges) {
      schedule();
    }
  }

  Future<void> _refreshAfterRejection() async {
    try {
      await _reload();
    } on Object {
      _status = "$_status. Current Realm values are unavailable";
    }
  }

  void _adoptSavedBaseline(AuthoredDraft baseline, int acceptedIntentCount) {
    _savedPrefix = acceptedIntentCount;
    switch (_draft.rebaseTailOnto(
      baseline,
      acceptedIntentCount: acceptedIntentCount,
    )) {
      case AuthoredDraftRebased(:final draft):
        _draft = draft;
        _pending = null;
        _blocked = false;
        _savedPrefix = null;
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
    _notify();
  }

  void _applyPendingBaseline() {
    final pendingBaseline = _pendingBaseline;
    _pendingBaseline = null;
    if (pendingBaseline != null && !_uncertain && _pending == null) {
      _adoptBaseline(pendingBaseline);
    }
  }

  void _adoptBaseline(AuthoredDraft baseline) {
    if (_savedPrefix case final acceptedIntentCount?) {
      _adoptSavedBaseline(baseline, acceptedIntentCount);
      if (!_blocked && dirty && policy == EditorCommitPolicy.autosaveChanges)
        schedule();
      return;
    }
    if (!dirty) {
      _draft = baseline.fork();
      _pending = null;
      _blocked = false;
      _savedPrefix = null;
      _status = null;
      _notify();
      return;
    }
    switch (_draft.rebaseOnto(baseline)) {
      case AuthoredDraftRebased(:final draft):
        _draft = draft;
        _pending = null;
        _blocked = false;
        _savedPrefix = null;
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
  });

  final skir.PreparedEdit prepared;
  final int acceptedIntentCount;
}
