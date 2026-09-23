import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class RealmAuthoringSelection {
  ResourceDefinitionId get resourceDefinition;

  List<PresentationDefinition> get presentations;

  List<PresentationCollectionSource> get collections;

  List<TypeDiagnostic> get presentationDiagnostics;
}

final class RealmAuthoringMultiInspectionDefinition
    implements MultiInspectionDefinition {
  const RealmAuthoringMultiInspectionDefinition(this.resourceDefinition);

  final ResourceDefinitionId resourceDefinition;

  @override
  PresentationId get id => PresentationId(
    namespace: "typewriter.authoring",
    name: resourceDefinition.value,
  );

  @override
  bool isCompatibleWith(MultiInspectionDefinition other) =>
      other is RealmAuthoringMultiInspectionDefinition &&
      other.resourceDefinition == resourceDefinition;

  @override
  TypeResult<InspectionContent> build(
    List<EditableSelectable> selection,
    InspectionBuildContext context,
  ) {
    final resources = selection.whereType<RealmAuthoringSelection>().toList();
    if (resources.length != selection.length ||
        resources.any(
          (resource) => resource.resourceDefinition != resourceDefinition,
        )) {
      return _failure("Selected resources use different Realm definitions");
    }
    final catalog = selection.mergedTypeCatalog;
    final mergedCatalog = catalog.valueOrNull;
    if (mergedCatalog == null) return TypeResult.failure(catalog.diagnostics);
    final presentations = resources._sharedPresentations;
    if (presentations == null) {
      return _failure(
        "Selected resources use inconsistent Realm presentations",
      );
    }
    final collections = resources._mergedCollections;
    final mergedCollections = collections.valueOrNull;
    if (mergedCollections == null) {
      return TypeResult.failure(collections.diagnostics);
    }
    final owner = context.multiEditorFor(
      selection,
      rootType: selection.first.document.rootType,
      typeCatalog: mergedCatalog,
    );
    return TypeResult.success(
      InspectionContent(
        model: PresentationModel.editor(
          owner: owner,
          presentations: presentations,
          collections: mergedCollections,
          diagnostics: resources
              .expand((resource) => resource.presentationDiagnostics)
              .toList(growable: false),
        ),
      ),
    );
  }
}

extension on List<RealmAuthoringSelection> {
  List<PresentationDefinition>? get _sharedPresentations {
    final firstValue = firstOrNull?.presentations;
    if (firstValue == null) return null;
    const equality = ListEquality<PresentationDefinition>();
    return skip(1).every(
          (resource) => equality.equals(firstValue, resource.presentations),
        )
        ? firstValue
        : null;
  }

  TypeResult<List<PresentationCollectionSource>> get _mergedCollections {
    final sourceIds = firstOrNull?.collections
        .map((source) => source.id)
        .toSet();
    if (sourceIds == null ||
        skip(1).any(
          (resource) =>
              !const SetEquality<PresentationCollectionSourceId>().equals(
                sourceIds,
                resource.collections.map((source) => source.id).toSet(),
              ),
        )) {
      return _failure("Selected resources use inconsistent collections");
    }
    final merged = <PresentationCollectionSource>[];
    for (final sourceId in sourceIds) {
      final result = mergeAuthoringCollectionSources(
        map(
          (resource) => resource.collections.singleWhere(
            (source) => source.id == sourceId,
          ),
        ),
      );
      final source = result.valueOrNull;
      if (source == null) return TypeResult.failure(result.diagnostics);
      merged.add(source);
    }
    return TypeResult.success(List.unmodifiable(merged));
  }
}

TypeResult<T> _failure<T>(String message) => TypeResult.failure([
  TypeDiagnostic(
    code: TypeDiagnosticCode.invalidPresentation,
    message: message,
    pathPresent: false,
  ),
]);
