import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test("breadcrumbs follow the owner chain below the root with siblings", () {
    final first = skir.ResourceId(value: "book:first");
    final second = skir.ResourceId(value: "book:second");
    final intro = skir.ResourceId(value: "page:intro");
    final outro = skir.ResourceId(value: "page:outro");
    final document = fixtureAuthoringDocument(
      realm: true,
      books: [
        Book(
          bookId: second,
          title: "Zebra",
          icon: "mdi:book",
          color: Colors.blue,
        ),
        Book(
          bookId: first,
          title: "Atlas",
          icon: "mdi:book",
          color: Colors.blue,
        ),
      ],
      pages: [
        Page(pageId: outro, bookId: first, name: "Outro"),
        Page(pageId: intro, bookId: first, name: "Intro"),
      ],
    );

    final crumbs = document.breadcrumbs(outro);

    expect(crumbs.map((crumb) => crumb.resource), [
      fixtureLibraryId,
      first,
      outro,
    ]);
    expect(
      crumbs[0].siblings,
      unorderedEquals([fixtureLibraryId, fixtureTaxonomyId]),
    );
    expect(crumbs[1].siblings, unorderedEquals([first, second]));
    expect(crumbs[2].siblings, unorderedEquals([intro, outro]));

    final scope = AuthoringScope(
      organizationId: skir.recordId("organization:crumbs"),
      realmId: skir.recordId("realm:crumbs"),
    );
    final container = ProviderContainer.test(
      overrides: [
        workingAuthoringDocumentProvider(scope)
            .overrideWithValue(AsyncData(document)),
      ],
    );
    expect(
      container
          .read(resourceCrumbChoicesProvider(scope, crumbs[1]))
          .map((choice) => choice.appearance.label),
      ["Atlas", "Zebra"],
    );
    expect(
      container
          .read(resourceCrumbChoicesProvider(scope, crumbs[2]))
          .map((choice) => choice.resource),
      [intro, outro],
    );
  });

  test("a section's breadcrumb is the section itself", () {
    final document = fixtureAuthoringDocument(realm: true);

    final crumbs = document.breadcrumbs(fixtureTaxonomyId);

    expect(crumbs.single.resource, fixtureTaxonomyId);
    expect(crumbs.single.siblings, hasLength(2));
  });
}
