part of "transactional_editor_source.dart";

/// Keeps persistence separate from draft ownership and canonical reconciliation.
///
/// This boundary schedules and captures attempts. It never treats an outbound
/// request as canonical merely because it was sent. Only the commit acceptance
/// path can advance the document, and only for edits not superseded while the
/// request was awaiting its typed outcome. Uncertain outcomes remain attached
/// to the captured attempt so replay cannot accidentally target a newer draft.
extension _EditorPersistence on TransactionalEditorSource {
  void _scheduleAutoFlush() {
    if (_disposed ||
        _deleted ||
        _unresolved != null ||
        commitPolicy == EditorCommitPolicy.applyResource) {
      return;
    }
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

  /// Serializes one captured persistence attempt and resumes autosave after it
  /// settles.
  Future<TypedMutationResult> _runCommit(Set<DataPath> selected) async {
    final commit = _persist(selected);
    _activeCommit = commit;
    try {
      return await commit;
    } finally {
      _activeCommit = null;
      _notify();
      if (!_disposed && !_deleted && _states.autoFlushCandidates.isNotEmpty) {
        _scheduleAutoFlush();
      }
    }
  }

  /// Validates, captures, submits, and interprets one persistence boundary.
  ///
  /// The loop handles version conflicts by using the server's observed
  /// revision, while validation and availability failures remain typed and do
  /// not advance canonical state. The generation check prevents asynchronous
  /// results from a replaced or disposed owner from being accepted.
  Future<TypedMutationResult> _persist(Set<DataPath> paths) async {
    if (resource != null) return _persistResource(paths);

    var attempts = 0;
    var activePaths = paths;

    try {
      while (true) {
        if (_disposed) return _unavailable("Editor is disposed");
        if (_disposed || _deleted) {
          return _unavailable("The resource is no longer available");
        }
        if (document.readOnly) {
          final diagnostics = [
            _diagnostic("The resource is not ready to save"),
          ];

          _failPaths(activePaths, diagnostics);
          return TypedMutationResult.unavailable(diagnostics);
        }
        if (commitPolicy == EditorCommitPolicy.applyResource &&
            _states.hasConflicts) {
          return _unavailable("Conflicting fields require a choice");
        }

        final diagnostics = _saveDiagnostics();
        if (diagnostics.isNotEmpty) {
          _failPaths(activePaths, diagnostics);
          return TypedMutationResult.invalid(diagnostics);
        }

        activePaths = _states.flushCandidates(
          commitPolicy == EditorCommitPolicy.applyResource ? null : activePaths,
        );
        if (activePaths.isEmpty) return _settledResult();

        final generation = _generation;
        final captured = captureCommit(activePaths);
        _states.markSaving(activePaths);
        _notify();

        final result = await _send(captured);
        if (_disposed || _deleted || generation != _generation) {
          return _unavailable("The commit result is stale");
        }
        if (result is MutationUncertain) {
          _unresolved = _UnresolvedCommit(captured, result);
          return result;
        }
        acceptCommit(captured, result);

        if (result is! MutationConflict ||
            commitPolicy == EditorCommitPolicy.applyResource) {
          return result;
        }
        final retryPaths = _states.flushCandidates(activePaths);
        if (retryPaths.isEmpty) return result;
        attempts++;
        if (!await _waitForRetry(
          retryPaths,
          attempts,
          expectedVersion: result.expectedRevision,
          observedVersion: result.actualRevision,
        )) {
          return result;
        }
        activePaths = retryPaths;
      }
    } finally {
      if (!_disposed) {
        _states.clearSaving();
        _notify();
      }
    }
  }

  List<TypeDiagnostic> _saveDiagnostics() {
    return draftDiagnostics;
  }

  /// Converts transport exceptions into an uncertain typed outcome.
  ///
  /// The cause and stack trace remain available to the caller, and replay is
  /// retained only for the exact captured submission.
  Future<TypedMutationResult> _send(EditorCommit commit) async {
    try {
      return await _commit!(commit);
    } on Object catch (error, stackTrace) {
      return TypedMutationResult.uncertain(
        message: "The save result could not be confirmed",
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Repeats an uncertain submission without creating a new commit.
  ///
  /// Replay is the recovery path for an outcome that cannot establish whether
  /// the destination applied the original attempt. Its result is still subject
  /// to lifecycle checks and may remain uncertain.
  Future<TypedMutationResult> _replayCommit(
    _UnresolvedCommit unresolved,
  ) async {
    final replay = unresolved.result.replay;
    if (replay == null) return unresolved.result;
    final operation = Future<TypedMutationResult>.sync(replay);
    _activeCommit = operation;

    _notify();
    try {
      final result = await operation;
      if (_disposed || _deleted) return result;
      if (result is MutationUncertain) {
        _unresolved = _UnresolvedCommit(unresolved.commit, result);
      } else {
        _unresolved = null;
        acceptCommit(unresolved.commit, result);
      }
      return result;
    } on Object catch (error, stackTrace) {
      final result = MutationUncertain(
        message: "The save result could not be confirmed",
        cause: error,
        stackTrace: stackTrace,
        replay: replay,
        submissionId: unresolved.result.submissionId,
      );
      _unresolved = _UnresolvedCommit(unresolved.commit, result);
      return result;
    } finally {
      _activeCommit = null;
      _notify();
      _scheduleAutoFlush();
    }
  }

  Future<bool> _waitForRetry(
    Set<DataPath> paths,
    int attempts, {
    required int expectedVersion,
    required int observedVersion,
  }) async {
    if (attempts > _retryDelays.length) {
      _states.markContended(
        paths,
        EditorContentionDetails(
          kind: EditorContentionKind.versionMismatch,
          attempts: attempts,
          retryLimit: _retryDelays.length,
          paths: paths,
          expectedVersion: expectedVersion,
          observedVersion: observedVersion,
        ),
      );
      _notify();
      return false;
    }
    final base = _retryDelays[attempts - 1];
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

  /// Builds the outbound value without changing either owned state.
  ///
  /// Autosave sends selected local paths over the canonical base. Apply
  /// resource mode sends the complete draft, so its consistency boundary is
  /// the whole resource.
  DataValue _commitValue(Set<DataPath> paths) {
    if (commitPolicy == EditorCommitPolicy.applyResource) return _draft;
    var value = _document.confirmedValue;
    for (final path in paths) {
      final local = path.read(_draft).valueOrNull;
      if (local != null) {
        value = path.replace(value, local).valueOrNull ?? value;
      }
    }
    return value;
  }

  void _failPaths(Set<DataPath> paths, List<TypeDiagnostic> diagnostics) {
    _states.fail(paths, diagnostics);
    _notify();
  }

  List<_PendingStructuralMutation> _mutationsFor(Set<DataPath> paths) => [
    for (final pending in _pendingMutations)
      if (paths.any((path) => _pathsOverlap(path, pending.mutation.path)))
        pending,
  ];
}
