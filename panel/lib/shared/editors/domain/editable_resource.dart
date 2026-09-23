import "package:typewriter_panel/typewriter_panel.dart";

/// Bridges an editor owner to one resource without owning its live state.
///
/// Implementations retain the resource identity and its external scope, then
/// create snapshots for the editor and prepare commits for the persistence
/// boundary. [refresh] supplies the next authoritative observation. A null
/// result means the resource is confirmed deleted. [prepare] must encode and
/// validate against the supplied snapshot, while [accept] receives the typed
/// outcome when the boundary integrates its response. [reservations] prevents
/// concurrent mutation batches from claiming overlapping resources.
abstract interface class EditableResource {
  /// Stable identity used to coordinate resource access and mutation batches.
  EditorResourceKey get key;
  Set<Object> get reservations;

  /// Fetches the current authoritative snapshot, or null after confirmed deletion.
  Future<EditorSnapshot?> refresh();

  /// Captures one commit against [snapshot] for later delivery.
  ///
  /// The returned intent owns the external operation. It must not read mutable
  /// editor state during delivery, and [accept] is the integration callback for
  /// the resulting typed outcome.
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit commit,
    void Function(TypedMutationResult) accept,
  );
}

/// Immutable document and validation context from one resource revision.
///
/// Editor owners use a snapshot to keep canonical content, revision metadata,
/// and resource specific validation aligned while a commit is prepared. The
/// default mutation validation resolves [DataPath] through the document type
/// catalog. Resource implementations override validation when their domain
/// imposes additional rules.

abstract class EditorSnapshot {
  const EditorSnapshot();

  /// Canonical content and metadata observed at one resource revision.
  EditorDocument get document;

  /// Applies resource specific validation to the complete local draft.
  List<TypeDiagnostic> validateDraft(DataValue value) => const [];

  /// Validates one path and value against the snapshot's type context.
  EditorMutationResult validate(DataPath path, DataValue value) =>
      document.rootType.validateEditorMutation(
        path,
        value,
        registry: TypeRegistry(document.typeCatalog),
      );
}

/// Marks a snapshot whose interpretation contract can change independently.
///
/// The editor owner pins the installed snapshot. A replacement is accepted
/// immediately only when [contractCompatibleWith] proves that the existing
/// draft keeps the same meaning. Incompatible replacements stay pending until
/// the user reconciles or discards the draft explicitly.
abstract interface class EditorContractSnapshot implements EditorSnapshot {
  bool contractCompatibleWith(EditorSnapshot candidate);
}

/// Reports that an exact resource contract cannot currently be loaded.
final class EditorContractUnavailableException implements Exception {
  const EditorContractUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Snapshot implementation for resources represented entirely by an [EditorDocument].
final class DocumentEditorSnapshot extends EditorSnapshot {
  const DocumentEditorSnapshot(this.document);

  @override
  final EditorDocument document;
}
