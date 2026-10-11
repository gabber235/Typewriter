import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
