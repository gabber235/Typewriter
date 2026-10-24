import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_document.freezed.dart";

/// Defines how local and remote values may be combined at a path.
///
/// `atomic` and `orderedList` preserve the local value and report a conflict
/// when both sides changed. `record` reconciles fields independently.
/// `set` combines membership changes while removing duplicates. The policy is
/// part of the document contract because reconciliation must use the same
/// semantics as the editor that produced the draft.
enum EditorMergePolicy { atomic, record, set, orderedList }

/// The complete canonical snapshot used to interpret an editor draft.
///
/// `confirmedValue` and `revision` are one atomic observation. A revision is
/// meaningful only with the value it identifies. Advancing one without the
/// other could make a commit target the wrong canonical content, so callers
/// replace them together through `copyWith` or a new `EditorDocument`.
/// Equality compares the whole observation, while [hasSameMetadata] ignores
/// the value and revision.
///
/// Type metadata, merge policy, diagnostics, and read only status travel with
/// that observation. The document is immutable and owned by the editor source;
/// presentation code may retain it as a stable snapshot but must not infer
/// local unsaved content from it.
@freezed
abstract class EditorDocument with _$EditorDocument {
  @Assert("revision >= 0", "Revision must not be negative.")
  const factory EditorDocument({
    required skir.TypeUse rootType,
    required CheckedEditorCatalog catalog,
    required skir.DataValue confirmedValue,
    required int revision,
    @Default({}) Map<skir.ValuePath, EditorMergePolicy> mergePolicies,
    @Default([]) List<EditorDiagnostic> diagnostics,
    @Default(false) bool readOnly,
  }) = _EditorDocument;
  const EditorDocument._();

  bool hasSameMetadata(EditorDocument other) =>
      rootType == other.rootType &&
      catalog == other.catalog &&
      mapEquals(mergePolicies, other.mergePolicies) &&
      listEquals(diagnostics, other.diagnostics) &&
      readOnly == other.readOnly;
}

/// An immutable persistence request captured from one editor state.
///
/// `expectedRevision` identifies the canonical `baseValue` that the request
/// was built against. `rootValue` is the proposed result, and
/// `localRevision` lets the owner distinguish edits made after capture.
/// `changedPaths` and `mutations` describe the intended delta. A committer
/// must treat this as one consistency boundary and return a typed result rather
/// than implying acceptance from completion alone.
@freezed
abstract class EditorCommit with _$EditorCommit {
  @Assert("expectedRevision >= 0", "Expected revision must not be negative.")
  @Assert("localRevision >= 0", "Local revision must not be negative.")
  const factory EditorCommit({
    required int expectedRevision,
    required int localRevision,
    required skir.DataValue rootValue,
    required skir.DataValue baseValue,
    required Set<skir.ValuePath> changedPaths,
    @Default([]) List<EditorSetValue> mutations,
  }) = _EditorCommit;
}

/// Describes one value assignment included in an [EditorCommit].
///
/// The path is relative to the commit root.
@freezed
abstract class EditorSetValue with _$EditorSetValue {
  const factory EditorSetValue(skir.ValuePath path, skir.DataValue value) =
      _EditorSetValue;
}
