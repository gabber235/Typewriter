import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final atlas = skir.ResourceId(value: "book:atlas");
  final zebra = skir.ResourceId(value: "book:zebra");
  final intro = skir.ResourceId(value: "page:intro");
  final outro = skir.ResourceId(value: "page:outro");
  final books = [
    Book(bookId: zebra, title: "Zebra", icon: "mdi:book", color: Colors.blue),
    Book(bookId: atlas, title: "Atlas", icon: "mdi:book", color: Colors.blue),
  ];
  final pages = [
    Page(pageId: outro, bookId: atlas, name: "Outro"),
    Page(pageId: intro, bookId: atlas, name: "Intro"),
  ];

  test("breadcrumbs follow the owner chain below the root, each with its "
      "siblings", () {
    final crumbs = realmDocument(books: books, pages: pages).breadcrumbs(outro);

    expect(crumbs.map((crumb) => crumb.resource), [libraryId, atlas, outro]);
    expect(crumbs[0].siblings, unorderedEquals([libraryId, taxonomyId]));
    expect(crumbs[1].siblings, unorderedEquals([atlas, zebra]));
    expect(crumbs[2].siblings, unorderedEquals([intro, outro]));
  });

  testWidgets("a breadcrumb offers its siblings in the order the user reads "
      "them", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: books, pages: pages),
    ]);
    final scope = panel.world.requireRealm.scope;
    final crumbs = panel.working.breadcrumbs(outro);

    List<ResourceCrumbChoice> choices(ResourceCrumb crumb) =>
        panel.container.read(resourceCrumbChoicesProvider(scope, crumb));

    expect(choices(crumbs[1]).map((choice) => choice.appearance.label), [
      "Atlas",
      "Zebra",
    ]);
    expect(choices(crumbs[2]).map((choice) => choice.resource), [intro, outro]);
  });

  test("a section's breadcrumb is the section itself among the sections", () {
    final crumbs = realmDocument().breadcrumbs(taxonomyId);

    expect(crumbs.single.resource, taxonomyId);
    expect(crumbs.single.siblings, unorderedEquals([libraryId, taxonomyId]));
  });
}
