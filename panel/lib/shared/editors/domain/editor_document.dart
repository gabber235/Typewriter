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
    this.group,
  }) : assert(expectedRevision >= 0, "Expected revision must not be negative."),
       assert(localRevision >= 0, "Local revision must not be negative.");

  final int expectedRevision;
  final int localRevision;
  final DataValue rootValue;
  final Set<DataPath> changedPaths;
  final String? group;
}
