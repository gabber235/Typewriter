import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Translates an element batch response into the editor mutation outcome.
///
/// Applied and conflicting responses use the projected authoritative document.
/// A missing document means the element was deleted. Invalid responses remain
/// validation failures, while internal and unknown responses are unavailable so
/// the editor can recover through refresh or explicit retry rather than claiming
/// that the draft was saved.
Future<TypedMutationResult> acceptElementCommit(
  skir.ApplyAuthoringBatchResponse response,
  EditorCommit commit,
  EditorDocument? actual,
) async => switch (response) {
  skir.ApplyAuthoringBatchResponse_appliedWrapper() =>
    actual == null
        ? unavailableMutation(
            "The element no longer exists",
            targetDeleted: true,
          )
        : TypedMutationResult.success(
            revision: actual.revision,
            value: actual.confirmedValue,
          ),
  skir.ApplyAuthoringBatchResponse_conflictWrapper() =>
    actual == null
        ? unavailableMutation(
            "The element no longer exists",
            targetDeleted: true,
          )
        : TypedMutationResult.conflict(
            expectedRevision: commit.expectedRevision,
            actualRevision: actual.revision,
            actualValue: actual.confirmedValue,
          ),
  _ => response.toMutationFailure(
    unavailableMessage: "The element could not be saved",
  ),
};
