import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Adapts the Realm request boundary without owning local work or delivery.
final class RealmEditPersistence
    implements EditPersistence<AuthoringDocument, RealmPreparedEdit> {
  const RealmEditPersistence({
    required this.request,
    required this.observe,
    required this.reservations,
  });
  final PreparedCommit<skir.CommitPreparedEditResponse> Function(
    skir.PreparedEdit,
  )
  request;
  final Future<AuthoringDocument> Function() observe;
  final Set<Object> Function(Iterable<skir.PreparedEdit>) reservations;
  @override
  Set<Object> reservationsFor(Iterable<RealmPreparedEdit> pendingEdits) =>
      reservations(pendingEdits.map((edit) => edit.request));
  @override
  Future<AuthoringDocument> observeForCommit(AuthoringDocument known) async =>
      known;
  @override
  Future<AuthoringDocument> refresh() => observe();
  @override
  PreparedCommit<EditSettlement<AuthoringDocument>> prepare(
    EditCapture<AuthoringDocument, RealmPreparedEdit> capture,
  ) {
    final branch = AuthoringEdit.fromDocument(capture.baseline);
    for (final edit in capture.edits) {
      branch.applyPrepared(edit.request);
    }
    final prepared = request(branch.prepare());
    return prepared.mapResponse((response) => response.editSettlement);
  }
}

extension RealmResponseSettlement on skir.CommitPreparedEditResponse {
  EditSettlement<AuthoringDocument> get editSettlement => switch (this) {
    skir.CommitPreparedEditResponse_resultWrapper(
      value: skir.CommitResult.committed,
    ) =>
      const EditSettlement.accepted(),
    skir.CommitPreparedEditResponse_resultWrapper(
      value: skir.CommitResult_conflictWrapper(:final value),
    ) =>
      EditSettlement.conflict(
        expected: value.firstOrNull?.expected,
        actual: value.firstOrNull?.actual,
        diagnostics: [
          EditorDiagnostic(
            code: EditorDiagnosticCode.mutationConflict,
            message: rejectionMessage,
          ),
        ],
      ),
    skir.CommitPreparedEditResponse_resultWrapper(
      value: skir.CommitResult_catalogChangedWrapper(),
    ) =>
      const EditSettlement.rejected(contractChanged: true),
    _ => EditSettlement.rejected(
      cause: this,
      diagnostics: [
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: rejectionMessage,
        ),
      ],
    ),
  };
}
