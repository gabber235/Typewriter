part of "transactional_editor_source.dart";

/// Rebinds a retained draft to newer immutable resource metadata.
extension EditorResourceBinding on TransactionalEditorSource {
  /// Refreshes the resource handle and snapshot without replacing local edits.
  ///
  /// The resource key is the ownership boundary and cannot change while a
  /// draft is retained. Older document revisions are ignored, preventing a
  /// delayed read from moving the editor backwards.
  void refreshTarget(EditorTarget target) {
    if (_resource?.key != target.resource.key) {
      throw StateError("A draft cannot change resource scope");
    }
    _resource = target.resource;
    refreshSnapshot(target.snapshot);
  }

  /// Applies a newer presentation snapshot while preserving the draft.
  void refreshSnapshot(EditorSnapshot snapshot) {
    if (snapshot.document.revision < document.revision) return;
    final pinned = _snapshot;
    if (pinned is EditorContractSnapshot &&
        !pinned.contractCompatibleWith(snapshot)) {
      _pendingContractSnapshot = snapshot;
      _pauseForContractChange();
      return;
    }
    _pendingContractSnapshot = null;
    _contractUnavailable = false;
    _snapshot = snapshot;
    refreshDocument(snapshot.document);
  }

  /// Integrates an authoritative read before saving resource mutations.
  ///
  /// Returns whether the read diverged from local state. Callers use that
  /// signal to stop submission and expose the divergence instead of writing
  /// against stale resource data.
  bool refreshAuthoritativeSnapshot(EditorSnapshot snapshot) {
    if (snapshot.document.revision < document.revision) return false;
    final pinned = _snapshot;
    if (pinned is EditorContractSnapshot &&
        !pinned.contractCompatibleWith(snapshot)) {
      _pendingContractSnapshot = snapshot;
      _pauseForContractChange();
      return true;
    }
    _pendingContractSnapshot = null;
    _contractUnavailable = false;
    _snapshot = snapshot;
    return _acceptAuthoritativeSnapshot(snapshot.document);
  }

  /// Validates the retained draft under the pending contract before swapping.
  bool reconcilePendingContract() {
    final candidate = _pendingContractSnapshot;
    if (candidate == null) return false;
    final mutation = candidate.validate(DataPath.root, _draft);
    if (mutation is! AppliedEditorMutation ||
        candidate.validateDraft(_draft).isNotEmpty) {
      return false;
    }
    _pendingContractSnapshot = null;
    _snapshot = candidate;
    _refreshDocument(candidate.document);
    return true;
  }

  /// Accepts the pending contract after explicitly discarding local work.
  bool discardDraftAndAcceptPendingContract() {
    final candidate = _pendingContractSnapshot;
    if (candidate == null) return false;
    _pendingContractSnapshot = null;
    _snapshot = candidate;
    _refreshDocument(candidate.document);
    _discardDraft();
    return true;
  }

  /// Pauses mutation while the exact resource contract is unavailable.
  void markContractUnavailable(String message) {
    _contractUnavailable = true;
    _pauseForContractChange(message: message);
  }

  /// Retries the current resource contract without changing the draft.
  Future<bool> retryContractRefresh() async {
    final resource = _resource;
    if (resource == null) return false;
    try {
      final candidate = await resource.refresh();
      if (candidate == null) {
        acceptRemoteDeletion();
        return false;
      }
      _contractUnavailable = false;
      refreshSnapshot(candidate);
      return !_contractUnavailable;
    } on EditorContractUnavailableException catch (error) {
      markContractUnavailable(error.message);
      return false;
    }
  }

  void _pauseForContractChange({
    String message = "The editor contract changed. Reconcile or discard the draft to continue",
  }) {
    final diagnostic = TypeDiagnostic(
      code: TypeDiagnosticCode.invalidRevision,
      message: message,
      pathPresent: false,
    );
    _document = _document.copyWith(
      diagnostics: [
        ..._document.diagnostics.where(
          (item) => item.code != TypeDiagnosticCode.invalidRevision,
        ),
        diagnostic,
      ],
      readOnly: true,
    );
    _notify();
  }
}

/// Prepares and submits resource saves inside one mutation reservation.
///
/// It refreshes every participant, checks ownership and conflicts, captures
/// commits, and verifies that all preparations belong to the reserved atomic
/// transaction. Failures before submission are unavailable; failures where
/// submission status cannot be confirmed are uncertain and retain replay data.
final class _ResourceSave {
  const _ResourceSave(
    this.commits,
    this.results, {
    this.authoritativeDivergence = false,
  });
  final Map<TransactionalEditorSource, EditorCommit> commits;
  final Map<TransactionalEditorSource, TypedMutationResult> results;
  final bool authoritativeDivergence;

  static Future<_ResourceSave> run(
    Map<TransactionalEditorSource, Set<DataPath>> paths,
  ) async {
    final workspace = paths.keys.first.workspace!;
    final commits = <TransactionalEditorSource, EditorCommit>{};
    final resources = paths.keys
        .expand((source) => source.resource!.reservations)
        .toSet();
    MutationReservation? reservation;
    try {
      if (paths.keys.any((source) => source.workspace != workspace)) {
        throw StateError("An editor transaction must belong to one workspace");
      }
      reservation = await workspace.coordinator.reserve(resources);
      final snapshots = <EditorSnapshot?>[];
      for (final source in paths.keys) {
        try {
          snapshots.add(await source.resource!.refresh());
        } on EditorContractUnavailableException catch (error) {
          source.markContractUnavailable(error.message);
          return _ResourceSave({}, {
            for (final participant in paths.keys)
              participant: _unavailable(error.message),
          });
        }
      }
      var authoritativeDivergence = false;
      for (final indexed in paths.keys.indexed) {
        final source = indexed.$2;
        if (source._disposed || source._deleted) {
          return _ResourceSave({}, {
            for (final participant in paths.keys)
              participant: _unavailable("The resource is no longer available"),
          });
        }
        final snapshot = snapshots[indexed.$1];
        if (snapshot == null) {
          source.acceptRemoteDeletion();
          return _ResourceSave({}, {
            for (final participant in paths.keys)
              participant: _unavailable("The resource was deleted"),
          });
        }
        authoritativeDivergence =
            source.refreshAuthoritativeSnapshot(snapshot) ||
            authoritativeDivergence;
      }
      if (authoritativeDivergence) {
        return _ResourceSave({}, {
          for (final participant in paths.keys)
            participant: _unavailable(
              "The authoritative resource changed while preparing the save",
            ),
        }, authoritativeDivergence: true);
      }
      for (final source in paths.keys) {
        if (source.document.readOnly || source._states.hasConflicts) {
          return _ResourceSave({}, {
            for (final participant in paths.keys)
              participant: _unavailable(
                "Resolve unavailable resources and conflicting fields before saving",
              ),
          });
        }
        final diagnostics = source._saveDiagnostics();
        if (diagnostics.isNotEmpty) {
          return _ResourceSave({}, {
            for (final participant in paths.keys)
              participant: TypedMutationResult.invalid(diagnostics),
          });
        }
      }
      for (final source in paths.keys) {
        final selected = source._states.flushCandidates(
          source.commitPolicy == EditorCommitPolicy.applyResource
              ? null
              : paths[source],
        );
        if (selected.isEmpty) continue;
        commits[source] = source.captureCommit(selected);
        source._states.markSaving(selected);
        source._notify();
      }

      if (commits.isEmpty) return const _ResourceSave({}, {});

      final results = <TransactionalEditorSource, TypedMutationResult>{};
      final pending = MutationPreparation.collect([
        for (final entry in commits.entries)
          entry.key.resource!.prepare(
            entry.key._snapshot!,
            entry.value,
            (result) => results[entry.key] = result,
          ),
      ]);
      if (pending.length != 1) {
        throw StateError("These resources do not share one atomic transaction");
      }
      if (!resources.containsAll(pending.single.resources)) {
        throw StateError("The request changed its reserved resources");
      }

      final submission = pending.single.start(workspace, reservation);

      reservation = null;
      Future<TypedMutationResult> outcome(
        TransactionalEditorSource source,
      ) async {
        final result = await submission.run();
        if (submission.integrationError != null) {
          return MutationUncertain(
            message: "The response could not be integrated",
            cause: submission.integrationError!.error,
            stackTrace: submission.integrationError!.stackTrace,
            submissionId: submission.id,
            replay: () => outcome(source),
          );
        }
        if (result is SubmissionNotSubmitted) {
          return _unavailable(result.message);
        }
        if (result is SubmissionUncertain) {
          return MutationUncertain(
            message: result.message,
            cause: result.cause,
            stackTrace: result.stackTrace,
            submissionId: submission.id,
            replay: submission.canReplay ? () => outcome(source) : null,
          );
        }
        return results[source] ??
            _unavailable("The transaction returned no resource result");
      }

      final settled = await Future.wait(commits.keys.map(outcome));
      return _ResourceSave(commits, {
        for (final indexed in commits.keys.indexed)
          indexed.$2: settled[indexed.$1],
      });
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: "Typewriter editor resource save",
          context: ErrorDescription("while preparing an editor resource save"),
        ),
      );
      return _ResourceSave({}, {
        for (final source in paths.keys)
          source: _unavailable(
            "The resource could not be prepared (${error.runtimeType})",
          ),
      });
    } finally {
      reservation?.release();
    }
  }
}

extension _ResourcePersistence on TransactionalEditorSource {
  /// Persists resource paths, retrying conflicts with the newest revision.
  ///
  /// Only paths still eligible after reconciliation are retried. An uncertain
  /// result stops the loop and stores the unresolved commit for explicit
  /// recovery, while successful commits are accepted before the source is
  /// notified.
  Future<TypedMutationResult> _persistResource(Set<DataPath> paths) async {
    var activePaths = paths;
    var attempts = 0;
    try {
      while (true) {
        final saved = await _ResourceSave.run({this: activePaths});
        if (_disposed || _deleted) {
          return _unavailable("Editor is no longer available");
        }
        final result = saved.results[this] ?? _settledResult();
        final commit = saved.commits[this];
        if (commit == null) {
          final diagnostics = switch (result) {
            MutationInvalid(:final diagnostics) ||
            MutationUnavailable(:final diagnostics) => diagnostics,
            _ => [_diagnostic("The resource could not be saved")],
          };
          if (result is! MutationSuccess && !saved.authoritativeDivergence) {
            _failPaths(activePaths, diagnostics);
          }
          return result;
        }
        if (result is MutationUncertain) {
          _unresolved = _UnresolvedCommit(commit, result);
          return result;
        }

        acceptCommit(commit, result);
        if (result is! MutationConflict ||
            commitPolicy == EditorCommitPolicy.applyResource) {
          return result;
        }

        final next = _states.flushCandidates(activePaths);
        if (next.isEmpty) return result;
        attempts++;
        if (!await _waitForRetry(
          next,
          attempts,
          expectedVersion: result.expectedRevision,
          observedVersion: result.actualRevision,
        )) {
          return result;
        }
        activePaths = next;
      }
    } finally {
      if (!_disposed) {
        _states.clearSaving();
        _notify();
      }
    }
  }
}
