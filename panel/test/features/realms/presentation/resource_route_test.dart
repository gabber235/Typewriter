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

  for (final (section, id) in [("Library", libraryId), ("Tags", taxonomyId)]) {
    testWidgets("a screen reader opens $section from the realm sidebar", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        ...library,
        window(const Size(1600, 1000)),
      ]);

      await panel.activateWithScreenReader(section);

      await panel.eventually(
        () => expect(
          panel.path,
          "/organization/acme/realm/main/resource/${id.value}",
        ),
      );
    });
  }

  testWidgets("a surface that opens behind search leaves typing in search", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      ...library,
      window(const Size(1600, 1000)),
    ]);
    await panel.openSurface(route);
    // Search opens before the realm's new navigator pushes Library, which it
    // does a frame later, once its guards ran.
    await panel.activateWithScreenReader("Library", settle: false);
    await panel.activateWithScreenReader("Search", repeated: true);

    expect(panel.routedResource, libraryId.value);
    expect(panel.queryBar.isFocused, isTrue, reason: "search keeps focus");
    await panel.queryBar.type("Route");
    expect(panel.queryBar.text, "Route");
  });

  for (final (kind, resource, field) in [
    ("Page", intro, "name"),
    ("Book", route, "title"),
  ]) {
    testWidgets("a $kind opens on its first field", (tester) async {
      final panel = await tester.pumpPanel([
        ...library,
        window(const Size(1600, 1000)),
      ]);
      await panel.openSurface(resource);
      expect(panel.field(field).isFocused, isTrue);
    });
  }

  for (final (how, create) in [
    ("N", (PanelDriver panel) => panel.press(LogicalKeyboardKey.keyN)),
    (
      "New page",
      (PanelDriver panel) =>
          panel.activateWithKeyboard(find.text("New page").first),
    ),
  ]) {
    testWidgets("$how focuses the new page's name", (tester) async {
      final panel = await tester.pumpPanel([
        ...library,
        window(const Size(1600, 1000)),
      ]);
      await panel.openSurface(route);
      await create(panel);
      await panel.eventually(() {
        expect(panel.working.relations.children[route], hasLength(2));
        // The new page's workspace; its side inspector shows a second
        // name field.
        expect(panel.focused, startsWith("name"));
      });
    });
  }

  testWidgets("typing a new page's name and pressing Enter keeps focus in "
      "the name and opens nothing", (tester) async {
    final panel = await tester.pumpPanel([
      ...library,
      window(const Size(1600, 1000)),
    ]);
    await panel.openSurface(route);
    await panel.press(LogicalKeyboardKey.keyN);
    await panel.eventually(() => expect(panel.focused, startsWith("name")));

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: "Chapter 12",
        selection: TextSelection.collapsed(offset: 10),
      ),
    );
    await panel.settle();
    expect(panel.focused, startsWith("name"));

    await panel.press(LogicalKeyboardKey.enter);
    await panel.settle();

    expect(panel.focused, startsWith("name"));
    expect(panel.working.relations.children[route], hasLength(2));
  });
}
