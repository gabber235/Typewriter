import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  group("SurfaceNavigator.open", () {
    test("a keyframe deep in a page lands on the page with it selected", () {
      final document = _deepDocument;

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
      final document = _deepDocument;

      expect(document.open(_page), SurfaceTarget.resource(routed: _page));
      expect(document.open(_book), SurfaceTarget.resource(routed: _book));
      expect(
        document.open(libraryId),
        SurfaceTarget.resource(routed: libraryId),
      );
    });

    test("the root maps to the realm home", () {
      final document = _deepDocument;

      expect(document.open(realmRootId), SurfaceTarget.home());
    });

    test("a resource without any surface owner opens the realm home", () {
      final document = _deepDocument.copyWith(links: const []);

      expect(document.open(_keyframe), SurfaceTarget.home(selected: _keyframe));
    });
  });

  test(
    "declared workspaces and navigators are surfaces, fallbacks are not",
    () {
      final document = _deepDocument;

      expect(document.hasSurface(_page), isTrue);
      expect(document.hasSurface(_book), isTrue);
      expect(document.hasSurface(realmRootId), isTrue);
      expect(document.hasSurface(_element), isFalse);
      expect(document.hasSurface(skir.ResourceId(value: "absent")), isFalse);
    },
  );

  group("the routed surface", () {
    final story = book("Story");
    final intro = page("Intro", book: story);
    const realmPath = "/organization/acme/realm/main";
    testWidgets("a link straight to a resource opens its surface", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [story], pages: [intro]),
        operations(const [RealmOperation.delete()]),
      ]);
      await panel.openSurface(intro.pageId);

      expect(panel.path, "$realmPath/resource/${intro.pageId.value}");
      expect(panel.resources.showing("Intro"), isTrue);
    });

    final deletions = {
      "the routed page returns to its Book": (intro.pageId, story.bookId),
      "the routed page's Book returns to the Library": (
        story.bookId,
        libraryId,
      ),
    };
    for (final MapEntry(key: outcome, value: (deleted, survivor))
        in deletions.entries) {
      testWidgets("deleting $outcome", (tester) async {
        final panel = await tester.pumpPanel([
          signedIn(ada, organization: acme),
          realm(books: [story], pages: [intro]),
          operations(const [RealmOperation.delete()]),
        ]);
        await panel.openSurface(intro.pageId);
        expect(panel.path, "$realmPath/resource/${intro.pageId.value}");

        // Delete with the Delete key, with focus on the page in the Book's
        // outline.
        await panel.resources.row("Intro").select();
        await panel.resources.selectOnly([deleted]);
        await panel.holdKey(LogicalKeyboardKey.delete);

        await panel.eventually(
          () => expect(panel.path, "$realmPath/resource/${survivor.value}"),
        );
      });
    }

    testWidgets("deleting every owner of the routed page returns to the "
        "realm home", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [story], pages: [intro]),
        operations(const [RealmOperation.delete()]),
      ]);
      await panel.openSurface(intro.pageId);

      // Delete with the Delete key, with focus on the page in the Book's
      // outline.
      await panel.resources.row("Intro").select();
      await panel.resources.selectOnly([libraryId]);
      await panel.holdKey(LogicalKeyboardKey.delete);

      await panel.eventually(() => expect(panel.path, realmPath));
    });

    // The Book's outline offers no menu on its pages yet, so the case asks
    // for the navigation the way a presentation's edit action does.
    testWidgets("editing another resource from a surface without a side "
        "inspector opens its own surface and inspects it there", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [story], pages: [intro]),
      ]);
      await panel.resources.row("Story").open();
      expect(panel.path, "$realmPath/resource/${story.bookId.value}");

      await panel.container
          .read(realmSurfaceNavigationProvider)
          .navigate(
            panel.world.requireRealm.scope,
            intro.pageId,
            skir.ResourceNavigationMode.edit,
            isCurrent: () => true,
          );
      await panel.settle();

      expect(panel.path, "$realmPath/resource/${intro.pageId.value}");
      expect(panel.resources.selected, [intro.pageId]);
      // Revealed in the inspector: keyboard focus on the page's first field,
      // as Inspect gives it on a surface with a side inspector.
      await panel.eventually(() => expect(panel.focused, "name"));
    });
  });

  test("the root, home section, trail and rail come from ownership", () {
    final document = _deepDocument;

    expect(document.realmRoot, realmRootId);
    expect(document.homeSection, libraryId);
    expect(document.surfaceTrail(_page), [libraryId, _book, _page]);
    expect(document.railNavigator(_page), _book);
    expect(document.railNavigator(_book), _book);
    expect(document.railNavigator(libraryId), isNull);
  });
}

final _book = skir.ResourceId(value: "book:deep");
final _page = skir.ResourceId(value: "page:deep");
final _element = skir.ResourceId(value: "element:deep");
final _keyframe = skir.ResourceId(value: "keyframe:deep");

/// A realm where a page owns an element that owns a keyframe. Elements and
/// keyframes reuse the tag record, a type without a surface of its own.

final _seeded = realmDocument(
  books: [
    Book(bookId: _book, title: "Book", icon: "mdi:book", color: Colors.blue),
  ],
  pages: [Page(pageId: _page, bookId: _book, name: "Page")],
  tags: [
    Tag(tagId: _element, name: "Element", color: Colors.green),
    Tag(tagId: _keyframe, name: "Keyframe", color: Colors.green),
  ],
);
final _elements = testOwnershipRelation(
  "test.page.elements",
  owner: libraryType("page"),
  member: libraryType("tag"),
);
final _keyframes = testOwnershipRelation(
  "test.element.keyframes",
  owner: libraryType("tag"),
  member: libraryType("tag"),
);

/// A realm where a page owns an element that owns a keyframe. Elements and
/// keyframes reuse the tag record, a type without a surface of its own.
final _deepDocument = _seeded
    .withCatalogEntries(relations: [_elements, _keyframes])
    .copyWith(
      // The deep resources are owned by the page chain, not the tags section.
      links: [
        for (final link in _seeded.links)
          if (link.second != _element && link.second != _keyframe) link,
        skir.LinkProjection(
          contract: _elements.id,
          first: _page,
          second: _element,
          firstLocation: editorRootPath.field("elements"),
          secondLocation: null,
        ),
        skir.LinkProjection(
          contract: _keyframes.id,
          first: _element,
          second: _keyframe,
          firstLocation: editorRootPath.field("keyframes"),
          secondLocation: null,
        ),
      ],
    );
