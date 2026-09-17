part of "transactional_editor_source.dart";

/// Persists the captured commits as one caller visible batch operation.
///
/// The sender must return one typed outcome per participating source. A
/// missing outcome is treated as unavailable, and an exception is represented
/// as uncertain because the destination may have accepted the request.
typedef EditorBatchSender =
    Future<Map<TransactionalEditorSource, TypedMutationResult>> Function(
      Map<TransactionalEditorSource, EditorCommit> commits,
    );

/// Coordinates one captured save across multiple editor sources.
///
/// A batch owns the commit set and its outcomes, then settles each source with
/// only the mutations represented by that commit. Resource backed sources are
/// prepared under one workspace reservation, while local sources use the
/// supplied sender. This keeps multi editor saves consistent and leaves
/// uncertain outcomes recoverable instead of treating them as ordinary
/// failures.
final class EditorBatch {
  EditorBatch._(
    this._commits,
    this._send, {
    Map<TransactionalEditorSource, Set<DataPath>>? paths,
  }) : _paths =
           paths ??
           {
             for (final entry in _commits.entries)
               entry.key: entry.value.changedPaths.toSet(),
           };
  final EditorBatchSender? _send;
  final Map<TransactionalEditorSource, EditorCommit> _commits;
  final Map<TransactionalEditorSource, Set<DataPath>> _paths;
  Map<TransactionalEditorSource, TypedMutationResult> _results = {};
  Future<Map<TransactionalEditorSource, TypedMutationResult>>? _recovery;

  /// Validates, captures, and submits changes for all participating sources.
  ///
  /// Sources with an active save are awaited first. Every input path must be
  /// non empty and disjoint within its source. The returned map contains one
  /// outcome per input source; invalid input is returned without changing any
  /// draft. Accepted changes are published before resource refresh begins, so
  /// projected consumers observe them immediately. An unconfirmable submission
  /// returns [MutationUncertain].
  static Future<Map<TransactionalEditorSource, TypedMutationResult>> submit({
    required Map<TransactionalEditorSource, Map<DataPath, DataValue>> changes,
    EditorBatchSender? send,
  }) async {
    while (changes.keys.any((source) => source._activeCommit != null)) {
      await Future.wait([
        for (final source in changes.keys) ?source._activeCommit,
      ]);
    }
    final resourceBatch = changes.keys.any((source) => source.resource != null);
    if (resourceBatch &&
        changes.keys.any((source) => source.resource == null)) {
      throw StateError(
        "A resource transaction cannot include local editor callbacks",
      );
    }
    if (!resourceBatch && send == null) {
      throw StateError("A local editor batch requires a sender");
    }

    final invalid = <TypeDiagnostic>[];

    final accepted = <TransactionalEditorSource, Map<DataPath, DataValue>>{};
    for (final entry in changes.entries) {
      if (entry.value.isEmpty ||
          entry.value.keys.any(
            (path) => entry.value.keys.any(
              (other) => path != other && _pathsOverlap(path, other),
            ),
          )) {
        invalid.add(_diagnostic("Batch paths must be present and disjoint"));
      }
      if (entry.key._unresolved != null || entry.key._states.hasConflicts) {
        return {
          for (final source in changes.keys)
            source: _unavailable(
              "Resolve the previous save before changing this batch",
            ),
        };
      }
      accepted[entry.key] = {};
      for (final change in entry.value.entries) {
        final result = entry.key.validate(change.key, change.value);
        if (result is AppliedEditorMutation) {
          accepted[entry.key]![change.key] = result.value;
        } else {
          invalid.addAll(
            result is InvalidEditorMutation
                ? result.diagnostics
                : [_diagnostic("The edit conflicts")],
          );
        }
      }
    }
    if (invalid.isNotEmpty) {
      return {
        for (final source in changes.keys)
          source: TypedMutationResult.invalid(invalid),
      };
    }
    final completions = {
      for (final source in changes.keys)
        source: Completer<TypedMutationResult>(),
    };
    for (final source in changes.keys) {
      source._activeCommit = completions[source]!.future;
      source._cancelScheduledTasks();
    }

    final commits = <TransactionalEditorSource, EditorCommit>{};
    for (final entry in changes.entries) {
      final source = entry.key;
      for (final change in accepted[source]!.entries) {
        source._draft = change.key
            .replace(source._draft, change.value)
            .valueOrNull!;
        source._localRevision++;
        source._pendingMutations.add(
          _PendingStructuralMutation(
            source._localRevision,
            EditorSetValue(change.key, change.value),
          ),
        );
        source._states.markEdited(change.key);
      }
    }
    if (resourceBatch) {
      for (final source in changes.keys) {
        source._notify();
      }
      return _flushPreparedClaimed(
        {
          for (final entry in changes.entries)
            entry.key: entry.value.keys.toSet(),
        },
        completions,
        send: send,
      );
    }
    for (final entry in changes.entries) {
      final source = entry.key;
      final paths = source._states.flushCandidates(entry.value.keys.toSet());
      if (paths.isEmpty) continue;
      commits[source] = source.captureCommit(paths);

      source._states.markSaving(paths);
      source._notify();
    }

    final batch = EditorBatch._(Map.unmodifiable(commits), send);
    try {
      batch._results = commits.isEmpty ? {} : await send!(batch._commits);
    } on Object catch (error, stackTrace) {
      batch._results = {
        for (final source in changes.keys)
          source: TypedMutationResult.uncertain(
            message: "The batch result could not be confirmed",
            cause: error,
            stackTrace: stackTrace,
          ),
      };
    }

    batch._settle();
    for (final source in changes.keys) {
      source._activeCommit = null;
      completions[source]!.complete(
        batch._results[source] ?? source._settledResult(),
      );
      source
        .._notify()
        .._scheduleAutoFlush();
    }
    return {
      for (final source in changes.keys)
        source: batch._results[source] ?? source._settledResult(),
    };
  }

  static Future<Map<TransactionalEditorSource, TypedMutationResult>>
  _flushPrepared(
    Map<TransactionalEditorSource, Set<DataPath>> paths, {
    EditorBatchSender? send,
  }) async {
    final resourceBatch = _validatePreparedPaths(paths, send: send);
    while (paths.keys.any((source) => source._activeCommit != null)) {
      await Future.wait([
        for (final source in paths.keys) ?source._activeCommit,
      ]);
    }
    final completions = _claim(paths.keys);
    return resourceBatch
        ? _flushPreparedClaimed(paths, completions, send: send)
        : _flushLocalPreparedClaimed(paths, completions, send!);
  }

  static Future<Map<TransactionalEditorSource, TypedMutationResult>>
  _flushPreparedClaimed(
    Map<TransactionalEditorSource, Set<DataPath>> paths,
    Map<TransactionalEditorSource, Completer<TypedMutationResult>>
    completions, {
    EditorBatchSender? send,
  }) async {
    late final Map<TransactionalEditorSource, TypedMutationResult> results;
    try {
      final saved = await _ResourceSave.run(paths);
      final batch =
          EditorBatch._(saved.commits, send, paths: _immutablePaths(paths))
            .._results = saved.results
            .._settle();
      for (final source in paths.keys) {
        final result = saved.results[source] ?? source._settledResult();
        if (!saved.commits.containsKey(source) && result is! MutationSuccess) {
          source._rejectedBatch = batch;
          source._failPaths(paths[source]!, [
            _diagnostic("The batch could not be prepared"),
          ]);
        }
      }
      results = {
        for (final source in paths.keys)
          source: saved.results[source] ?? source._settledResult(),
      };
    } on Object catch (error) {
      results = {
        for (final source in paths.keys)
          source: _unavailable("The batch could not be settled: $error"),
      };
    } finally {
      _completeClaim(completions, results);
    }
    return results;
  }

  static Future<Map<TransactionalEditorSource, TypedMutationResult>>
  _flushLocalPreparedClaimed(
    Map<TransactionalEditorSource, Set<DataPath>> paths,
    Map<TransactionalEditorSource, Completer<TypedMutationResult>> completions,
    EditorBatchSender send,
  ) async {
    final commits = <TransactionalEditorSource, EditorCommit>{};
    for (final entry in paths.entries) {
      final source = entry.key;
      final selected = source._states.flushCandidates(entry.value);
      if (selected.isEmpty) continue;
      commits[source] = source.captureCommit(selected);
      source._states.markSaving(selected);
      source._notify();
    }

    final batch = EditorBatch._(
      Map.unmodifiable(commits),
      send,
      paths: _immutablePaths(paths),
    );
    try {
      batch._results = commits.isEmpty ? {} : await send(batch._commits);
    } on Object catch (error, stackTrace) {
      batch._results = {
        for (final source in paths.keys)
          source: TypedMutationResult.uncertain(
            message: "The batch result could not be confirmed",
            cause: error,
            stackTrace: stackTrace,
          ),
      };
    }

    try {
      batch._settle();
      return {
        for (final source in paths.keys)
          source: batch._results[source] ?? source._settledResult(),
      };
    } finally {
      _completeClaim(completions, {
        for (final source in paths.keys)
          source: batch._results[source] ?? source._settledResult(),
      });
      for (final source in paths.keys) {
        source._scheduleAutoFlush();
      }
    }
  }

  static Map<TransactionalEditorSource, Completer<TypedMutationResult>> _claim(
    Iterable<TransactionalEditorSource> sources,
  ) {
    final completions = {
      for (final source in sources) source: Completer<TypedMutationResult>(),
    };
    for (final source in sources) {
      source._activeCommit = completions[source]!.future;
      source._cancelScheduledTasks();
    }
    return completions;
  }

  static void _completeClaim(
    Map<TransactionalEditorSource, Completer<TypedMutationResult>> completions,
    Map<TransactionalEditorSource, TypedMutationResult> results,
  ) {
    for (final source in completions.keys) {
      final result =
          results[source] ?? _unavailable("The batch produced no result");
      source._activeCommit = null;
      completions[source]!.complete(result);
      source._notify();
    }
  }

  static bool _validatePreparedPaths(
    Map<TransactionalEditorSource, Set<DataPath>> paths, {
    EditorBatchSender? send,
  }) {
    if (paths.isEmpty || paths.values.any((value) => value.isEmpty)) {
      throw ArgumentError.value(paths, "paths", "Must not be empty");
    }
    final resourceBatch = paths.keys.first.resource != null;
    if (paths.keys.any(
      (source) => (source.resource != null) != resourceBatch,
    )) {
      throw StateError(
        "Prepared paths cannot mix resources and local callbacks",
      );
    }
    if (!resourceBatch) {
      if (send == null) {
        throw StateError("Prepared local paths require a sender");
      }
      return false;
    }
    final workspace = paths.keys.first.workspace;
    if (workspace == null ||
        paths.keys.any((source) => source.workspace != workspace)) {
      throw StateError("Prepared paths must belong to one workspace");
    }
    return true;
  }

  static Map<TransactionalEditorSource, Set<DataPath>> _immutablePaths(
    Map<TransactionalEditorSource, Set<DataPath>> paths,
  ) => Map.unmodifiable({
    for (final entry in paths.entries) entry.key: Set.unmodifiable(entry.value),
  });

  void _settle() {
    for (final entry in _commits.entries) {
      final source = entry.key;
      if (source._disposed || source._deleted) continue;
      final commit = entry.value;
      final result = _results[source] ?? _unavailable("Missing batch result");

      source._states.clearSaving();
      source
        .._unresolved = null
        .._rejectedBatch =
            result is MutationSuccess || result is MutationUncertain
            ? null
            : this;
      if (result is MutationUncertain) {
        source._unresolved = _UnresolvedCommit(
          commit,
          result.copyWith(
            replay: result.replay == null
                ? null
                : () async => (await _retry())[source]!,
          ),
        );
      } else {
        source.acceptCommit(commit, result);
      }
      source
        .._notify()
        .._scheduleAutoFlush();
    }
  }
}
