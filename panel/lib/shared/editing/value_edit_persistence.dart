import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Adapts one typed value resource to shared editing capture and settlement.
///
/// Subclasses supply canonical snapshots and a prepared value mutation. This
/// adapter preserves the resource identity while translating revision checks,
/// changed paths and typed mutation outcomes into workspace semantics.
abstract class ValueEditPersistence
    implements EditPersistence<ValueEditDocument, ValueEdit> {
  const ValueEditPersistence();
  EditorResourceKey get key;
  Set<Object> get reservations;
  Future<EditorSnapshot?> refreshSnapshot();
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit commit,
  );
  @override
  Set<Object> reservationsFor(Iterable<ValueEdit> pendingEdits) => reservations;
  @override
  Future<ValueEditDocument> observeForCommit(ValueEditDocument known) async {
    final snapshot = await refreshSnapshot();
    return snapshot == null
        ? known.copyWith(exists: false)
        : ValueEditDocument.fromSnapshot(snapshot, identity: key);
  }

  @override
  Future<ValueEditDocument> refresh() async {
    final snapshot = await refreshSnapshot();
    if (snapshot == null) throw StateError("The resource was deleted");
    return ValueEditDocument.fromSnapshot(snapshot, identity: key);
  }

  @override
  PreparedCommit<EditSettlement<ValueEditDocument>> prepare(
    EditCapture<ValueEditDocument, ValueEdit> capture,
  ) {
    final commit = EditorCommit(
      expectedRevision: capture.baseline.revision,
      localRevision: capture.operations.last,
      rootValue: capture.proposed.value,
      baseValue: capture.baseline.value,
      changedPaths: {for (final edit in capture.edits) ...edit.paths},
      mutations: [for (final edit in capture.edits) ...edit.mutations],
    );
    return prepareValue(
      capture.baseline.metadata,
      commit,
    ).mapResponse((result) => result.editSettlement(capture.baseline));
  }
}

extension ValueMutationSettlement on TypedMutationResult {
  EditSettlement<ValueEditDocument> editSettlement(ValueEditDocument baseline) {
    ValueEditDocument observed(int revision, skir.DataValue value) =>
        ValueEditDocument.fromSnapshot(
          ResultEditorSnapshot(
            baseline.metadata,
            baseline.metadata.document.copyWith(
              revision: revision,
              confirmedValue: value,
            ),
          ),
          identity: baseline.identity,
        );
    return switch (this) {
      MutationSuccess(:final revision, :final value) =>
        EditSettlement.confirmed(observed(revision, value)),
      MutationConflict(:final actualRevision, :final actualValue) =>
        EditSettlement.conflict(
          observation: observed(actualRevision, actualValue),
          evidence: ValueConflictEvidence(response: this),
        ),
      MutationInvalid(:final diagnostics) ||
      MutationUnavailable(
        :final diagnostics,
      ) => EditSettlement.rejected(diagnostics: diagnostics),
      MutationPermissionDenied(:final message) => EditSettlement.rejected(
        diagnostics: [
          EditorDiagnostic(
            code: EditorDiagnosticCode.invalidValue,
            message: message,
          ),
        ],
      ),
      MutationUncertain() => throw StateError(
        "Delivery uncertainty belongs to the submission",
      ),
    };
  }
}

/// Updates canonical content while keeping validation with its interpretation.
final class ResultEditorSnapshot extends EditorSnapshot
    implements EditorContractSnapshot {
  ResultEditorSnapshot(EditorSnapshot delegate, this.document)
    : delegate = delegate is ResultEditorSnapshot
          ? delegate.delegate
          : delegate;
  final EditorSnapshot delegate;
  @override
  final EditorDocument document;
  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) =>
      delegate.validate(path, value);
  @override
  List<EditorDiagnostic> validateDraft(skir.DataValue value) =>
      delegate.validateDraft(value);
  @override
  bool contractCompatibleWith(EditorSnapshot candidate) =>
      delegate is EditorContractSnapshot
      ? (delegate as EditorContractSnapshot).contractCompatibleWith(candidate)
      : document.rootType == candidate.document.rootType &&
            document.catalog.snapshot.generation ==
                candidate.document.catalog.snapshot.generation;
}
