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
    required this.typeCatalog,
    required this.confirmedValue,
    required this.revision,
    this.mergePolicies = const {},
    this.diagnostics = const [],
    this.readOnly = false,
  }) : assert(revision >= 0, "Revision must not be negative.");

  final TypeExpression rootType;
  final TypeCatalog typeCatalog;
  final DataValue confirmedValue;
  final int revision;
  final Map<DataPath, EditorMergePolicy> mergePolicies;
  final List<TypeDiagnostic> diagnostics;
  final bool readOnly;

  bool hasSameContent(EditorDocument other) =>
      hasSameMetadata(other) &&
      confirmedValue == other.confirmedValue &&
      revision == other.revision;

  bool hasSameMetadata(EditorDocument other) =>
      typeExpressionsEqual(rootType, other.rootType) &&
      typeCatalog == other.typeCatalog &&
      mapEquals(mergePolicies, other.mergePolicies) &&
      listEquals(diagnostics, other.diagnostics) &&
      readOnly == other.readOnly;

  EditorDocument copyWith({
    TypeExpression? rootType,
    TypeCatalog? typeCatalog,
    DataValue? confirmedValue,
    int? revision,
    Map<DataPath, EditorMergePolicy>? mergePolicies,
    List<TypeDiagnostic>? diagnostics,
    bool? readOnly,
  }) => EditorDocument(
    rootType: rootType ?? this.rootType,
    typeCatalog: typeCatalog ?? this.typeCatalog,
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
  final DataValue rootValue;
  final DataValue baseValue;
  final Set<DataPath> changedPaths;
  final List<EditorStructuralMutation> mutations;
}

/// Describes one structural operation included in an [EditorCommit].
///
/// These operations preserve intent that a value diff cannot reliably recover,
/// such as list movement, duplication, and concrete type replacement. The path
/// is relative to the commit root and [prefixedBy] is used when a nested
/// operation becomes part of a larger structural edit.
sealed class EditorStructuralMutation {
  const EditorStructuralMutation(this.path);

  final DataPath path;

  EditorStructuralMutation prefixedBy(DataPath prefix) {
    final next = prefix.followedBy(path);
    return switch (this) {
      EditorSetValue(:final value) => EditorSetValue(next, value),
      EditorInsertListItems(:final index, :final values) =>
        EditorInsertListItems(next, index, values),
      EditorRemoveListItems(:final index, :final count) =>
        EditorRemoveListItems(next, index, count),
      EditorReorderListItems(
        :final sourceIndex,
        :final count,
        :final destinationIndex,
      ) =>
        EditorReorderListItems(next, sourceIndex, count, destinationIndex),
      EditorDuplicateListItems(
        :final sourceIndex,
        :final count,
        :final destinationIndex,
      ) =>
        EditorDuplicateListItems(next, sourceIndex, count, destinationIndex),
      EditorPutMapEntries(:final entries) => EditorPutMapEntries(next, entries),
      EditorRemoveMapEntries(:final keys) => EditorRemoveMapEntries(next, keys),
      EditorReplaceConcreteType(:final concreteType, :final value) =>
        EditorReplaceConcreteType(next, concreteType, value),
    };
  }
}

final class EditorSetValue extends EditorStructuralMutation {
  const EditorSetValue(super.path, this.value);

  final DataValue value;
}

final class EditorInsertListItems extends EditorStructuralMutation {
  const EditorInsertListItems(super.path, this.index, this.values);

  final int index;
  final List<DataValue> values;
}

final class EditorRemoveListItems extends EditorStructuralMutation {
  const EditorRemoveListItems(super.path, this.index, this.count);

  final int index;
  final int count;
}

final class EditorReorderListItems extends EditorStructuralMutation {
  const EditorReorderListItems(
    super.path,
    this.sourceIndex,
    this.count,
    this.destinationIndex,
  );

  final int sourceIndex;
  final int count;
  final int destinationIndex;
}

final class EditorDuplicateListItems extends EditorStructuralMutation {
  const EditorDuplicateListItems(
    super.path,
    this.sourceIndex,
    this.count,
    this.destinationIndex,
  );

  final int sourceIndex;
  final int count;
  final int destinationIndex;
}

final class EditorPutMapEntries extends EditorStructuralMutation {
  const EditorPutMapEntries(super.path, this.entries);

  final List<DataMapEntry> entries;
}

final class EditorRemoveMapEntries extends EditorStructuralMutation {
  const EditorRemoveMapEntries(super.path, this.keys);

  final List<DataValue> keys;
}

final class EditorReplaceConcreteType extends EditorStructuralMutation {
  const EditorReplaceConcreteType(super.path, this.concreteType, this.value);

  final ResolvedTypeRef concreteType;
  final DataValue value;
}
