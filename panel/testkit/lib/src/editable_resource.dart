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

/// Mutable remote fixture. Each save captures its own immutable request.
class FakeEditableResource implements EditableResource {
  FakeEditableResource({
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
  Future<EditorSnapshot?> refresh() async => load == null ? current : load!();

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit changes,
    void Function(TypedMutationResult) accept,
  ) => IndependentMutation(
    PendingCommit(
      resources: reservations,
      prepare: () => PreparedCommit<TypedMutationResult>(
        id: Object(),
        label: "Test resource",
        resources: reservations,
        send: () async => SubmissionResult.confirmed(await commit(changes)),
        integrate: (result) async {
          if (result case SubmissionConfirmed(:final value)) {
            if (value case MutationSuccess(
              :final revision,
              value: final data,
            )) {
              current = FakeEditorSnapshot(
                snapshot.document.copyWith(
                  revision: revision,
                  confirmedValue: data,
                ),
                validation: snapshot.validate,
                draftValidation: snapshot.validateDraft,
              );
            }
            accept(value);
          }
        },
      ),
    ),
  );
}

ResourceEditorTarget fakeEditorTarget({
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
  return ResourceEditorTarget(
    targetId: targetId,
    label: label,
    snapshot: snapshot,
    commitPolicy: commitPolicy,
    resource: FakeEditableResource(
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
