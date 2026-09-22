import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension ElementCommands on AuthoringSession {
  Future<skir.ApplyAuthoringBatchResponse> applyPreviewed(
    Iterable<skir.AuthoringOperation> operations,
  ) async {
    final batch = operations.toList(growable: false);
    (await preview(batch)).requireValid();
    return apply(batch);
  }
}

extension on skir.PreviewAuthoringBatchResponse {
  void requireValid() {
    switch (this) {
      case skir.PreviewAuthoringBatchResponse_validWrapper():
        return;
      case skir.PreviewAuthoringBatchResponse_conflictWrapper():
        throw ApiException.conflict(
          "Authoring state changed while validating the operation",
        );
      case skir.PreviewAuthoringBatchResponse_invalidWrapper(:final value):
        throw ApiException.badRequest(
          value.diagnostics.map((diagnostic) => diagnostic.message).join("; "),
        );
      case skir.PreviewAuthoringBatchResponse_catalogChangedWrapper():
        throw ApiException.conflict("The Realm catalog changed");
      case skir.PreviewAuthoringBatchResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.PreviewAuthoringBatchResponse_unknown():
        throw ApiException.unknownResponseMessage();
    }
  }
}
