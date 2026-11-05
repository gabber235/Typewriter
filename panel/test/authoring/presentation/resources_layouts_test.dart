import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final atlas = book("Atlas");
  final zebra = book("Zebra");
  final opening = Page(
    pageId: skir.ResourceId(value: "page:opening"),
    bookId: atlas.bookId,
    name: "Opening",
    chapter: "act1",
  );
  final scene = Page(
    pageId: skir.ResourceId(value: "page:scene"),
    bookId: atlas.bookId,
    name: "Scene",
    chapter: "act1.intro",
  );
  final loose = Page(
    pageId: skir.ResourceId(value: "page:loose"),
    bookId: atlas.bookId,
    name: "Loose",
  );
  final later = Page(
    pageId: skir.ResourceId(value: "page:later"),
    bookId: atlas.bookId,
    name: "Later",
    chapter: "act2",
  );

  testWidgets("the Library shows every Book", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [atlas, zebra], pages: [loose, scene, opening]),
    ]);
    await panel.openSurface(libraryId);

    expect(panel.resources.showing("Atlas"), isTrue);
    expect(panel.resources.showing("Zebra"), isTrue);
  });

  testWidgets("a Book's outline groups its pages by their chapter path", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [atlas, zebra], pages: [loose, scene, opening]),
    ]);
    await panel.openSurface(atlas.bookId);

    // Group headers render the declared group node bound to each group.
    expect(find.text("act1"), findsOneWidget);
    expect(find.text("intro"), findsOneWidget);
    expect(panel.resources.showing("Opening"), isTrue);
    expect(panel.resources.showing("Loose"), isTrue);
    // A nested chapter sits below and inside its parent.
    final intro = tester.getTopLeft(find.text("intro"));
    final sceneRect = panel.resources.row("Scene").rect;
    expect(sceneRect.top, greaterThan(intro.dy));
    expect(
      sceneRect.left,
      greaterThan(panel.resources.row("Opening").rect.left),
    );

    await panel.tapOn(find.tooltip("Collapse act1"));

    expect(find.text("intro"), findsNothing);
    expect(panel.resources.showing("Opening"), isFalse);
    expect(panel.resources.showing("Scene"), isFalse);
    expect(panel.resources.showing("Loose"), isTrue);

    await panel.tapOn(find.tooltip("Expand act1"));
    expect(panel.resources.showing("Scene"), isTrue);
  });

  testWidgets("a page dropped onto a chapter header moves into that chapter", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [atlas, zebra], pages: [loose, scene, opening]),
    ]);
    await panel.openSurface(atlas.bookId);

    await panel.resources.drag("Loose", onto: "intro");

    await panel.eventually(
      () => expect(
        panel.working.textAt(loose.pageId, editorRootPath.field("chapter")),
        "act1.intro",
      ),
    );
  });

  testWidgets("a dragged chapter carries its pages below the target chapter", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [atlas, zebra], pages: [loose, scene, opening, later]),
    ]);
    await panel.openSurface(atlas.bookId);

    await panel.resources.drag("intro", onto: "act2");
    await panel.eventually(
      () => expect(
        panel.working.textAt(scene.pageId, editorRootPath.field("chapter")),
        "act2.intro",
      ),
    );
    expect(
      panel.working.textAt(opening.pageId, editorRootPath.field("chapter")),
      "act1",
    );

    // A chapter never moves into its own subtree.
    await panel.resources.drag("act2", onto: "intro");
    await panel.settle();
    expect(
      panel.working.textAt(scene.pageId, editorRootPath.field("chapter")),
      "act2.intro",
    );
  });

  testWidgets("the outline marks only the routed page as current", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [atlas, zebra], pages: [loose, scene, opening]),
    ]);
    await panel.openSurface(scene.pageId);

    expect(panel.resources.row("Scene").isMarkedSelected, isTrue);
    expect(panel.resources.row("Opening").isMarkedSelected, isFalse);
    expect(panel.resources.row("Loose").isMarkedSelected, isFalse);
  });
}
