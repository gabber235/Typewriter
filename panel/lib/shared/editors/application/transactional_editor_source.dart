import "dart:async";

import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

typedef EditorCommitter =
    Future<TypedMutationResult> Function(EditorCommit commit);
typedef EditorMutationValidator =
    EditorMutationResult Function(DataPath path, DataValue value);
typedef EditorRealmActionExecutor =
    Future<TypedMutationResult> Function(
      RealmAction action,
      ExpressionContext context,
    );

final class TransactionalEditorSource extends ChangeNotifier
    implements EditorSource {
  TransactionalEditorSource({
    required EditorDocument document,
    required EditorCommitter commit,
    EditorMutationValidator? validate,
    EditorRealmActionExecutor? executeRealmAction,
    EditorDelayScheduler scheduler = const TimerEditorDelayScheduler(),
    EditorJitterSource? jitter,
    this.debounce = const Duration(milliseconds: 250),
    this.successfulSavePhase = EditorSavePhase.saved,
    this.onDeleted,
  }) : _document = document,
       _draft = document.confirmedValue,
       _commit = commit,
       _validate = validate,
       _executeRealmAction = executeRealmAction,
       _scheduler = scheduler,
       _jitter = jitter ?? RandomEditorJitterSource();

  EditorDocument _document;
  DataValue _draft;
  final EditorCommitter _commit;
  final EditorMutationValidator? _validate;
  final EditorRealmActionExecutor? _executeRealmAction;
  final EditorDelayScheduler _scheduler;
  final EditorJitterSource _jitter;
  final Duration debounce;
  final EditorSavePhase successfulSavePhase;
  final VoidCallback? onDeleted;
  final EditorReconciler _reconciler = const EditorReconciler();
  final EditorPathStates _states = EditorPathStates();
  EditorScheduledTask? _debounceTask;
  EditorScheduledTask? _retryTask;
  Future<TypedMutationResult>? _activeCommit;
  bool _deleted = false;
  bool _disposed = false;
  int _localRevision = 0;
  int _generation = 0;

  @override
  EditorDocument get document => _document;

  @override
  EditorValue value(DataPath path) {
    if (_deleted) {
      return EditorValue.invalid([_diagnostic("Deleted elsewhere", path)]);
    }
    return _draft.readEditorValue(path);
  }

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    if (_disposed) {
      return EditorMutationResult.invalid([_diagnostic("Editor is disposed")]);
    }
    if (_deleted) return EditorMutationResult.invalid([_deletedDiagnostic()]);
    if (_document.readOnly) {
      return EditorMutationResult.invalid([
        _diagnostic("The editor is read only", path),
      ]);
    }
    final validation =
        _validate?.call(path, value) ??
        _document.rootType.validateEditorMutation(
          path,
          value,
          registry: TypeRegistry(_document.typeCatalog),
        );
    if (validation is! AppliedEditorMutation) return validation;
    final replaced = path.replace(_draft, validation.value);
    if (replaced case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    _draft = replaced.valueOrNull!;
    _localRevision++;
    _states.markEdited(path);
    _notify();
    _scheduleAutoFlush();
    return validation;
  }

  @override
  void refreshDocument(EditorDocument document) {
    if (_disposed) return;
    if (_document.hasSameContent(document)) return;
    acceptRemote(revision: document.revision, value: document.confirmedValue);
    final refreshed = _document.copyWith(
      rootType: document.rootType,
      typeCatalog: document.typeCatalog,
      presentations: document.presentations,
      collections: document.collections,
      mergePolicies: document.mergePolicies,
      commitGroups: document.commitGroups,
      rootPresentation: document.rootPresentation,
      clearRootPresentation: document.rootPresentation == null,
      diagnostics: document.diagnostics,
      readOnly: document.readOnly,
    );
    if (_document.hasSameContent(refreshed)) return;
    _document = refreshed;
    _notify();
  }

  @override
  EditorInteractionSession beginInteraction(DataPath path) {
    final existing = _states.gate(path);
    if (existing is _Interaction && existing.active) return existing;
    final interaction = _Interaction(
      source: this,
      path: path,
      origin: path.read(_draft).valueOrNull,
    );
    if (_disposed || _deleted) {
      interaction.close();
      return interaction;
    }
    _states.setGate(path, interaction);
    return interaction;
  }

  @override
  EditorSaveState saveState(DataPath path) {
    if (_deleted) {
      return EditorSaveState(
        phase: EditorSavePhase.deletedElsewhere,
        path: path,
      );
    }
    return _states.saveState(path);
  }

  @override
  Future<TypedMutationResult> flush({Set<DataPath>? paths}) async {
    if (_disposed) return _unavailable("Editor is disposed");
    if (_deleted) return _unavailable("Deleted elsewhere");

    var result = _settledResult();
    final processedGroups = <String?>{};
    while (true) {
      while (_activeCommit != null) {
        result = await _activeCommit!;
        if (_disposed) return _unavailable("Editor is disposed");
        if (_deleted) return _unavailable("Deleted elsewhere");
      }

      final selected = _states
          .flushCandidates(paths)
          .where((path) => !processedGroups.contains(_commitGroupFor(path)))
          .toSet();
      if (selected.isEmpty) return result;
      final commitPaths = _firstCommitGroup(selected);
      processedGroups.add(_commitGroupFor(commitPaths.first));
      result = await _runCommit(commitPaths);
      if (_disposed) return _unavailable("Editor is disposed");
      if (_deleted) {
        return result is MutationConflict
            ? result
            : _unavailable("Deleted elsewhere");
      }
      if (result is! MutationSuccess) return result;
    }
  }

  Set<DataPath> _firstCommitGroup(Set<DataPath> paths) {
    final ordered = paths.toList()
      ..sort((left, right) => left.toString().compareTo(right.toString()));
    final group = _commitGroupFor(ordered.first);
    return {
      for (final path in ordered)
        if (_commitGroupFor(path) == group) path,
    };
  }

  String? _commitGroupFor(DataPath path) {
    MapEntry<DataPath, String>? closest;
    for (final entry in _document.commitGroups.entries) {
      if (!path.isAtOrBelow(entry.key)) continue;
      if (closest == null ||
          entry.key.segments.length > closest.key.segments.length) {
        closest = entry;
      }
    }
    return closest?.value;
  }

  TypedMutationResult _settledResult() {
    if (_states.hasConflicts) {
      return _unavailable("Conflicting fields require a choice");
    }
    return TypedMutationResult.success(
      revision: _document.revision,
      value: _document.confirmedValue,
    );
  }

  Future<TypedMutationResult> _runCommit(Set<DataPath> selected) async {
    final commit = _persist(selected);
    _activeCommit = commit;
    try {
      return await commit;
    } finally {
      _activeCommit = null;
      if (!_disposed && !_deleted && _states.autoFlushCandidates.isNotEmpty) {
        _scheduleAutoFlush();
      }
    }
  }

  Future<TypedMutationResult> _persist(Set<DataPath> paths) async {
    var attempt = 0;
    var activePaths = paths;
    try {
      while (true) {
        if (_disposed) return _unavailable("Editor is disposed");
        final generation = _generation;
        final rootValue = _commitValue(activePaths);
        _states.markSaving(activePaths);
        _notify();
        final result = await _commit(
          EditorCommit(
            expectedRevision: _document.revision,
            localRevision: _localRevision,
            rootValue: rootValue,
            changedPaths: activePaths,
            group: _commitGroupFor(activePaths.first),
          ),
        );
        if (_disposed || _deleted || generation != _generation) {
          return _unavailable("The commit result is stale");
        }
        switch (result) {
          case MutationSuccess(:final revision, :final value):
            if (revision < _document.revision) {
              final retryPaths = _states.flushCandidates(activePaths);
              if (retryPaths.isEmpty) return result;
              if (!await _waitForRetry(retryPaths, attempt++)) return result;
              activePaths = retryPaths;
              continue;
            }
            if (revision == _document.revision &&
                value != _document.confirmedValue) {
              acceptRemote(revision: revision, value: value);
              _failPaths(activePaths, [
                _diagnostic("Different values share the same revision"),
              ]);
              return result;
            }
            _acceptSuccess(revision, value, rootValue, activePaths);
            return result;
          case MutationConflict(:final actualRevision, :final actualValue):
            acceptRemote(revision: actualRevision, value: actualValue);
            final retryPaths = _states.flushCandidates(activePaths);
            if (retryPaths.isEmpty) return result;
            if (!await _waitForRetry(retryPaths, attempt++)) return result;
            activePaths = retryPaths;
          case MutationInvalid(:final diagnostics) ||
              MutationUnavailable(:final diagnostics):
            if (_targetWasDeleted(diagnostics)) {
              acceptRemoteDeletion();
              return result;
            }
            _failPaths(activePaths, diagnostics);
            return result;
          case MutationPermissionDenied(:final message):
            _failPaths(activePaths, [_diagnostic(message)]);
            return result;
        }
      }
    } finally {
      if (!_disposed) {
        _states.clearSaving();
        _notify();
      }
    }
  }

  Future<bool> _waitForRetry(Set<DataPath> paths, int attempt) async {
    if (attempt >= _retryDelays.length) {
      _states.markContended(paths);
      _notify();
      return false;
    }
    final base = _retryDelays[attempt];
    final jitter = _jitter.next(
      Duration(microseconds: base.inMicroseconds ~/ 2),
    );
    final task = _scheduler.schedule(base + jitter);
    _retryTask?.cancel();
    _retryTask = task;
    final completion = await task.completed;
    if (identical(_retryTask, task)) _retryTask = null;
    return completion == EditorTaskCompletion.executed &&
        !_disposed &&
        !_deleted;
  }

  DataValue _commitValue(Set<DataPath> paths) {
    var value = _document.confirmedValue;
    for (final path in paths) {
      final local = path.read(_draft).valueOrNull;
      if (local != null) {
        value = path.replace(value, local).valueOrNull ?? value;
      }
    }
    return value;
  }

  void _acceptSuccess(
    int revision,
    DataValue value,
    DataValue sent,
    Set<DataPath> committed,
  ) {
    var nextDraft = value;
    final confirmed = <DataPath>{};
    for (final path in _states.dirtyPaths) {
      final local = path.read(_draft).valueOrNull;
      if (committed.contains(path) && local == path.read(sent).valueOrNull) {
        confirmed.add(path);
        continue;
      }
      if (local != null) {
        nextDraft = path.replace(nextDraft, local).valueOrNull ?? nextDraft;
      }
    }
    _states.confirm(confirmed, successfulSavePhase);
    _document = _document.copyWith(confirmedValue: value, revision: revision);
    _draft = nextDraft;
    _notify();
  }

  void _failPaths(Set<DataPath> paths, List<TypeDiagnostic> diagnostics) {
    _states.fail(paths, diagnostics);
    _notify();
  }

  @override
  Future<TypedMutationResult> executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async {
    if (_disposed) return _unavailable("Editor is disposed");
    final result = switch (action) {
      LocalEditorAction() =>
        action
            .canonicalizedWith(aliases)
            .execute(context, registry: TypeRegistry(_document.typeCatalog)),
      RealmEditorAction(:final action) => await _executeRealm(action, context),
    };
    return result;
  }

  Future<TypedMutationResult> _executeRealm(
    RealmAction action,
    ExpressionContext context,
  ) async {
    final executor = _executeRealmAction;
    if (executor == null) return _unavailable("Realm actions are unavailable");
    return executor(action, context);
  }

  @override
  void acceptRemote({required int revision, required DataValue value}) {
    if (_disposed || _deleted || revision < _document.revision) return;
    if (revision == _document.revision) {
      if (value == _document.confirmedValue) return;
      _document = _document.copyWith(
        diagnostics: [
          ..._document.diagnostics,
          _diagnostic("Different values share the same revision"),
        ],
      );
      _notify();
      return;
    }
    final result = _reconciler.reconcile(
      base: _document.confirmedValue,
      local: _draft,
      remote: value,
      remoteRevision: revision,
      dirtyPaths: _states.dirtyPaths,
      mergePolicies: _document.mergePolicies,
    );
    _document = _document.copyWith(
      confirmedValue: result.base,
      revision: result.revision,
      diagnostics: [..._document.diagnostics, ...result.diagnostics],
    );
    _draft = result.draft;
    _states.applyReconciliation(
      dirtyPaths: result.dirtyPaths,
      confirmedPaths: result.confirmedPaths,
      conflicts: result.conflicts,
      confirmedPhase: successfulSavePhase,
    );
    _notify();
  }

  @override
  void useRemote(DataPath path) {
    if (_disposed) return;
    final remote = path.read(_document.confirmedValue).valueOrNull;
    if (remote == null) return;
    _draft = path.replace(_draft, remote).valueOrNull ?? _draft;
    _states.adoptRemote(path, EditorSavePhase.saved);
    _notify();
  }

  @override
  Future<TypedMutationResult> keepLocal(DataPath path) {
    if (_disposed) return Future.value(_unavailable("Editor is disposed"));
    _states.resolveConflictLocally(path);
    _notify();
    return flush(paths: {path});
  }

  @override
  void acceptRemoteDeletion() {
    if (_disposed || _deleted) return;
    _deleted = true;
    _generation++;
    _cancelScheduledTasks();
    _closeGates();
    _notify();
    onDeleted?.call();
  }

  void _scheduleAutoFlush() {
    if (_disposed || _deleted) return;
    _cancelDebounce();
    final task = _scheduler.schedule(debounce);
    _debounceTask = task;
    unawaited(_autoFlushAfter(task));
  }

  Future<void> _autoFlushAfter(EditorScheduledTask task) async {
    final completion = await task.completed;
    if (!identical(_debounceTask, task)) return;
    _debounceTask = null;
    if (completion == EditorTaskCompletion.cancelled || _disposed || _deleted) {
      return;
    }
    final candidates = _states.autoFlushCandidates;
    if (candidates.isEmpty) return;
    await flush(paths: candidates);
  }

  void _cancelDebounce() {
    _debounceTask?.cancel();
    _debounceTask = null;
  }

  void _cancelScheduledTasks() {
    _cancelDebounce();
    _retryTask?.cancel();
    _retryTask = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<TypedMutationResult> _commitInteraction(_Interaction interaction) {
    if (!_release(interaction)) {
      return Future.value(_unavailable("Interaction is closed"));
    }
    return flush(paths: {..._states.autoFlushCandidates, interaction.path});
  }

  void _cancelInteraction(_Interaction interaction) {
    if (!_release(interaction)) return;
    if (_disposed || _deleted) return;
    final origin = interaction.origin;
    if (origin != null) {
      _draft = interaction.path.replace(_draft, origin).valueOrNull ?? _draft;
    }
    _states.reset(interaction.path);
    _notify();
  }

  bool _release(_Interaction interaction) {
    if (!interaction.active) return false;
    interaction.close();
    _states.clearGate(interaction.path, interaction);
    return true;
  }

  void _closeGates() {
    for (final gate in _states.takeGates()) {
      if (gate is _Interaction) gate.close();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _cancelScheduledTasks();
    _closeGates();
    super.dispose();
  }
}

final class _Interaction implements EditorInteractionSession {
  _Interaction({
    required this.source,
    required this.path,
    required this.origin,
  });

  final TransactionalEditorSource source;
  @override
  final DataPath path;
  final DataValue? origin;
  @override
  bool active = true;

  @override
  Future<TypedMutationResult> commit() => source._commitInteraction(this);

  @override
  void cancel() => source._cancelInteraction(this);

  void close() => active = false;
}

TypeDiagnostic _diagnostic(String message, [DataPath path = DataPath.root]) {
  return TypeDiagnostic(
    code: TypeDiagnosticCode.mutationConflict,
    message: message,
    path: path,
  );
}

TypeDiagnostic _deletedDiagnostic() => _diagnostic("Deleted elsewhere");

TypedMutationResult _unavailable(String message) =>
    TypedMutationResult.unavailable([_diagnostic(message)]);

bool _targetWasDeleted(List<TypeDiagnostic> diagnostics) {
  return diagnostics.any(
    (diagnostic) => diagnostic.details.any(
      (detail) => detail.key == "editor.target" && detail.value == "deleted",
    ),
  );
}

const _retryDelays = [
  Duration(milliseconds: 50),
  Duration(milliseconds: 100),
  Duration(milliseconds: 200),
];
