import "package:flutter/material.dart" hide Page;
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("element type source participates in destination selectors", () {
    final definitions = ValueNotifier<AsyncValue<List<ElementDefinition>>>(
      const AsyncData([]),
    );
    final source = ElementTypeSearchSource(definitions: definitions);
    addTearDown(definitions.dispose);
    addTearDown(source.dispose);

    expect(source.selectors.map((selector) => selector.id), [
      "book",
      "page",
      "type",
    ]);
  });

  test("explicit book and page selectors override the current page", () {
    expect(
      resolveElementCreationPage(
        query: _query(book: _otherBook.title, page: _otherPage.name),
        books: [_currentBook, _otherBook],
        pages: [_currentPage, _otherPage],
        currentPage: _currentPage,
      ),
      _otherPage,
    );
    expect(
      resolveElementCreationPage(
        query: _query(book: _otherBook.title),
        books: [_currentBook, _otherBook],
        pages: [_currentPage, _otherPage],
        currentPage: _currentPage,
      ),
      isNull,
    );
  });

  test("page selector exposes only element types accepted by that page", () {
    final dependencies = _scopeDependencies();
    addTearDown(dependencies.dispose);
    final scope = dependencies.scope;
    final query = _query(book: _otherBook.title, page: _otherPage.name);

    expect(
      scope.evaluate(_elementResult(_childDefinition), query),
      isA<SearchResultVisible>(),
    );
    expect(
      scope.evaluate(_elementResult(_unrelatedDefinition), query),
      isA<SearchResultHidden>(),
    );
  });

  test("type selector includes concrete descendants", () {
    final dependencies = _scopeDependencies();
    addTearDown(dependencies.dispose);
    final scope = dependencies.scope;

    expect(
      scope.evaluate(
        _elementResult(_childDefinition),
        _query(type: _parentDefinition.name),
      ),
      isA<SearchResultVisible>(),
    );
    expect(
      scope.evaluate(
        _elementResult(_unrelatedDefinition),
        _query(type: _parentDefinition.name),
      ),
      isA<SearchResultHidden>(),
    );
  });
}

({SearchScope scope, void Function() dispose}) _scopeDependencies() {
  final books = ValueNotifier<AsyncValue<List<Book>>>(
    AsyncData([_currentBook, _otherBook]),
  );
  final pages = ValueNotifier<AsyncValue<List<Page>>>(
    AsyncData([_currentPage, _otherPage]),
  );
  final policies = ValueNotifier(AsyncValue.data({_pageKind: _pagePolicy}));
  final catalog = ValueNotifier<AsyncValue<RealmEditorCatalogState>>(
    AsyncData(
      RealmEditorCatalogState.ready(
        RealmEditorCatalogSnapshot(
          catalog: TypeCatalog([
            TypeDefinition(
              id: _parentType,
              kind: NominalTypeKind.concrete,
              representation: const RecordType(fields: {}),
            ),
            TypeDefinition(
              id: _childType,
              kind: NominalTypeKind.concrete,
              representation: const RecordType(fields: {}),
              parents: [_parentType],
            ),
            TypeDefinition(
              id: _unrelatedType,
              kind: NominalTypeKind.concrete,
              representation: const RecordType(fields: {}),
            ),
          ]),
          generation: const CatalogGeneration("test"),
          elements: {
            _parentDefinition.typeId.uuid: _catalogEntry(_parentDefinition),
            _childDefinition.typeId.uuid: _catalogEntry(_childDefinition),
            _unrelatedDefinition.typeId.uuid: _catalogEntry(
              _unrelatedDefinition,
            ),
          },
        ),
      ),
    ),
  );
  return (
    scope: primarySearchScope(
      books: books,
      pages: pages,
      pagePolicies: policies,
      catalog: catalog,
    ),
    dispose: () {
      books.dispose();
      pages.dispose();
      policies.dispose();
      catalog.dispose();
    },
  );
}

RealmElementCatalogEntry _catalogEntry(ElementDefinition definition) =>
    RealmElementCatalogEntry(
      originArtifactId: "test",
      sourcePart: "test",
      definition: DiscoveredElementDefinition(
        id: definition.typeId.uuid,
        type: definition.rootType,
        name: definition.name,
        description: definition.description,
        icon: definition.icon,
        color: definition.color,
        availability: const ElementAvailability.always(),
      ),
      eligible: true,
      available: true,
    );

SearchQueryContext _query({String? book, String? page, String? type}) =>
    SearchQueryContext(
      normalizedQuery: "",
      selectors: [
        if (book != null)
          SearchParsedSelector(selectorId: "book", key: "book:", value: book),
        if (page != null)
          SearchParsedSelector(selectorId: "page", key: "page:", value: page),
        if (type != null)
          SearchParsedSelector(selectorId: "type", key: "type:", value: type),
      ],
    );

SearchResult _elementResult(ElementDefinition definition) => SearchResult(
  id: definition.typeId.uuid,
  type: elementTypeSearchResultType,
  payload: definition,
  title: definition.name,
);

final _currentBook = Book(
  bookId: recordId("book:current"),
  title: "Current",
  icon: "mdi:book",
  color: Colors.blue,
  tagIds: const [],
);
final _otherBook = Book(
  bookId: recordId("book:other"),
  title: "Other",
  icon: "mdi:book",
  color: Colors.green,
  tagIds: const [],
);
const _pageKind = PageKindRef(id: "static", revision: 1);
final _currentPage = Page(
  pageId: recordId("page:current"),
  bookId: _currentBook.bookId,
  name: "Intro",
  kind: _pageKind,
  chapter: "",
  priority: 0,
);
final _otherPage = Page(
  pageId: recordId("page:other"),
  bookId: _otherBook.bookId,
  name: "Intro",
  kind: _pageKind,
  chapter: "",
  priority: 0,
);
final _parentType = ResolvedTypeRef(
  id: DeclaredTypeId("10000000000000000000000000000001"),
  revision: 1,
);
final _childType = ResolvedTypeRef(
  id: DeclaredTypeId("10000000000000000000000000000002"),
  revision: 1,
);
final _unrelatedType = ResolvedTypeRef(
  id: DeclaredTypeId("10000000000000000000000000000003"),
  revision: 1,
);
final _parentDefinition = _definition(_parentType, "Parent");
final _childDefinition = _definition(_childType, "Child");
final _unrelatedDefinition = _definition(_unrelatedType, "Unrelated");
final _pagePolicy = PageEntryCreationPolicy(
  placement: PageEntryCreationPlacement.graph,
  types: {_childType},
);

ElementDefinition _definition(ResolvedTypeRef type, String name) =>
    ElementDefinition(
      rootType: type,
      name: name,
      description: "$name element",
      icon: const IconValue.iconify("mdi:test-tube"),
    );
