part of "tag_selectable.dart";

const _tagInspectorPresentationId = PresentationId(
  namespace: "typewriter.core",
  name: "tag.default",
);

/// Builds one Realm declared editor for multiple selected tags.
final class TagMultiInspectionDefinition implements MultiInspectionDefinition {
  const TagMultiInspectionDefinition();

  @override
  PresentationId get id => _tagInspectorPresentationId;

  @override
  bool isCompatibleWith(MultiInspectionDefinition other) =>
      other is TagMultiInspectionDefinition;

  @override
  TypeResult<InspectionContent> build(
    List<EditableSelectable> selection,
    InspectionBuildContext context,
  ) {
    final selected = selection.requireAll<TagSelectable>();
    final tags = selected.valueOrNull;
    if (tags == null) return TypeResult.failure(selected.diagnostics);
    final catalog = tags.mergedTypeCatalog;
    final merged = catalog.valueOrNull;
    if (merged == null) return TypeResult.failure(catalog.diagnostics);
    final presentations = tags.sharedTagPresentations;
    if (presentations == null) return _inconsistentTagPresentation();
    final collection = mergeAuthoringCollectionSources(
      tags.map((tag) => tag.tagCollection),
    );
    final shared = collection.valueOrNull;
    if (shared == null) return TypeResult.failure(collection.diagnostics);
    final owner = context.multiEditorFor(
      tags,
      rootType: tags.first.document.rootType,
      typeCatalog: merged,
    );
    return TypeResult.success(
      InspectionContent(
        model: PresentationModel.editor(
          owner: owner,
          presentations: presentations,
          collections: [shared],
          diagnostics: tags
              .expand((tag) => tag.presentationDiagnostics)
              .toList(growable: false),
        ),
      ),
    );
  }
}

extension on List<TagSelectable> {
  List<PresentationDefinition>? get sharedTagPresentations {
    final first = firstOrNull?.catalogPresentations;
    if (first == null) return null;
    const equality = ListEquality<PresentationDefinition>();
    return skip(1).every(
          (selection) => equality.equals(first, selection.catalogPresentations),
        )
        ? first
        : null;
  }
}

TypeResult<InspectionContent> _inconsistentTagPresentation() =>
    TypeResult<InspectionContent>.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidPresentation,
        message: "Selected Tags use inconsistent Realm presentations",
        pathPresent: false,
      ),
    ]);
