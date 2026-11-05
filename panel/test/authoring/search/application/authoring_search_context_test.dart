import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("owner routes", () {
    test("walk every owner above a type, nearest first", () {
      final catalog = _document.catalog;

      final routes = catalog
          .ownerRoutes(catalog.beginSelection(_element))
          .toList();

      expect(routes.map((route) => route.ownerRoot), [
        libraryType("page"),
        libraryType("book"),
        libraryType("library"),
        libraryType("realm"),
      ]);
      expect(routes[1].endpoints, [_elementPage, _pageBook]);
    });

    test("a type owning its own type is reached once and the walk ends", () {
      final catalog = _document.catalog;

      final routes = catalog
          .ownerRoutes(catalog.beginSelection(_folder))
          .toList();

      expect(routes.map((route) => route.ownerRoot).toSet(), {
        _folder,
        libraryType("library"),
        libraryType("realm"),
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
      final catalog = _document.catalog;

      final selectors = catalog
          .scopeSelectors(catalog.beginSelection(_element))
          .toList();

      expect(selectors.map((selector) => selector.key), ["page", "book"]);
      expect(selectors.last.route.endpoints, [_elementPage, _pageBook]);
      expect(
        catalog.scopeSelectors(catalog.beginSelection(libraryType("book"))),
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
      final catalog = _document.catalog;

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
      final document = _document;
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
          route: [_elementPage, _pageBook],
          targets: {_mainStory.bookId},
        ),
      ]);
      expect(context.allowedTargets(_elementPage), {_mainIntro.pageId});
    });

    test("a value naming several resources leaves a choice among them", () {
      final document = _document;
      final page = document.catalog.beginSelection(libraryType("page"));

      final resolutions = document.resolveScopes(page, {"book": "Intro"});
      final outcome = document.creationContext(page, {"book": "Intro"});

      expect(resolutions.single, isA<ScopeAmbiguous>());
      expect((resolutions.single as ScopeAmbiguous).candidates, {
        _introOne.bookId,
        _introTwo.bookId,
      });
      expect((outcome as CreationScoped).context.allowedTargets(_pageBook), {
        _introOne.bookId,
        _introTwo.bookId,
      });
    });

    test("a value naming no resource is reported, not thrown", () {
      final document = _document;
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
      final document = _document;
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

  test("a selector given twice is ambiguous and leaves the creation context "
      "unscoped by it", () {
    final query = SearchQueryContext(
      normalizedQuery: "",
      selectors: const [
        SearchParsedSelector(selectorId: "book", key: "book:", value: "Main"),
        SearchParsedSelector(selectorId: "page", key: "page:", value: "A"),
        SearchParsedSelector(selectorId: "page", key: "page:", value: "B"),
      ],
    );

    expect(query.selectorValues, {"book": "Main"});
    expect(query.selectorValues.containsKey("page"), isFalse);
  });
}

final _element = testTypeId("Element");
final _folder = testTypeId("Folder");
final _act = testTypeId("Act");
final _scene = testTypeId("Scene");
final _elementPage = skir.EndpointId(value: "test.page.elements:second");

/// The endpoint through which a Page reaches the Book that owns it.
final _pageBook = _document.catalog.ownershipRelations
    .singleWhere(
      (ownership) =>
          ownership.member.resource.definition == libraryType("page"),
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
final _document =
    realmDocument(
      books: [_mainStory, _otherBook, _introOne, _introTwo],
      pages: [_mainIntro, _otherIntro],
    ).withCatalogEntries(
      types: [
        declaredRecord(
          _element,
          searchKey: "element",
          display: defaultTypeDisplay("element"),
        ),
        declaredRecord(
          _folder,
          searchKey: "folder",
          display: defaultTypeDisplay("folder"),
        ),
        declaredRecord(
          _act,
          searchKey: "act",
          display: defaultTypeDisplay("act"),
        ),
        declaredRecord(
          _scene,
          searchKey: "scene",
          display: defaultTypeDisplay("scene"),
        ),
      ],
      relations: [
        testOwnershipRelation(
          "test.page.elements",
          owner: libraryType("page"),
          member: _element,
        ),
        testOwnershipRelation(
          "test.library.folders",
          owner: libraryType("library"),
          member: _folder,
        ),
        testOwnershipRelation(
          "test.folder.folders",
          owner: _folder,
          member: _folder,
        ),
        testOwnershipRelation(
          "test.library.acts",
          owner: libraryType("library"),
          member: _act,
        ),
        testOwnershipRelation("test.act.scenes", owner: _act, member: _scene),
      ],
    );
