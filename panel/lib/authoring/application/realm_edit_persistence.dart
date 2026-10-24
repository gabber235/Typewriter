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
    final compiled = const RealmEditModel().compose(capture);
    return request(compiled.request)
        .mapResponse((response) => response.editSettlement);
  }
}

extension RealmResponseSettlement on skir.CommitPreparedEditResponse {
  EditSettlement<AuthoringDocument> get editSettlement => switch (this) {
    skir.CommitPreparedEditResponse.committed =>
      const EditSettlement.accepted(),
    skir.CommitPreparedEditResponse_conflictErrorWrapper(:final value) =>
      EditSettlement.conflict(
        evidence: AuthoringConflictEvidence(
          facts: value.toList(),
          diagnostics: [
            EditorDiagnostic(
              code: EditorDiagnosticCode.mutationConflict,
              message: rejectionMessage,
            ),
          ],
        ),
      ),
    skir.CommitPreparedEditResponse_catalogChangedErrorWrapper() =>
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
