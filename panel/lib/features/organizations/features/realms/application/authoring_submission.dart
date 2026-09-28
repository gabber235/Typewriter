import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension AuthoringCommitResult on skir.ApplyAuthoringBatchResponse {
  Future<TypedMutationResult> acceptCommit(
    EditorCommit commit,
    EditorDocument? actual,
  ) async => switch (this) {
    skir.ApplyAuthoringBatchResponse_appliedWrapper() =>
      actual == null
          ? unavailableMutation(
              "The resource no longer exists",
              targetDeleted: true,
            )
          : TypedMutationResult.success(
              revision: actual.revision,
              value: actual.confirmedValue,
            ),
    skir.ApplyAuthoringBatchResponse_conflictWrapper() =>
      actual == null
          ? unavailableMutation(
              "The resource no longer exists",
              targetDeleted: true,
            )
          : TypedMutationResult.conflict(
              expectedRevision: commit.expectedRevision,
              actualRevision: actual.revision,
              actualValue: actual.confirmedValue,
            ),
    _ => toMutationFailure(
      unavailableMessage: "The resource could not be saved",
    ),
  };
}
