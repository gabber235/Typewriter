import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

typedef EditorCommitter = Future<TypedMutationResult> Function(
  EditorCommit commit,
);
typedef EditorMutationValidator = EditorMutationResult Function(
  skir.ValuePath path,
  skir.DataValue value,
);

/// Exposes typed path editing through one group in an [EditingWorkspace].
///
/// The default factory owns its workspace and any privately created work
/// session. [ValueEditing.fromWorkspace] is a borrowed view whose disposal
/// leaves the shared owner alive. [ValueEditingRegistration] supplies this
/// borrowed form for resource views retained by the local work session.
final class ValueEditing
    implements EditOwner, EditingControlOwner, EditingStageOwner {
  factory ValueEditing({
    required EditorDocument document,
    EditorCommitter? commit,
    ValueEditPersistence? persistence,
    LocalWorkCommands? workspace,
    EditorSnapshot? snapshot,
    EditorMutationValidator? validation,
    List<EditorDiagnostic> Function(skir.DataValue)? validateDraft,
    EditorCommitPolicy commitPolicy = EditorCommitPolicy.autosaveChanges,
    EditorDelayScheduler scheduler = const TimerEditorDelayScheduler(),
    EditorJitterSource? jitter,
    Duration debounce = const Duration(milliseconds: 250),
  }) {
    final metadata =
        snapshot ?? CallbackEditorSnapshot(document, validation, validateDraft);
    final session = workspace ?? ScopedWorkSession();
    final boundary =
        persistence ?? CallbackValueEditPersistence(metadata, commit);
    final owner = EditingWorkspace<ValueEditDocument, ValueEdit>(
      model: const ValueEditModel(),
      persistence: boundary,
      submissions: session,
      initial: ValueEditDocument.fromSnapshot(metadata, identity: boundary.key),
      scheduler: scheduler,
      jitter: jitter,
      debounce: debounce,
    );
    final group = owner.createGroup(
      label: "Edit value",
      key: boundary.key,
      policy: commitPolicy,
      admission: commitPolicy == EditorCommitPolicy.applyResource
          ? EditWriteAdmission.lockWhileSubmitted
          : EditWriteAdmission.allowWhileSubmitted,
      repair: EditRepairAdmission.acceptCorrections,
      commits: commitPolicy == EditorCommitPolicy.applyResource
          ? EditCommitAdmission.completeGroup
          : EditCommitAdmission.applicableOperations,
    );
    return ValueEditing._(owner, group, () {
      owner.dispose();
      if (workspace == null) (session as ScopedWorkSession).dispose();
    });
  }
  ValueEditing._(this.workspace, this.groupId, this._dispose);
  ValueEditing.fromWorkspace(this.workspace, this.groupId) : _dispose = null;
  final EditingWorkspace<ValueEditDocument, ValueEdit> workspace;
  final EditGroupId groupId;
  final VoidCallback? _dispose;
  @override
  EditGroupControl<ValueEditDocument, ValueEdit> bindControl() =>
      workspace.group(groupId);
  EditorDocument get document {
    final current = workspace.confirmed.metadata.document;
    final failure = workspace.state.failure;
    return failure is EditPreparationFailure
        ? current.copyWith(
            diagnostics: [...current.diagnostics, ...failure.diagnostics],
          )
        : current;
  }

  EditorSnapshot get snapshot => workspace.document.metadata;
  EditorCommitPolicy get commitPolicy => workspace.policyFor(groupId);
  bool get hasWork => workspace.state.groups.containsKey(groupId);
  int get localRevision => workspace.revision;
  Set<skir.ValuePath> get editedPaths => {
    for (final edit in workspace.edits(groupId)) ...edit.paths,
  };
  List<EditorDiagnostic> get draftDiagnostics =>
      snapshot.validateDraft(workspace.document.value);
  bool get contractReconciliationPending =>
      !workspace.model.sameContract(workspace.confirmed, workspace.document);
  bool get contractUnavailable =>
      workspace.state.failure is EditorContractUnavailableException;
  @override
  skir.TypeUse get rootType => snapshot.document.rootType;
  @override
  CheckedEditorCatalog get catalog => snapshot.document.catalog;
  @override
  bool get readOnly =>
      snapshot.document.readOnly ||
      !workspace.canEdit(groupId) ||
      !workspace.document.exists;
  @override
  EditorValue value(skir.ValuePath path) => workspace.document.exists
      ? workspace.document.value.readEditorValue(path)
      : EditorValue.invalid([_valueDiagnostic("Deleted elsewhere", path)]);
  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      readOnly
      ? EditorMutationResult.invalid([
          _valueDiagnostic("The editor is read only", path),
        ])
      : snapshot.validate(path, value);
  @override
  EditorMutationResult update(skir.ValuePath path, skir.DataValue value) {
    final hold = workspace.holdStage();
    try {
      final admitted = validate(path, value);
      if (admitted is! AppliedEditorMutation) return admitted;
      final phase = workspace.state.groups[groupId]?.phase;
      if (phase != null && phase.blocked && !phase.submitted) {
        workspace.replacePending(
          groupId,
          (observation, edit) =>
              edit.paths.every((edited) => edited.isAtOrBelow(path))
              ? edit.copyWith(baseline: observation)
              : edit,
        );
      }
      final before = workspace.document;
      final next = before.value.replacingEditorValue(path, admitted.value);
      if (next == null) {
        return EditorMutationResult.invalid([
          _valueDiagnostic("The editor path is unavailable", path),
        ]);
      }
      final result = workspace.stage(
        groupId,
        ValueEdit(
          baseline: before,
          proposed: next,
          paths: {path},
          mutations: [EditorSetValue(path, admitted.value)],
        ),
      );
      return result is EditStageRejected
          ? EditorMutationResult.invalid([
              _valueDiagnostic(result.message, path),
            ])
          : admitted;
    } finally {
      hold.release();
    }
  }

  @override
  EditingStageHold holdStage() => workspace.holdStage();
  @override
  EditorInteractionSession beginInteraction(skir.ValuePath path) =>
      ValueEditingInteraction(path, workspace.beginInteraction(groupId, path));
  EditorSaveState saveState(skir.ValuePath path) {
    final phase = workspace.state.groups[groupId]?.phase;
    final relevant = workspace
        .edits(groupId)
        .where((edit) => edit.paths.any((edited) => edited.overlaps(path)))
        .toList();
    final conflicts = <EditReplay<ValueEditDocument, ValueEdit>>[];
    var observation = workspace.confirmed;
    for (final edit in workspace.edits(groupId)) {
      final replay = workspace.model.replay(observation, edit);
      if (replay.kind == EditReplayKind.conflict &&
          edit.paths.any((edited) => edited.overlaps(path))) {
        conflicts.add(replay);
      }
      observation = replay.observation;
    }
    final rejected = phase is EditGroupRejected<ValueEditDocument>
        ? phase.cause
        : null;
    final diagnostics =
        rejected is EditPreparationFailure && rejected.diagnostics.isNotEmpty
        ? rejected.diagnostics
        : [
            if (phase != null && phase.needsAttention)
              _valueDiagnostic(phase.message, path),
          ];
    return EditorSaveState(
      phase: !workspace.document.exists
          ? EditorSavePhase.deletedElsewhere
          : phase?.active ?? false
          ? EditorSavePhase.saving
          : phase is EditGroupUncertain ||
                phase is EditGroupCommittedAwaitingRefresh
          ? EditorSavePhase.uncertain
          : phase is EditGroupRepeatedContention
          ? EditorSavePhase.repeatedContention
          : phase is EditGroupRejected || phase is EditGroupContractChanged
          ? EditorSavePhase.failed
          : conflicts.isNotEmpty
          ? EditorSavePhase.conflict
          : relevant.isNotEmpty
          ? EditorSavePhase.pending
          : workspace.submissionId(groupId) != null
          ? EditorSavePhase.saved
          : EditorSavePhase.idle,
      contention: phase is EditGroupRepeatedContention<ValueEditDocument>
          ? EditorContentionDetails(
              kind: EditorContentionKind.versionMismatch,
              attempts: phase.attempts,
              retryLimit: 3,
              paths: editedPaths,
              expectedVersion: switch (phase.evidence) {
                final ValueConflictEvidence evidence =>
                  evidence.expectedVersion,
                _ => null,
              },
              observedVersion: switch (phase.evidence) {
                final ValueConflictEvidence evidence =>
                  evidence.observedVersion,
                _ => null,
              },
            )
          : null,
      path: relevant.firstOrNull?.paths.firstOrNull ?? path,
      submissionId: workspace.submissionId(groupId),
      replayAvailable: workspace.canRetry(groupId),
      diagnostics: diagnostics,
    );
  }

  Future<TypedMutationResult> flush({Set<skir.ValuePath>? paths}) async {
    if (workspace.closed || !workspace.document.exists) {
      return TypedMutationResult.unavailable([
        _valueDiagnostic("The editor is unavailable"),
      ]);
    }
    if (paths != null &&
        !editedPaths.any((edited) => paths.any(edited.overlaps))) {
      return TypedMutationResult.success(
        revision: document.revision,
        value: document.confirmedValue,
      );
    }
    if (workspace.canRetry(groupId)) {
      await workspace.retry(groupId);
    } else {
      await workspace.save(groupId);
    }
    if (workspace.closed || !workspace.document.exists) {
      return TypedMutationResult.unavailable([
        _valueDiagnostic("The editor is unavailable"),
      ]);
    }
    final phase = workspace.state.groups[groupId]?.phase;
    if (phase
        case EditGroupRejected<ValueEditDocument>(
          cause: EditPreparationFailure(:final diagnostics),
        )
        when diagnostics.isNotEmpty) {
      return TypedMutationResult.invalid(diagnostics);
    }
    if (phase is EditGroupUncertain ||
        phase is EditGroupCommittedAwaitingRefresh) {
      return MutationUncertain(
        message: phase!.message,
        cause: phase,
        stackTrace: StackTrace.current,
        submissionId: workspace.submissionId(groupId),
      );
    }
    if (phase != null && phase.blocked) {
      return TypedMutationResult.unavailable([_valueDiagnostic(phase.message)]);
    }
    return TypedMutationResult.success(
      revision: document.revision,
      value: document.confirmedValue,
    );
  }

  void discardDraft() => workspace.discard(groupId);
  void refreshSnapshot(EditorSnapshot snapshot) => workspace.acceptConfirmed(
    ValueEditDocument.fromSnapshot(
      snapshot,
      identity: workspace.confirmed.identity,
    ),
  );
  void refreshDocument(EditorDocument document) {
    if (!identical(document, workspace.confirmed.metadata.document)) {
      refreshSnapshot(ResultEditorSnapshot(snapshot, document));
    }
  }

  void acceptRemote({required int revision, required skir.DataValue value}) =>
      refreshDocument(
        document.copyWith(revision: revision, confirmedValue: value),
      );
  void acceptRemoteDeletion() =>
      workspace.acceptConfirmed(workspace.confirmed.copyWith(exists: false));
  void useRemote(skir.ValuePath path) => workspace.discardMatching(
    groupId,
    (edit) => edit.paths.any((edited) => edited.overlaps(path)),
  );
  Future<TypedMutationResult> keepLocal(skir.ValuePath path) async {
    workspace.replacePending(
      groupId,
      (observation, edit) => edit.paths.any((edited) => edited.overlaps(path))
          ? edit.copyWith(baseline: observation)
          : edit,
    );
    return commitPolicy == EditorCommitPolicy.applyResource
        ? TypedMutationResult.success(
            revision: document.revision,
            value: document.confirmedValue,
          )
        : flush();
  }

  bool reconcilePendingContract() {
    if (!contractReconciliationPending) return false;
    final candidate = workspace.confirmed.copyWith(
      value: workspace.document.value,
    );
    if (candidate.metadata.validateDraft(candidate.value).isNotEmpty) {
      return false;
    }
    workspace.replacePending(
      groupId,
      (observation, edit) => edit.copyWith(baseline: observation),
    );
    return !contractReconciliationPending;
  }

  bool discardDraftAndAcceptPendingContract() {
    if (!contractReconciliationPending) return false;
    discardDraft();
    return true;
  }

  void markContractUnavailable(String message) =>
      workspace.acceptUnavailable(EditorContractUnavailableException(message));
  Future<bool> retryContractRefresh() async {
    await workspace.refreshConfirmed();
    return workspace.state.failure == null && !contractReconciliationPending;
  }

  @override
  void addListener(VoidCallback listener) => workspace.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      workspace.removeListener(listener);
  @override
  void dispose() => _dispose?.call();
}

/// An interaction view of the common reversible gate.
final class ValueEditingInteraction implements EditorInteractionSession {
  const ValueEditingInteraction(this.path, this.interaction);
  @override
  final skir.ValuePath path;
  final EditInteraction<ValueEditDocument, ValueEdit> interaction;
  @override
  bool get active => interaction.active;
  @override
  Future<void> commit() => interaction.commit();
  @override
  void cancel() => interaction.cancel();
}

final class CallbackEditorSnapshot extends EditorSnapshot {
  const CallbackEditorSnapshot(this.document, this.admit, this.admitDraft);
  @override
  final EditorDocument document;
  final EditorMutationValidator? admit;
  final List<EditorDiagnostic> Function(skir.DataValue)? admitDraft;
  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      admit?.call(path, value) ??
      EditorMutationResult.invalid([
        _valueDiagnostic("No editor admission policy is installed", path),
      ]);
  @override
  List<EditorDiagnostic> validateDraft(skir.DataValue value) =>
      admitDraft?.call(value) ?? super.validateDraft(value);
}

/// Explicit callback boundary for local values and deterministic fixtures.
final class CallbackValueEditPersistence extends ValueEditPersistence {
  CallbackValueEditPersistence(this.snapshot, this.committer);
  final EditorSnapshot snapshot;
  final EditorCommitter? committer;
  @override
  final EditorResourceKey key = EditorResourceKey(
    scope: null,
    identity: Object(),
  );
  @override
  Set<Object> get reservations => {};
  @override
  Future<EditorSnapshot?> refreshSnapshot() async => snapshot;
  @override
  Future<ValueEditDocument> observeForCommit(ValueEditDocument known) async =>
      known;
  @override
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) => PreparedCommit(
    id: Object(),
    label: "Apply value",
    send: () async {
      final result =
          await committer?.call(commit) ??
          TypedMutationResult.success(
            revision: commit.expectedRevision + 1,
            value: commit.rootValue,
          );
      return switch (result) {
        MutationUncertain(:final message, :final cause, :final stackTrace) =>
          SubmissionResult.uncertain(
            message: message,
            cause: cause,
            stackTrace: stackTrace,
          ),
        MutationSuccess() => SubmissionResult.confirmed(result),
        _ => SubmissionResult.rejected(
          message: "Value edit rejected",
          response: result,
        ),
      };
    },
  );
}

EditorDiagnostic _valueDiagnostic(String message, [skir.ValuePath? path]) =>
    EditorDiagnostic(
      code: EditorDiagnosticCode.mutationConflict,
      message: message,
      path: path ?? editorRootPath,
    );
