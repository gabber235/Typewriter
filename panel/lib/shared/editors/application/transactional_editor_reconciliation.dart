part of "transactional_editor_source.dart";

/// Applies remote observations without conflating canonical and local state.
///
/// Reconciliation owns the rule that a newer remote revision advances the
/// canonical document, while the draft keeps local edits unless merge policy
/// proves them unchanged, already accepted remotely, or conflicting. It also
/// updates path save state and diagnostics as one owner controlled transition.
/// No remote observation can erase a local draft silently.
extension _EditorReconciliation on TransactionalEditorSource {
  /// Accepts a complete authoritative document when its revision is current or
  /// newer, preserving local draft work through reconciliation.
  bool _acceptAuthoritativeSnapshot(EditorDocument document) {
    if (_disposed || _deleted || document.revision < _document.revision) {
      return false;
    }
    if (document.revision > _document.revision) {
      _refreshDocument(document);
      return false;
    }
    final divergent = document.confirmedValue != _document.confirmedValue;
    var reconciliationDiagnostics = const <EditorDiagnostic>[];
    if (divergent) {
      final result = _reconciler.reconcile(
        base: _document.confirmedValue,
        local: _draft,
        remote: document.confirmedValue,
        remoteRevision: document.revision,
        dirtyPaths: _states.dirtyPaths,
        mergePolicies: _document.mergePolicies,
      );
      _document = _document.copyWith(
        confirmedValue: result.base,
        revision: result.revision,
      );
      reconciliationDiagnostics = result.diagnostics;
      _draft = result.draft;
      _states.applyReconciliation(
        dirtyPaths: result.dirtyPaths,
        confirmedPaths: result.confirmedPaths,
        conflicts: result.conflicts,
        confirmedPhase: EditorSavePhase.saved,
      );
    }
    final refreshed = _document.copyWith(
      rootType: document.rootType,
      catalog: document.catalog,
      mergePolicies: document.mergePolicies,
      diagnostics: [...document.diagnostics, ...reconciliationDiagnostics],
      readOnly: document.readOnly,
    );
    if (!_document.hasSameContent(refreshed) || divergent) {
      _document = refreshed;
      _notify();
    }
    return divergent;
  }

  /// Refreshes canonical metadata and value while preserving local ownership.
  ///
  /// This path is used when the resource binding is replaced or refreshed. The
  /// existing draft is not retargeted to a new persistence operation, and any
  /// in flight operation remains bound to the commit it captured.
  void _refreshDocument(EditorDocument document) {
    if (_disposed) return;
    if (_document.hasSameContent(document)) return;
    acceptRemote(revision: document.revision, value: document.confirmedValue);
    final refreshed = _document.copyWith(
      rootType: document.rootType,
      catalog: document.catalog,

      mergePolicies: document.mergePolicies,

      diagnostics: document.diagnostics,
      readOnly: document.readOnly,
    );

    if (_document.hasSameContent(refreshed)) return;

    _document = refreshed;
    _notify();
  }

  /// Merges a remote value into the canonical document and local draft.
  ///
  /// Revision order is monotonic. Same revision and different value is a
  /// diagnostic rather than a merge input. For a newer revision, the
  /// reconciler returns the next canonical value, draft, dirty paths,
  /// confirmed paths, conflicts, and diagnostics together so observers never
  /// see only part of the transition.
  void _acceptRemote({required int revision, required skir.DataValue value}) {
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
      confirmedPhase: EditorSavePhase.saved,
    );
    _notify();
  }

  /// Acknowledges the captured commit while retaining edits made in flight.
  ///
  /// A path is confirmed only when the returned value still matches the value
  /// sent and no newer local mutation overlaps it. This prevents an old
  /// successful response from overwriting a newer draft.
  void _acceptSuccess(
    int revision,
    skir.DataValue value,
    skir.DataValue sent,
    Set<skir.ValuePath> committed,
    int submittedRevision,
  ) {
    var nextDraft = value;
    final confirmed = <skir.ValuePath>{};
    for (final path in _states.dirtyPaths) {
      final local = _draft.editorValueAt(path);
      final editedAfterSubmission = _pendingMutations.any(
        (pending) =>
            pending.revision > submittedRevision &&
            _pathsOverlap(path, pending.mutation.path),
      );
      if (committed.contains(path) &&
          !editedAfterSubmission &&
          local == sent.editorValueAt(path)) {
        confirmed.add(path);
        continue;
      }
      if (local != null) {
        nextDraft = nextDraft.replacingEditorValue(path, local) ?? nextDraft;
      }
    }
    _states.confirm(confirmed, EditorSavePhase.saved);

    _document = _document.copyWith(confirmedValue: value, revision: revision);

    _draft = nextDraft;
    _notify();
  }
}
