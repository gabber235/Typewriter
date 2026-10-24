import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  group("owner routes", () {
    test("walk every owner above a type, nearest first", () {
      final catalog = _document().catalog;

      final routes = catalog
          .ownerRoutes(catalog.beginSelection(_element))
          .toList();

      expect(routes.map((route) => route.ownerRoot), [
        fixtureResourceType("page"),
        fixtureResourceType("book"),
        fixtureResourceType("library"),
        fixtureResourceType("realm"),
      ]);
      expect(routes[1].endpoints, [_elementPage, _pageBook(catalog)]);
    });

    test("a type owning its own type is reached once and the walk ends", () {
      final catalog = _document().catalog;

      final routes = catalog
          .ownerRoutes(catalog.beginSelection(_folder))
          .toList();

      expect(routes.map((route) => route.ownerRoot).toSet(), {
        _folder,
        fixtureResourceType("library"),
        fixtureResourceType("realm"),
      });
      expect(routes.where((route) => route.ownerRoot == _folder), hasLength(1));
      expect(
        catalog
            .scopeSelectors(catalog.beginSelection(_folder))
            .map((selector) => selector.key),
        ["folder"],
      );
    });
  });

  group("scope selectors", () {
    test("come from owner search keys, skipping the root and sections", () {
      final catalog = _document().catalog;

      final selectors = catalog
          .scopeSelectors(catalog.beginSelection(_element))
          .toList();

      expect(selectors.map((selector) => selector.key), ["page", "book"]);
      expect(selectors.last.route.endpoints, [
        _elementPage,
        _pageBook(catalog),
      ]);
      expect(
        catalog.scopeSelectors(
          catalog.beginSelection(fixtureResourceType("book")),
        ),
        isEmpty,
      );
    });

    test("the compiled SDK catalog scopes page elements by page and Book", () {
      final catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
      final entry = catalog.creatableTypes.singleWhere(
        (type) =>
            type.typeId ==
            skir.TypeId.createQualified(
              namespace: "fixture",
              name: "MessageEntry",
            ),
      );

      expect(
        catalog
            .scopeSelectors(catalog.beginSelection(entry))
            .map((selector) => selector.key),
        ["page", "book"],
      );
    });

    test("an extension owner type gets its selector from its search key", () {
      final catalog = _document().catalog;

      final selectors = catalog
          .scopeSelectors(catalog.beginSelection(_scene))
          .toList();

      expect(selectors.single.key, "act");
      expect(selectors.single.route.ownerRoot, _act);
      expect(
        catalog.creationSelectors.whereType<KeyValueSelectorDefinition>().map(
          (selector) => selector.key,
        ),
        containsAll(["book:", "page:", "act:", "folder:", "type:"]),
      );
    });
  });

  group("creation context", () {
    test("scope values constrain the new resource to the named owners", () {
      final document = _document();
      final element = document.catalog.beginSelection(_element);

      final outcome = document.creationContext(element, {
        "book": "Main story",
        "page": "intro",
      });

      final context = (outcome as CreationScoped).context;
      expect(context.constraints, [
        CreationReferenceConstraint(
          route: [_elementPage],
          targets: {_mainIntro.pageId},
        ),
        CreationReferenceConstraint(
          route: [_elementPage, _pageBook(document.catalog)],
          targets: {_mainStory.bookId},
        ),
      ]);
      expect(context.allowedTargets(_elementPage), {_mainIntro.pageId});
    });

    test("a value naming several resources leaves a choice among them", () {
      final document = _document();
      final page = document.catalog.beginSelection(fixtureResourceType("page"));

      final resolutions = document.resolveScopes(page, {"book": "Intro"});
      final outcome = document.creationContext(page, {"book": "Intro"});

      expect(resolutions.single, isA<ScopeAmbiguous>());
      expect((resolutions.single as ScopeAmbiguous).candidates, {
        _introOne.bookId,
        _introTwo.bookId,
      });
      expect(
        (outcome as CreationScoped).context.allowedTargets(
          _pageBook(document.catalog),
        ),
        {_introOne.bookId, _introTwo.bookId},
      );
    });

    test("a value naming no resource is reported, not thrown", () {
      final document = _document();
      final element = document.catalog.beginSelection(_element);

      final outcome = document.creationContext(element, {
        "book": "Missing",
        "page": "Intro",
      });

      final unmatched = (outcome as CreationScopeUnmatched).scopes;
      expect(unmatched.single.selector.key, "book");
      expect(unmatched.single.text, "Missing");
    });

    test("a page value narrows to pages inside the named Book", () {
      final document = _document();
      final element = document.catalog.beginSelection(_element);

      expect(
        document.resolveScopes(element, {"page": "Intro"}).single,
        isA<ScopeAmbiguous>(),
      );
      expect(
        document.resolveScopes(element, {
          "book": "Other",
          "page": "Intro",
        }).first,
        ScopeResolution.matched(
          selector: document.catalog
              .scopeSelectors(element)
              .firstWhere((selector) => selector.key == "page"),
          text: "Intro",
          target: _otherIntro.pageId,
        ),
      );
      expect(
        document.resolveScopes(element, {
          "book": "Main story",
          "page": "Missing",
        }).first,
        isA<ScopeUnmatched>(),
      );
    });
  });

  test("the query's selector values feed the creation context", () {
    final query = SearchQueryContext(
      normalizedQuery: "",
      selectors: const [
        SearchParsedSelector(selectorId: "book", key: "book:", value: "Main"),
        SearchParsedSelector(selectorId: "page", key: "page:", value: "A"),
        SearchParsedSelector(selectorId: "page", key: "page:", value: "B"),
      ],
    );

    expect(query.selectorValues, {"book": "Main"});
  });
}

final _element = _typeId("Element");
final _folder = _typeId("Folder");
final _act = _typeId("Act");
final _scene = _typeId("Scene");
final _elementPage = skir.EndpointId(value: "test.page.elements:second");

skir.TypeDefinitionId _typeId(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: name),
  revision: 1,
);

skir.EndpointId _pageBook(CheckedEditorCatalog catalog) => catalog
    .ownershipRelations
    .singleWhere(
      (ownership) =>
          ownership.member.resource.definition == fixtureResourceType("page"),
    )
    .member
    .id;

final _mainStory = Book(
  bookId: skir.ResourceId(value: "book:main"),
  title: "Main story",
  icon: "mdi:book",
  color: Colors.blue,
);
final _otherBook = Book(
  bookId: skir.ResourceId(value: "book:other"),
  title: "Other",
  icon: "mdi:book",
  color: Colors.green,
);
final _introOne = Book(
  bookId: skir.ResourceId(value: "book:intro:1"),
  title: "Intro",
  icon: "mdi:book",
  color: Colors.red,
);
final _introTwo = Book(
  bookId: skir.ResourceId(value: "book:intro:2"),
  title: "Intro",
  icon: "mdi:book",
  color: Colors.red,
);
final _mainIntro = Page(
  pageId: skir.ResourceId(value: "page:main:intro"),
  bookId: _mainStory.bookId,
  name: "Intro",
);
final _otherIntro = Page(
  pageId: skir.ResourceId(value: "page:other:intro"),
  bookId: _otherBook.bookId,
  name: "Intro",
);

/// The fixture library extended with types an extension could add: elements
/// owned by pages, Folders holding Folders, and Acts holding Scenes.
AuthoringDocument _document() {
  final document = fixtureAuthoringDocument(
    realm: true,
    books: [_mainStory, _otherBook, _introOne, _introTwo],
    pages: [_mainIntro, _otherIntro],
  );
  final library = fixtureResourceType("library");
  final snapshot = document.catalog.snapshot.toMutable()
    ..types = [
      ...document.catalog.snapshot.types,
      _published(_element, "element"),
      _published(_folder, "folder"),
      _published(_act, "act"),
      _published(_scene, "scene"),
    ]
    ..relations = [
      ...document.catalog.snapshot.relations,
      _ownership("test.page.elements", fixtureResourceType("page"), _element),
      _ownership("test.library.folders", library, _folder),
      _ownership("test.folder.folders", _folder, _folder),
      _ownership("test.library.acts", library, _act),
      _ownership("test.act.scenes", _act, _scene),
    ];
  return document.copyWith(catalog: CheckedEditorCatalog(snapshot.toFrozen()));
}

skir.PublishedType _published(skir.TypeDefinitionId id, String searchKey) =>
    skir.PublishedType(
      definition: skir.TypeDefinition(
        id: id,
        parameters: const [],
        representation: skir.RepresentationTemplate.createRecord(
          abstract_: false,
          fields: const [],
        ),
        parents: const [],
      ),
      status: skir.DeclarationStatus.ready,
      effectiveFields: const [],
      ancestorTemplates: const [],
      display: defaultTypeDisplay(searchKey),
      searchKey: searchKey,
      placementField: null,
    );

skir.RelationContract _ownership(
  String id,
  skir.TypeDefinitionId owner,
  skir.TypeDefinitionId member,
) => skir.RelationContract(
  id: skir.RelationId(value: id),
  first: skir.EndpointDefinition(
    id: skir.EndpointId(value: "$id:first"),
    slot: skir.EndpointSlot.first,
    resource: skir.NamedTypeTemplate(definition: owner, arguments: const []),
    cardinality: skir.EndpointCardinality.one,
    onDelete: skir.RelationDeletePolicy.cascade,
  ),
  second: skir.EndpointDefinition(
    id: skir.EndpointId(value: "$id:second"),
    slot: skir.EndpointSlot.second,
    resource: skir.NamedTypeTemplate(definition: member, arguments: const []),
    cardinality: skir.EndpointCardinality.many,
    onDelete: skir.RelationDeletePolicy.clear,
  ),
  families: [skir.resourceOwnershipFamily],
);
