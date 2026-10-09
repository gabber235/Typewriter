import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
///
/// Type metadata, merge policy, diagnostics, and read only status travel with
/// that observation. The document is immutable and owned by the editor source;
/// presentation code may retain it as a stable snapshot but must not infer
/// local unsaved content from it.
final class EditorDocument {
  const EditorDocument({
    required this.rootType,
    required this.catalog,
    required this.confirmedValue,
    required this.revision,
    this.mergePolicies = const {},
    this.diagnostics = const [],
    this.readOnly = false,
  }) : assert(revision >= 0, "Revision must not be negative.");

  final skir.TypeUse rootType;
  final CheckedEditorCatalog catalog;
  final skir.DataValue confirmedValue;
  final int revision;
  final Map<skir.ValuePath, EditorMergePolicy> mergePolicies;
  final List<EditorDiagnostic> diagnostics;
  final bool readOnly;

  bool hasSameContent(EditorDocument other) =>
      hasSameMetadata(other) &&
      confirmedValue == other.confirmedValue &&
      revision == other.revision;

  bool hasSameMetadata(EditorDocument other) =>
      rootType == other.rootType &&
      catalog == other.catalog &&
      mapEquals(mergePolicies, other.mergePolicies) &&
      listEquals(diagnostics, other.diagnostics) &&
      readOnly == other.readOnly;

  EditorDocument copyWith({
    skir.TypeUse? rootType,
    CheckedEditorCatalog? catalog,
    skir.DataValue? confirmedValue,
    int? revision,
    Map<skir.ValuePath, EditorMergePolicy>? mergePolicies,
    List<EditorDiagnostic>? diagnostics,
    bool? readOnly,
  }) => EditorDocument(
    rootType: rootType ?? this.rootType,
    catalog: catalog ?? this.catalog,
    confirmedValue: confirmedValue ?? this.confirmedValue,
    revision: revision ?? this.revision,
    mergePolicies: mergePolicies ?? this.mergePolicies,
    diagnostics: diagnostics ?? this.diagnostics,
    readOnly: readOnly ?? this.readOnly,
  );
}

/// An immutable persistence request captured from one editor state.
///
/// `expectedRevision` identifies the canonical `baseValue` that the request
/// was built against. `rootValue` is the proposed result, and
/// `localRevision` lets the owner distinguish edits made after capture.
/// `changedPaths` and `mutations` describe the intended delta. A committer
/// must treat this as one consistency boundary and return a typed result rather
/// than implying acceptance from completion alone.
final class EditorCommit {
  const EditorCommit({
    required this.expectedRevision,
    required this.localRevision,
    required this.rootValue,
    required this.baseValue,
    required this.changedPaths,
    this.mutations = const [],
  }) : assert(expectedRevision >= 0, "Expected revision must not be negative."),
       assert(localRevision >= 0, "Local revision must not be negative.");

  final int expectedRevision;
  final int localRevision;
  final skir.DataValue rootValue;
  final skir.DataValue baseValue;
  final Set<skir.ValuePath> changedPaths;
  final List<EditorStructuralMutation> mutations;
}

/// Describes one structural operation included in an [EditorCommit].
///
/// These operations preserve intent that a value diff cannot reliably recover,
/// such as map membership and concrete type replacement. The path is relative
/// to the commit root and [prefixedBy] is used when a nested operation becomes
/// part of a larger structural edit.
sealed class EditorStructuralMutation {
  const EditorStructuralMutation(this.path);

  final skir.ValuePath path;

  EditorStructuralMutation prefixedBy(skir.ValuePath prefix) {
    final next = prefix.followedBy(path);
    return switch (this) {
      EditorSetValue(:final value) => EditorSetValue(next, value),
      EditorPutMapEntries(:final entries) => EditorPutMapEntries(next, entries),
      EditorRemoveMapEntries(:final keys) => EditorRemoveMapEntries(next, keys),
      EditorReplaceConcreteType(:final concreteType, :final value) =>
        EditorReplaceConcreteType(next, concreteType, value),
    };
  }
}

final class EditorSetValue extends EditorStructuralMutation {
  const EditorSetValue(super.path, this.value);

  final skir.DataValue value;
}

final class EditorPutMapEntries extends EditorStructuralMutation {
  const EditorPutMapEntries(super.path, this.entries);

  final List<skir.MapRow> entries;
}

final class EditorRemoveMapEntries extends EditorStructuralMutation {
  const EditorRemoveMapEntries(super.path, this.keys);

  final List<skir.DataValue> keys;
}

final class EditorReplaceConcreteType extends EditorStructuralMutation {
  const EditorReplaceConcreteType(super.path, this.concreteType, this.value);

  final skir.NamedTypeUse concreteType;
  final skir.DataValue value;
}
