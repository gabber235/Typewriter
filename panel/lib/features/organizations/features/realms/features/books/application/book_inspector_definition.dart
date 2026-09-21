part of "books.dart";

const _bookInspectorPresentationId = PresentationId(
  namespace: "typewriter.core",
  name: "book.default",
);

/// Builds one Realm declared editor for multiple selected books.
final class BookMultiInspectionDefinition implements MultiInspectionDefinition {
  const BookMultiInspectionDefinition();

  @override
  PresentationId get id => _bookInspectorPresentationId;

  @override
  bool isCompatibleWith(MultiInspectionDefinition other) =>
      other is BookMultiInspectionDefinition;

  @override
  TypeResult<InspectionContent> build(
    List<EditableSelectable> selection,
    InspectionBuildContext context,
  ) {
    final selected = selection.requireAll<BookSelection>();
    final books = selected.valueOrNull;
    if (books == null) return TypeResult.failure(selected.diagnostics);
    final catalog = books.mergedTypeCatalog;
    final merged = catalog.valueOrNull;
    if (merged == null) return TypeResult.failure(catalog.diagnostics);
    final presentations = books.sharedBookPresentations;
    if (presentations == null) return _inconsistentBookPresentation();
    final collection = mergeAuthoringCollectionSources(
      books.map((book) => book.tagCollection),
    );
    final tags = collection.valueOrNull;
    if (tags == null) return TypeResult.failure(collection.diagnostics);
    final owner = context.multiEditorFor(
      books,
      rootType: books.first.document.rootType,
      typeCatalog: merged,
    );
    return TypeResult.success(
      InspectionContent(
        model: PresentationModel.editor(
          owner: owner,
          presentations: presentations,
          collections: [tags],
          diagnostics: books
              .expand((book) => book.presentationDiagnostics)
              .toList(growable: false),
        ),
      ),
    );
  }
}

extension on List<BookSelection> {
  List<PresentationDefinition>? get sharedBookPresentations {
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

TypeResult<InspectionContent> _inconsistentBookPresentation() =>
    TypeResult<InspectionContent>.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidPresentation,
        message: "Selected Books use inconsistent Realm presentations",
        pathPresent: false,
      ),
    ]);
