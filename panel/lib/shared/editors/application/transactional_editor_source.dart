/*
 * Coordinates one editable resource without collapsing local and remote state.
 *
 * TransactionalEditorSource owns the lifecycle of a canonical EditorDocument,
 * a separate local draft, local revisions, pending structural mutations,
 * persistence attempts, and reconciliation decisions. The document is the
 * last accepted resource state. The draft is what the editor currently shows
 * and may contain edits that have never been sent. Revisions order canonical
 * observations; they do not identify local edits. Persistence captures an
 * immutable commit, and reconciliation decides how a later remote observation
 * affects the draft. Typed mutation results expose success, conflict, invalid,
 * denied, uncertain, and unavailable outcomes so callers do not infer
 * durability from a completed future.
 *
 * Only this source mutates the combined editing state. Consumers observe it,
 * submit explicit operations, and resolve reported conflicts. A source is
 * single threaded at the Dart event loop boundary: a commit may be awaiting
 * external work, but remote updates and later edits are serialized when they
 * reenter the source. dispose invalidates outstanding work and prevents a
 * stale completion from changing state.
 */
import "dart:async";

import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "transactional_editor_persistence.dart";
part "transactional_editor_commit.dart";
part "editor_batch.dart";
part "editor_resource_save.dart";
part "editor_batch_recovery.dart";
part "transactional_editor_interactions.dart";
part "transactional_editor_reconciliation.dart";

/// Sends one captured commit to the persistence boundary.
///
/// The callback must preserve the commit's expected revision semantics and
/// return a typed outcome. An uncertain outcome means the request may have
/// reached its destination, so the source retains the captured operation for
/// replay rather than treating it as failed.
typedef EditorCommitter = Future<TypedMutationResult> Function(
  EditorCommit commit,
);

/// Validates a local mutation before it enters the draft.
typedef EditorMutationValidator = EditorMutationResult Function(
  DataPath path,
  DataValue value,
);

/// Executes a realm action independently of editor persistence.
typedef EditorRealmActionExecutor = Future<RealmCommandResult> Function(
  RealmAction action,
  ExpressionContext context,
);

/// Owns the editable projection of one resource and its save lifecycle.
///
/// Canonical state lives in [document]. Local edits live in the private draft
/// until a captured [EditorCommit] is accepted. A successful result confirms
/// only edits still represented by that capture; edits made while it was in
/// flight remain local. Remote observations are never written over the draft
/// blindly. They pass through reconciliation, which preserves independent
/// local changes and records conflicts where both sides changed the same path.
///
/// Autosave schedules persistence after a quiet period. Apply resource mode
/// waits for an explicit flush and treats the whole draft as one consistency
/// boundary. Flushes are serialized, conflict retries use the returned
/// revisions, and uncertain results remain recoverable through their typed
/// replay outcome. Dispose ends this lifecycle; deleted resources reject later
/// edits and stale asynchronous results.
final class TransactionalEditorSource extends ChangeNotifier
    implements EditorSource {
  /// Creates an owner for [document] and an optional persistence boundary.
  ///
  /// [document] supplies the canonical value and revision at attachment time.
  /// The source copies its confirmed value into a separate draft. Validation,
  /// scheduling, jitter, and persistence are injected so timing and external
  /// effects remain explicit and testable.
  TransactionalEditorSource({
    required EditorDocument document,
    this._commit,
    this._resource,
    this.workspace,
    this._snapshot,
    this._validate,
    this._validateDraft,
    this.commitPolicy = EditorCommitPolicy.autosaveChanges,
    this._scheduler = const TimerEditorDelayScheduler(),
    EditorJitterSource? jitter,
    this.debounce = const Duration(milliseconds: 250),
    this.onDeleted,
  }) : _document = document,
       _draft = document.confirmedValue,
       _jitter = jitter ?? RandomEditorJitterSource();

  EditorDocument _document;
  DataValue _draft;
  final EditorCommitter? _commit;
  EditableResource? _resource;
  EditableResource? get resource => _resource;
  final LocalWorkSession? workspace;
  EditorSnapshot? _snapshot;
  EditorSnapshot? get snapshot => _snapshot;
  EditorSnapshot? _pendingContractSnapshot;
  bool get contractReconciliationPending => _pendingContractSnapshot != null;
  bool _contractUnavailable = false;
  bool get contractUnavailable => _contractUnavailable;
  int get localRevision => _localRevision;
  final EditorMutationValidator? _validate;
  final List<TypeDiagnostic> Function(DataValue)? _validateDraft;

  @override
  final EditorCommitPolicy commitPolicy;

  @override
  bool get hasWork =>
      _states.dirtyPaths.isNotEmpty ||
      _activeCommit != null ||
      _unresolved != null;

  Set<DataPath> get editedPaths => Set.unmodifiable(_states.dirtyPaths);

  @override
  List<TypeDiagnostic> get draftDiagnostics =>
      _snapshot?.validateDraft(_draft) ??
      _validateDraft?.call(_draft) ??
      const [];

  final EditorDelayScheduler _scheduler;
  final EditorJitterSource _jitter;
  final Duration debounce;
  final VoidCallback? onDeleted;
  final EditorReconciler _reconciler = const EditorReconciler();
  final EditorPathStates _states = EditorPathStates();
  EditorScheduledTask? _debounceTask;
  EditorScheduledTask? _retryTask;
  Future<TypedMutationResult>? _activeCommit;
  _UnresolvedCommit? _unresolved;
  EditorBatch? _rejectedBatch;
  bool _deleted = false;
  bool _disposed = false;
  int _localRevision = 0;
  int _generation = 0;
  final List<_PendingStructuralMutation> _pendingMutations = [];

  /// The type of the current canonical document.
  @override
  TypeExpression get rootType => document.rootType;

  /// The catalog of the current canonical document.
  @override
  TypeCatalog get typeCatalog => document.typeCatalog;

  /// Whether local mutation is currently disallowed by the document or save
  /// lifecycle.
  @override
  bool get readOnly =>
      document.readOnly ||
      (commitPolicy == EditorCommitPolicy.applyResource &&
          (_activeCommit != null || _unresolved != null));

  @override
  EditorDocument get document => _document;

  /// Reads the local draft at [path], including unsaved edits.
  @override
  EditorValue value(DataPath path) {
    if (_deleted) {
      return EditorValue.invalid([_diagnostic("Deleted elsewhere", path)]);
    }
    return _draft.readEditorValue(path);
  }

  /// Validates and applies one local draft edit.
  ///
  /// This changes local state only. Persistence occurs later according to
  /// [commitPolicy], and the returned typed result identifies rejection before
  /// any draft change.
  @override
  EditorMutationResult update(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    final validation = validate(path, value);
    if (validation is! AppliedEditorMutation) return validation;
    final replaced = path.replace(_draft, validation.value);
    if (replaced case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }

    _draft = replaced.valueOrNull!;

    _localRevision++;
    _pendingMutations.add(
      _PendingStructuralMutation(
        _localRevision,
        structuralMutation ?? EditorSetValue(path, validation.value),
      ),
    );

    _states.markEdited(path);

    _notify();

    _scheduleAutoFlush();
    return validation;
  }

  /// Validates an edit against the current document and editor lifecycle.
  @override
  EditorMutationResult validate(DataPath path, DataValue value) {
    if (_disposed) {
      return EditorMutationResult.invalid([_diagnostic("Editor is disposed")]);
    }
    if (_deleted) return EditorMutationResult.invalid([_deletedDiagnostic()]);
    if (readOnly) {
      return EditorMutationResult.invalid([
        _diagnostic("The editor is read only", path),
      ]);
    }
    return _snapshot?.validate(path, value) ??
        _validate?.call(path, value) ??
        _document.rootType.validateEditorMutation(
          path,
          value,
          registry: TypeRegistry(_document.typeCatalog),
        );
  }

  @override
  void refreshDocument(EditorDocument document) => _refreshDocument(document);

  /// Starts a reversible interaction for [path].
  ///
  /// Overlapping interactions are closed before the new interaction owns the
  /// path. The session controls its local interaction lifecycle; it does not
  /// imply that the resulting draft is persisted.
  @override
  EditorInteractionSession beginInteraction(DataPath path) {
    for (final gate in _states.takeGates()) {
      if (_pathsOverlap(path, gate.path)) {
        if (gate is _Interaction) gate.close();
      } else {
        _states.setGate(gate.path, gate);
      }
    }
    final interaction = _Interaction(
      source: this,
      path: path,
      origin: path.read(_draft).valueOrNull,
      startingRevision: _localRevision,
    );
    if (_disposed || _deleted) {
      interaction.close();
      return interaction;
    }
    _states.setGate(path, interaction);
    return interaction;
  }

  /// Reports the persistence and reconciliation state affecting [path].
  ///
  /// Uncertain means the destination may have accepted the captured commit and
  /// must be resolved or replayed. It is not equivalent to failure.
  @override
  EditorSaveState saveState(DataPath path) {
    if (_deleted) {
      return EditorSaveState(
        phase: EditorSavePhase.deletedElsewhere,
        path: path,
      );
    }
    if (_unresolved case final unresolved?) {
      return EditorSaveState(
        phase: _activeCommit == null
            ? EditorSavePhase.uncertain
            : EditorSavePhase.saving,
        path: path,
        replayAvailable: unresolved.result.replay != null,
        submissionId: unresolved.result.submissionId,
        diagnostics: [_diagnostic(unresolved.result.message)],
      );
    }
    return _states.saveState(path);
  }

  /// Persists eligible draft changes and returns the typed operation outcome.
  ///
  /// With [paths], autosave mode limits the consistency boundary to overlapping
  /// paths. Apply resource mode flushes the whole draft. Calls serialize behind
  /// an active attempt, and a conflict may rebase and retry. A successful
  /// result confirms only the captured edits that were not superseded locally.
  @override
  Future<TypedMutationResult> flush({Set<DataPath>? paths}) async {
    if (_disposed) return _unavailable("Editor is disposed");
    if (_deleted) return _unavailable("Deleted elsewhere");

    while (_activeCommit != null) {
      await _activeCommit!;
      if (_disposed) return _unavailable("Editor is disposed");
      if (_deleted) return _unavailable("Deleted elsewhere");
    }
    if (_unresolved case final unresolved?) return _replayCommit(unresolved);
    if (_rejectedBatch case final batch?) {
      if (paths == null ||
          paths.any(
            (path) => batch._paths[this]!.any(
              (changed) => _pathsOverlap(path, changed),
            ),
          )) {
        return (await batch._retryRejected())[this] ?? _settledResult();
      }
    }
    final selected = _states.flushCandidates(
      commitPolicy == EditorCommitPolicy.applyResource ? null : paths,
    );
    return selected.isEmpty ? _settledResult() : _runCommit(selected);
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

  /// Supplies a newer canonical observation for reconciliation.
  ///
  /// Older revisions are ignored. A newer revision becomes canonical while
  /// local draft edits remain subject to merge policy. Equal revisions with
  /// different values are retained as a diagnostic because the invariant that
  /// revisions identify canonical content has been violated.
  @override
  void acceptRemote({required int revision, required DataValue value}) =>
      _acceptRemote(revision: revision, value: value);

  /// Resolves [path] by discarding its local value in favor of the canonical
  /// value.
  ///
  /// This is a local conflict decision. It does not send a persistence request.
  @override
  void useRemote(DataPath path) {
    if (_disposed || _unresolved != null) return;
    final remote = path.read(_document.confirmedValue).valueOrNull;
    if (remote == null) return;
    _draft = path.replace(_draft, remote).valueOrNull ?? _draft;
    _pendingMutations.removeWhere(
      (pending) => _pathsOverlap(path, pending.mutation.path),
    );

    _states.adoptRemote(path, EditorSavePhase.saved);
    _notify();
  }

  /// Resolves [path] by retaining its local value and, when appropriate,
  /// flushing it.
  ///
  /// The typed result describes that flush. In apply resource mode the choice
  /// only settles the conflict because the enclosing draft is persisted by a
  /// later explicit operation.
  @override
  Future<TypedMutationResult> keepLocal(DataPath path) {
    if (_disposed) return Future.value(_unavailable("Editor is disposed"));
    if (_unresolved case final unresolved?) {
      return Future.value(unresolved.result);
    }
    _states.resolveConflictLocally(path);
    _notify();
    if (commitPolicy == EditorCommitPolicy.applyResource) {
      return Future.value(_settledResult());
    }
    return flush(paths: {path});
  }

  /// Ends editing when the canonical resource was deleted elsewhere.
  ///
  /// Pending work is invalidated, interactions close, and future edits return
  /// an unavailable typed outcome. The owner remains observable until
  /// [dispose], allowing consumers to render the deletion state.
  @override
  void acceptRemoteDeletion() {
    if (_disposed || _deleted) return;
    _deleted = true;
    _pendingMutations.clear();
    _unresolved = null;

    _generation++;

    _cancelScheduledTasks();

    _closeGates();

    _notify();
    onDeleted?.call();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Replaces the draft with canonical content and clears local work.
  @override
  void discardDraft() => _discardDraft();

  /// Releases scheduled tasks, interactions, and listener notifications.
  ///
  /// Completions already awaiting external work cannot mutate this owner after
  /// disposal. Calling this more than once is harmless.
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
