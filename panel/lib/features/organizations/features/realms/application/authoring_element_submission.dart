import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Converts changed element editor paths into one optimistic patch operation.
///
/// Value mutations omit the outer editor wrapper path because the protocol
/// addresses the element value directly. Every mutation carries the value that
/// was observed at its path in the captured base. Placement is sent separately
/// with its complete expected and replacement variants, preserving the server's
/// conflict boundary for concurrent edits.
skir.AuthoringOperation elementCommitOperation(
  String id,
  EditorCommit commit,
  TypeCatalog catalog,
) {
  final codec = SkirEditorCodec(TypeRegistry(catalog));
  final mutations = <skir.ExpectedElementValueMutation>[];
  for (final path in commit.changedPaths.where(
    (path) => path.isAtOrBelow(elementValuePath),
  )) {
    final before = path.read(commit.baseValue).valueOrNull!;
    final after = path.read(commit.rootValue).valueOrNull!;
    mutations.add(
      skir.ExpectedElementValueMutation(
        expected: codec.encodeValue(before).valueOrNull!,
        mutation: skir.ElementValueMutation.createSetValue(
          path: codec
              .encodePath(DataPath(path.segments.skip(1).toList()))
              .valueOrNull!,
          value: codec.encodeValue(after).valueOrNull!,
        ),
      ),
    );
  }
  return skir.AuthoringOperation.createPatchElement(
    id: recordId("element:$id"),
    page: null,
    placement:
        commit.changedPaths.any(
          (path) => path.isAtOrBelow(elementPlacementPath),
        )
        ? skir.ElementPlacementChange(
            expected: encodeElementPlacement(
              elementPlacementPath.read(commit.baseValue).valueOrNull!,
            ),
            value: encodeElementPlacement(
              elementPlacementPath.read(commit.rootValue).valueOrNull!,
            ),
          )
        : null,
    valueMutations: mutations,
  );
}

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
