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
    skir.CommitPreparedEditRequest,
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

  /// Names one save attempt: every resend of the request it prepares carries
  /// the same key, and the next capture gets a new one.
  @override
  PreparedCommit<EditSettlement<AuthoringDocument>> prepare(
    EditCapture<AuthoringDocument, RealmPreparedEdit> capture,
  ) {
    final compiled = const RealmEditModel().compose(capture);
    final catalog = capture.baseline.catalog;
    return request(
      skir.CommitPreparedEditRequest(
        edit: compiled.request,
        submission: uuid.v4(),
      ),
    ).mapResponse(
      (response) => switch (response) {
        skir.CommitPreparedEditResponse_committedWrapper(:final value)
            when value.generation == catalog.snapshot.generation =>
          EditSettlement.confirmed(
            AuthoringDocument.fromState(value, catalog: catalog),
          ),
        // A resend after a catalog change answers with the saved state under
        // the new catalog, which this request's catalog cannot read. The save
        // landed; the session's catalog refresh brings the state.
        skir.CommitPreparedEditResponse_committedWrapper() =>
          const EditSettlement.confirmed(null),
        _ => response.editSettlement,
      },
    );
  }
}

/// The settlement of every reply but `committed`, which
/// [RealmEditPersistence.prepare] settles with the catalog it was composed
/// against.
extension RealmResponseSettlement on skir.CommitPreparedEditResponse {
  EditSettlement<AuthoringDocument> get editSettlement => switch (this) {
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
