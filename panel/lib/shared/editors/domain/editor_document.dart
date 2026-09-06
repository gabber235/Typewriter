import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

enum EditorMergePolicy { atomic, record, set, orderedList }

final class EditorDocument {
  const EditorDocument({
    required this.rootType,
    required this.typeCatalog,
    required this.confirmedValue,
    required this.revision,
    this.presentations = const [],
    this.collections = const [],
    this.mergePolicies = const {},
    this.commitGroups = const {},
    this.rootPresentation,
    this.diagnostics = const [],
    this.readOnly = false,
  }) : assert(revision >= 0, "Revision must not be negative.");

  final TypeExpression rootType;
  final TypeCatalog typeCatalog;
  final DataValue confirmedValue;
  final int revision;
  final List<PresentationDefinition> presentations;
  final List<PresentationCollectionSource> collections;
  final Map<DataPath, EditorMergePolicy> mergePolicies;
  final Map<DataPath, String> commitGroups;
  final PresentationNode? rootPresentation;
  final List<TypeDiagnostic> diagnostics;
  final bool readOnly;

  bool hasSameContent(EditorDocument other) =>
      hasSameMetadata(other) &&
      confirmedValue == other.confirmedValue &&
      revision == other.revision;

  bool hasSameMetadata(EditorDocument other) =>
      typeExpressionsEqual(rootType, other.rootType) &&
      typeCatalog == other.typeCatalog &&
      listEquals(presentations, other.presentations) &&
      listEquals(collections, other.collections) &&
      mapEquals(mergePolicies, other.mergePolicies) &&
      mapEquals(commitGroups, other.commitGroups) &&
      rootPresentation == other.rootPresentation &&
      listEquals(diagnostics, other.diagnostics) &&
      readOnly == other.readOnly;

  EditorDocument copyWith({
    TypeExpression? rootType,
    TypeCatalog? typeCatalog,
    DataValue? confirmedValue,
    int? revision,
    List<PresentationDefinition>? presentations,
    List<PresentationCollectionSource>? collections,
    Map<DataPath, EditorMergePolicy>? mergePolicies,
    Map<DataPath, String>? commitGroups,
    PresentationNode? rootPresentation,
    bool clearRootPresentation = false,
    List<TypeDiagnostic>? diagnostics,
    bool? readOnly,
  }) => EditorDocument(
    rootType: rootType ?? this.rootType,
    typeCatalog: typeCatalog ?? this.typeCatalog,
    confirmedValue: confirmedValue ?? this.confirmedValue,
    revision: revision ?? this.revision,
    presentations: presentations ?? this.presentations,
    collections: collections ?? this.collections,
    mergePolicies: mergePolicies ?? this.mergePolicies,
    commitGroups: commitGroups ?? this.commitGroups,
    rootPresentation: clearRootPresentation
        ? null
        : rootPresentation ?? this.rootPresentation,
    diagnostics: diagnostics ?? this.diagnostics,
    readOnly: readOnly ?? this.readOnly,
  );
}

final class EditorCommit {
  const EditorCommit({
    required this.expectedRevision,
    required this.localRevision,
    required this.rootValue,
    required this.changedPaths,
    this.mutations = const [],
    this.group,
  }) : assert(expectedRevision >= 0, "Expected revision must not be negative."),
       assert(localRevision >= 0, "Local revision must not be negative.");

  final int expectedRevision;
  final int localRevision;
  final DataValue rootValue;
  final Set<DataPath> changedPaths;
  final List<EditorStructuralMutation> mutations;
  final String? group;
}

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
