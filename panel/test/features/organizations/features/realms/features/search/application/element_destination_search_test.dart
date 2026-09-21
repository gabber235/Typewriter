import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("destination scope exposes only compatible pages and kinds", () {
    final books = ValueNotifier<AsyncValue<List<Book>>>(AsyncData([_book]));
    final compatibleKinds = ValueNotifier(
      AsyncValue.data({_compatibleKind: _policy}),
    );
    addTearDown(books.dispose);
    addTearDown(compatibleKinds.dispose);
    final scope = elementDestinationScope(
      books: books,
      compatibleKinds: compatibleKinds,
    );

    expect(
      scope.evaluate(_pageResult(_compatibleKind), SearchQueryContext.empty),
      isA<SearchResultVisible>(),
    );
    expect(
      scope.evaluate(_pageResult(_incompatibleKind), SearchQueryContext.empty),
      isA<SearchResultHidden>(),
    );
    expect(
      scope.evaluate(_kindResult(_compatibleKind), _bookQuery),
      isA<SearchResultVisible>(),
    );
    expect(
      scope.evaluate(_kindResult(_compatibleKind), SearchQueryContext.empty),
      isA<SearchResultHidden>(),
    );
  });

  test("activation returns the selected existing page", () async {
    final books = ValueNotifier<AsyncValue<List<Book>>>(AsyncData([_book]));
    final compatibleKinds = ValueNotifier(
      AsyncValue.data({_compatibleKind: _policy}),
    );
    addTearDown(books.dispose);
    addTearDown(compatibleKinds.dispose);
    final activation = elementDestinationActivation(
      books: books,
      compatibleKinds: compatibleKinds,
    );
    final result = _pageResult(_compatibleKind);

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
    expect(selection.policy, _policy);
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
const _compatibleKind = PageKindRef(id: "compatible", revision: 1);
const _incompatibleKind = PageKindRef(id: "incompatible", revision: 1);
final _elementType = ResolvedTypeRef(
  id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
  revision: 1,
);
final _policy = PageEntryCreationPolicy(
  placement: PageEntryCreationPlacement.graph,
  types: {_elementType},
);
final _bookQuery = SearchQueryContext(
  normalizedQuery: "",
  terms: const [],
  selectors: const [
    SearchParsedSelector(selectorId: "book", key: "book:", value: "Test Book"),
  ],
);

SearchResult _pageResult(PageKindRef kind) => SearchResult(
  id: "page:${kind.id}",
  type: authoringPageSearchResultType,
  payload: _pagePayload(kind),
);

AuthoringSearchResultPayload _pagePayload(PageKindRef kind) {
  final content = TypedValueEnvelope(
    rootType: referenceResourceTypes.page,
    rootValue: RecordValue({
      "kind": RecordValue({
        "id": StringValue(kind.id),
        "revision": IntegerValue(BigInt.from(kind.revision)),
      }),
    }),
  );
  final catalog = TypeCatalog([
    TypeDefinition(
      id: referenceResourceTypes.page,
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
      rootType: referenceResourceTypes.page,
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
    kind: AuthoringSearchResultKind.page,
  );
}

SearchResult _kindResult(PageKindRef kind) => SearchResult(
  id: "kind:${kind.id}",
  type: pageKindSearchResultType,
  payload: RealmPageDefinition(
    kind: kind,
    name: kind.id,
    description: null,
    icon: const IconValue.iconify("mdi:test-tube"),
    color: Colors.blue,
    editor: RealmGraphPageEditor(
      direction: GraphDirection.leftToRight,
      nodeTypes: [_elementType],
    ),
    originArtifactId: "test",
    sourcePart: "test",
    presentationSubject: _catalogSubject(referenceResourceTypes.pageKind),
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
