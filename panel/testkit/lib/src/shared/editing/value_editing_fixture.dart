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

/// Builds a [ValueEditing] that owns its workspace and, unless [workspace] is
/// supplied, a private work session. Disposing the view releases both.
///
/// Without [persistence], commits go to [commit] or succeed with the proposed
/// value. Without [snapshot], [validation] admits path writes and every write
/// is rejected when it is absent.
ValueEditing fakeValueEditing({
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
  return ValueEditing.fromWorkspace(
    owner,
    group,
    onDispose: () {
      owner.dispose();
      if (workspace == null) (session as ScopedWorkSession).dispose();
    },
  );
}

/// Editor metadata whose admission comes from optional callbacks.
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
        EditorDiagnostic(
          code: EditorDiagnosticCode.mutationConflict,
          message: "No editor admission policy is installed",
          path: path,
        ),
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

EditorMutationResult acceptTestEditorMutation(
  skir.ValuePath path,
  skir.DataValue value,
) => EditorMutationResult.applied(value);

final class FakeEditorSnapshot extends EditorSnapshot {
  const FakeEditorSnapshot(
    this.document, {
    required this.validation,
    this.draftValidation,
  });

  @override
  final EditorDocument document;
  final EditorMutationValidator validation;
  final List<EditorDiagnostic> Function(skir.DataValue)? draftValidation;

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      validation(path, value);

  @override
  List<EditorDiagnostic> validateDraft(skir.DataValue value) =>
      draftValidation?.call(value) ?? const [];
}

/// Scripted canonical observations and replies, with production editing ownership.
class ScriptedValuePersistence extends ValueEditPersistence {
  ScriptedValuePersistence({
    required this.key,
    required this.current,
    required this.commit,
    this.load,
  });
  @override
  final EditorResourceKey key;
  EditorSnapshot? current;
  final EditorCommitter commit;
  Future<EditorSnapshot?> Function()? load;
  @override
  Set<Object> get reservations => {key};
  @override
  Future<EditorSnapshot?> refreshSnapshot() async =>
      load == null ? current : load!();
  @override
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit changes,
  ) => PreparedCommit(
    id: Object(),
    label: "Apply scripted value",
    resources: reservations,
    send: () async {
      final result = await commit(changes);
      return switch (result) {
        MutationSuccess() => SubmissionResult.confirmed(result),
        MutationUncertain(:final message, :final cause, :final stackTrace) =>
          SubmissionResult.uncertain(
            message: message,
            cause: cause,
            stackTrace: stackTrace,
          ),
        _ => SubmissionResult.rejected(
          message: "Scripted value rejected",
          response: result,
        ),
      };
    },
    integrate: (result) async {
      if (result case SubmissionConfirmed(
        value: MutationSuccess(:final revision, value: final data),
      )) {
        current = FakeEditorSnapshot(
          snapshot.document.copyWith(revision: revision, confirmedValue: data),
          validation: snapshot.validate,
          draftValidation: snapshot.validateDraft,
        );
      }
    },
  );
}

ValueEditingRegistration fakeEditorTarget({
  required Object targetId,
  required String label,
  required EditorDocument document,
  required EditorCommitter commit,
  required EditorMutationValidator validation,
  Object? scope,
  EditorCommitPolicy commitPolicy = EditorCommitPolicy.autosaveChanges,
  List<EditorDiagnostic> Function(skir.DataValue)? validateDraft,
}) {
  final snapshot = FakeEditorSnapshot(
    document,
    validation: validation,
    draftValidation: validateDraft,
  );
  return ValueEditingRegistration(
    targetId: targetId,
    label: label,
    snapshot: snapshot,
    commitPolicy: commitPolicy,
    persistence: ScriptedValuePersistence(
      key: EditorResourceKey(
        scope: scope,
        identity: targetId is SelectableIdentifier
            ? targetId.resourceId
            : targetId,
      ),
      current: snapshot,
      commit: commit,
    ),
  );
}
