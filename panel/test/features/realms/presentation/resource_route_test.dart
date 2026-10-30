import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final route = skir.ResourceId(value: "book:route");
  final intro = skir.ResourceId(value: "page:route");

  /// The Book "Route" holding the page "Intro".
  final library = [
    signedIn(ada, organization: acme),
    realm(
      books: [
        Book(
          bookId: route,
          title: "Route",
          icon: "mdi:book",
          color: Colors.blue,
        ),
      ],
      pages: [Page(pageId: intro, bookId: route, name: "Intro")],
    ),
  ];

  testWidgets("a page shows its workspace beside its Book's outline", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      ...library,
      window(const Size(1600, 1000)),
    ]);
    await panel.openSurface(intro);

    expect(semanticsButtons("Route").isNotEmpty, isTrue);
    expect(semanticsButtons("Intro").isNotEmpty, isTrue);
    expect(panel.field("name").value, "Intro");
    expect(
      panel.item("Route").rect.right,
      lessThanOrEqualTo(panel.field("name").rect.left),
      reason: "the outline sits beside the page's workspace",
    );
  });

  testWidgets(
    "a Book without a workspace shows its inspector in the main area",
    (tester) async {
      final panel = await tester.pumpPanel([
        ...library,
        window(const Size(1600, 1000)),
      ]);
      await panel.openSurface(route);

      expect(semanticsButtons("Route").isNotEmpty, isTrue);
      expect(panel.field("title").value, "Route");
      expect(panel.shows("New page"), isTrue);
      expect(panel.inspector.isOpen, isFalse);
    },
  );

  testWidgets("a narrow surface opens its outline from a menu in the heading", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      ...library,
      window(const Size(420, 900)),
    ]);
    await panel.openSurface(intro);
    expect(semanticsButtons("Route").isNotEmpty, isFalse);

    await panel.tapOn(find.tooltip("Open Route"));

    expect(semanticsButtons("Route").isNotEmpty, isTrue);
    expect(semanticsButtons("Intro").isNotEmpty, isTrue);
  });

  testWidgets("the creation shortcut works with focus in the surface body", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      ...library,
      window(const Size(1600, 1000)),
    ]);
    await panel.openSurface(route);
    await panel.tapOn(find.text("Route").last);

    await panel.press(LogicalKeyboardKey.keyN);

    expect(panel.working.relations.children[route], hasLength(2));
  });

  testWidgets("a section has no outline and offers to create its members", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      ...library,
      window(const Size(1600, 1000)),
    ]);
    await panel.openSurface(libraryId);

    expect(panel.shows("New book"), isTrue);
    expect(semanticsButtons("Intro").isNotEmpty, isFalse);
  });
}
