import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final route = book("Route");
  final intro = page("Intro", book: route);

  /// Ada edits the Book "Route" holding the page "Intro" on a wide screen.
  final library = [
    signedIn(ada, organization: acme),
    realm(books: [route], pages: [intro]),
    window(const Size(1600, 1000)),
  ];

  testWidgets("a Book offers to create its next page as its main action", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(library);
    await panel.openSurface(route.bookId);

    await panel.tapOn(find.text("New page"));

    expect(panel.working.relations.children[route.bookId], hasLength(2));
  });

  testWidgets("a resource that no longer exists says so on its whole page", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(library);

    await panel.openSurface(skir.ResourceId(value: "book:removed"));

    expect(panel.shows("This resource is no longer available"), isTrue);
  });

  testWidgets("the heading counts the issues found on its resource", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(library);
    await panel.openSurface(route.bookId);

    panel.world.requireRealm.publication.emit(
      publicationBlockedBy([
        "A title is required",
        "The cover is missing",
      ], resource: route.bookId.value),
    );
    await panel.settle();

    expect(find.tooltip("2 issues"), findsOneWidget);
  });
}
