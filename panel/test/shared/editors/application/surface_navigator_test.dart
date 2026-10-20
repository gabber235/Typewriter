import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  group("SurfaceNavigator.open", () {
    test("a keyframe deep in a page lands on the page with it selected", () {
      final document = _deepDocument();

      expect(
        document.open(_keyframe),
        SurfaceTarget.resource(routed: _page, selected: _keyframe),
      );
      expect(
        document.open(_element),
        SurfaceTarget.resource(routed: _page, selected: _element),
      );
    });

    test("a resource with its own surface opens itself", () {
      final document = _deepDocument();

      expect(document.open(_page), SurfaceTarget.resource(routed: _page));
      expect(document.open(_book), SurfaceTarget.resource(routed: _book));
      expect(
        document.open(fixtureLibraryId),
        SurfaceTarget.resource(routed: fixtureLibraryId),
      );
    });

    test("the root maps to the realm home", () {
      final document = _deepDocument();

      expect(document.open(fixtureRealmRootId), SurfaceTarget.home());
    });

    test("a resource without any surface owner opens the realm home", () {
      final document = _deepDocument().copyWith(links: const []);

      expect(document.open(_keyframe), SurfaceTarget.home(selected: _keyframe));
    });
  });

  test(
    "declared workspaces and navigators are surfaces, fallbacks are not",
    () {
      final document = _deepDocument();

      expect(document.hasSurface(_page), isTrue);
      expect(document.hasSurface(_book), isTrue);
      expect(document.hasSurface(fixtureRealmRootId), isTrue);
      expect(document.hasSurface(_element), isFalse);
      expect(document.hasSurface(skir.ResourceId(value: "absent")), isFalse);
    },
  );

  test("the root, home section, trail and rail come from ownership", () {
    final document = _deepDocument();

    expect(document.realmRoot, fixtureRealmRootId);
    expect(document.homeSection, fixtureLibraryId);
    expect(document.surfaceTrail(_page), [fixtureLibraryId, _book, _page]);
    expect(document.railNavigator(_page), _book);
    expect(document.railNavigator(_book), _book);
    expect(document.railNavigator(fixtureLibraryId), isNull);
  });
}

final _book = skir.ResourceId(value: "book:deep");
final _page = skir.ResourceId(value: "page:deep");
final _element = skir.ResourceId(value: "element:deep");
final _keyframe = skir.ResourceId(value: "keyframe:deep");

/// A realm where a page owns an element that owns a keyframe. Elements and
/// keyframes reuse the tag record, a type without a surface of its own.
AuthoringDocument _deepDocument() {
  final document = fixtureAuthoringDocument(
    realm: true,
    books: [
      Book(bookId: _book, title: "Book", icon: "mdi:book", color: Colors.blue),
    ],
    pages: [Page(pageId: _page, bookId: _book, name: "Page")],
    tags: [
      Tag(tagId: _element, name: "Element", color: Colors.green),
      Tag(tagId: _keyframe, name: "Keyframe", color: Colors.green),
    ],
  );
  final page = fixtureResourceType("page");
  final tag = fixtureResourceType("tag");
  skir.RelationContract ownership(
    String id,
    skir.TypeDefinitionId owner,
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
      resource: skir.NamedTypeTemplate(definition: tag, arguments: const []),
      cardinality: skir.EndpointCardinality.many,
      onDelete: skir.RelationDeletePolicy.clear,
    ),
    families: [skir.RelationFamilyId(value: "resource.ownership")],
  );
  final elements = ownership("test.page.elements", page);
  final keyframes = ownership("test.element.keyframes", tag);
  final catalog = document.catalog.snapshot.toMutable()
    ..relations = [...document.catalog.snapshot.relations, elements, keyframes];
  return document.copyWith(
    catalog: CheckedEditorCatalog(catalog.toFrozen()),
    // The deep resources are owned by the page chain, not the tags section.
    links: [
      for (final link in document.links)
        if (link.second != _element && link.second != _keyframe) link,
      skir.LinkProjection(
        contract: elements.id,
        first: _page,
        second: _element,
        firstLocation: editorRootPath.field("elements"),
        secondLocation: null,
      ),
      skir.LinkProjection(
        contract: keyframes.id,
        first: _element,
        second: _keyframe,
        firstLocation: editorRootPath.field("keyframes"),
        secondLocation: null,
      ),
    ],
  );
}
