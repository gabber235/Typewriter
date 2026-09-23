import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("destination scope exposes only compatible pages and types", () {
    final books = ValueNotifier<AsyncValue<List<Book>>>(AsyncData([_book]));
    final compatibleFields = ValueNotifier(
      AsyncValue.data({_compatibleType: _field}),
    );
    addTearDown(books.dispose);
    addTearDown(compatibleFields.dispose);
    final scope = elementDestinationScope(
      books: books,
      compatibleFields: compatibleFields,
    );

    expect(
      scope.evaluate(_pageResult(_compatibleType), SearchQueryContext.empty),
      isA<SearchResultVisible>(),
    );
    expect(
      scope.evaluate(_pageResult(_incompatibleType), SearchQueryContext.empty),
      isA<SearchResultHidden>(),
    );
    expect(
      scope.evaluate(_kindResult(_compatibleType), _bookQuery),
      isA<SearchResultVisible>(),
    );
    expect(
      scope.evaluate(_kindResult(_compatibleType), SearchQueryContext.empty),
      isA<SearchResultHidden>(),
    );
  });

  test("activation returns the selected existing page", () async {
    final books = ValueNotifier<AsyncValue<List<Book>>>(AsyncData([_book]));
    final compatibleFields = ValueNotifier(
      AsyncValue.data({_compatibleType: _field}),
    );
    addTearDown(books.dispose);
    addTearDown(compatibleFields.dispose);
    final activation = elementDestinationActivation(
      books: books,
      compatibleFields: compatibleFields,
    );
    final result = _pageResult(_compatibleType);

    final outcome = await activation.activate(
      SearchActivationContext(
        prompts: const UnsupportedSearchPromptHost(),
        commands: const _NoCommands(),
        query: SearchQueryContext.empty,
      ),
      result,
    );

    expect(outcome, isA<SearchActivationComplete<ElementPageSelection>>());
    final selection =
        (outcome as SearchActivationComplete<ElementPageSelection>).value;
    expect(selection.pageId, _pageId);
    expect(selection.bookId, _book.bookId);
    expect(selection.field, _field);
  });
}

final _book = Book(
  bookId: skir.ResourceId(value: "test"),
  title: "Test Book",
  icon: "mdi:book",
  color: Colors.blue,
  tagIds: const [],
);
final _pageId = skir.ResourceId(value: "compatible");
final _compatibleType = ResolvedTypeRef(id: const QualifiedTypeId(namespace: "test", name: "CompatiblePage"), revision: 1);
final _incompatibleType = ResolvedTypeRef(id: const QualifiedTypeId(namespace: "test", name: "IncompatiblePage"), revision: 1);
final _elementType = ResolvedTypeRef(
  id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
  revision: 1,
);
final _field = RealmRelationField(
  relation: RealmRelationDefinition(
    id: "page.elements",
    source: _compatibleType,
    target: _elementType,
    onSourceDelete: RealmRelationDeletePolicy.cascade,
    onTargetDelete: RealmRelationDeletePolicy.clear,
    sourceEndpoint: RealmRelationEndpointDefinition(
      owner: _compatibleType,
      path: DataPath.root.field("elements"),
      side: RealmRelationEndpointSide.source,
      cardinality: RealmRelationCardinality.many,
    ),
    targetEndpoint: null,
    families: const {"resource.ownership"},
  ),
  endpoint: RealmRelationEndpointDefinition(
    owner: _compatibleType,
    path: DataPath.root.field("elements"),
    side: RealmRelationEndpointSide.source,
    cardinality: RealmRelationCardinality.many,
  ),
  target: _elementType,
);
final _bookQuery = SearchQueryContext(
  normalizedQuery: "",
  terms: const [],
  selectors: const [
    SearchParsedSelector(selectorId: "book", key: "book:", value: "Test Book"),
  ],
);

SearchResult _pageResult(ResolvedTypeRef kind) => SearchResult(
  id: "page:${kind.id}",
  type: authoringResourceSearchResultType,
  payload: _pagePayload(kind),
);

AuthoringSearchResultPayload _pagePayload(ResolvedTypeRef kind) {
  final content = TypedValueEnvelope(
    rootType: kind,
    rootValue: RecordValue({}),
  );
  final catalog = TypeCatalog([
    TypeDefinition(
      id: kind,
      kind: NominalTypeKind.concrete,
      representation: const RecordType(fields: {}),
    ),
  ]);
  return AuthoringSearchResultPayload(
    subject: (
      content: content,
      descriptor: content,
      identityEnvelope: content,
      identity: (id: _pageId, owner: _book.bookId),
    ),
    context: TypedValueEnvelope(
      rootType: kind,
      rootValue: RecordValue({"book": ReferenceValue(_book.bookId)}),
    ),
    presentation: (
      model: PresentationModel(
        catalog: catalog,
        inputs: const {},
        root: PresentationNode(
          id: "test.page.result",
          element: TextElement("Compatible".asStringLiteral),
        ),
      ),
      presentation: const PresentationId(namespace: "test", name: "page"),
    ),
    definition: CoreResourceDefinitionIds.page,
    ownerPath: [_book.bookId],
  );
}

SearchResult _kindResult(ResolvedTypeRef kind) => SearchResult(
  id: "kind:${kind.id}",
  type: pageTypeSearchResultType,
  payload: RealmPageDefinition(
    type: kind,
    name: kind.id.toString(),
    description: null,
    icon: const IconValue.iconify("mdi:test-tube"),
    color: Colors.blue,
    editor: const RealmGraphPageEditor(direction: GraphDirection.leftToRight),
    originArtifactId: "test",
    sourcePart: "test",
    presentationSubject: _catalogSubject(referenceResourceTypes.page),
  ),
);

TypedCatalogPresentationSubject _catalogSubject(ResolvedTypeRef type) => (
  target: type,
  descriptor: TypedValueEnvelope(rootType: type, rootValue: RecordValue({})),
  identity: TypedValueEnvelope(rootType: type, rootValue: RecordValue({})),
);

final class _NoCommands implements SearchCommandDispatcher {
  const _NoCommands();

  @override
  SearchCommandSubmitResult executeCommand(
    SearchCommandId id, {
    String? resultId,
  }) => SearchCommandSubmitResult.commandNotFound;

  @override
  ResolvedSearchCommand? resolveCommand(
    SearchCommandId id,
    SearchResult result,
  ) => null;
}
