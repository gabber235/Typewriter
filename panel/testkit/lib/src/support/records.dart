import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Record ids as SurrealQL writes them.
extension RecordKeySurrealQl on skir.RecordIdKey {
  /// The key alone as it appears in a SurrealQL record id, after the
  /// `table:` prefix.
  String get surrealQl => skir.RecordId(
    table: "ignored",
    key: this,
  ).toSurrealQl().substring("ignored:".length);
}

/// Book entries reconciled by revision, the way canonical read models
/// reconcile them.
extension ReconcileBooks on List<({String id, int revision, String name})>? {
  /// Reconciles [incoming] into these entries, keyed by id and ordered by
  /// revision, naming each entry `book <id>`.
  CanonicalReconciliation<({String id, int revision, String name})>
  reconcileBook(({String id, int revision, String name}) incoming) =>
      reconcileRevision(
        incoming: incoming,
        keyOf: (entry) => entry.id,
        revisionOf: (entry) => entry.revision,
        identityOf: (entry) => "book ${entry.id}",
        entityName: "book",
      );
}
