part of "transactional_editor_source.dart";

extension EditorCommitReconciliation on TransactionalEditorSource {
  EditorCommit previewCommit(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    final replaced = path.replace(_draft, value);
    if (replaced case TypeFailure(:final diagnostics)) {
      throw StateError(diagnostics.map((item) => item.message).join("; "));
    }
    final paths = {...editedPaths, path};
    final current = captureCommit(paths);
    return EditorCommit(
      expectedRevision: current.expectedRevision,
      localRevision: current.localRevision,
      rootValue: replaced.valueOrNull!,
      baseValue: current.baseValue,
      changedPaths: current.changedPaths,
      mutations: [
        ...current.mutations,
        structuralMutation ?? EditorSetValue(path, value),
      ],
    );
  }

  /// Captures immutable intent. Delivery and later edits cannot change it.
  EditorCommit captureCommit(Set<DataPath> paths) => EditorCommit(
    expectedRevision: document.revision,
    localRevision: _localRevision,
    rootValue: _commitValue(paths),
    baseValue: document.confirmedValue,
    changedPaths: Set.unmodifiable(paths),
    mutations: List.unmodifiable(
      _mutationsFor(paths).map((pending) => pending.mutation),
    ),
  );

  /// Integrates a known outcome against the captured edit revision.
  /// Acknowledging an older save must preserve later local and remote changes.
  void acceptCommit(EditorCommit commit, TypedMutationResult result) {
    if (_disposed || _deleted) return;
    _states.clearSaving();
    switch (result) {
      case MutationSuccess(:final revision, :final value):
        if (revision == document.revision && value != document.confirmedValue) {
          acceptRemote(revision: revision, value: value);
          _failPaths(commit.changedPaths, [
            _diagnostic("Different values share the same revision"),
          ]);
          return;
        }
        _acceptSuccess(
          revision < document.revision ? document.revision : revision,
          revision < document.revision ? document.confirmedValue : value,
          commit.rootValue,
          commit.changedPaths,
          commit.localRevision,
        );
        _pendingMutations.removeWhere(
          (pending) =>
              pending.revision <= commit.localRevision &&
              commit.changedPaths.any(
                (path) => _pathsOverlap(path, pending.mutation.path),
              ),
        );
      case MutationConflict(:final actualRevision, :final actualValue):
        acceptRemote(revision: actualRevision, value: actualValue);
        _states.fail(_states.flushCandidates(commit.changedPaths), [
          _diagnostic("The resource changed elsewhere"),
        ]);
      case MutationInvalid(:final diagnostics) ||
          MutationUnavailable(:final diagnostics):
        if (_targetWasDeleted(diagnostics)) {
          acceptRemoteDeletion();
          return;
        }
        _failPaths(commit.changedPaths, diagnostics);
      case MutationPermissionDenied(:final message):
        _failPaths(commit.changedPaths, [_diagnostic(message)]);
      case MutationUncertain():
        return;
    }
    _notify();
  }
}
