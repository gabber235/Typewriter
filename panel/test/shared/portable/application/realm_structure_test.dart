import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  final catalog = authoringFixtureCatalog();
  skir.TypeSelection selection(String kind) =>
      catalog.beginSelection(fixtureResourceType(kind));

  test("creatable types exclude the realm root and its sections", () {
    expect(catalog.creatableTypes.toSet(), {
      fixtureResourceType("book"),
      fixtureResourceType("page"),
      fixtureResourceType("tag"),
    });
    expect(catalog.isRealmRoot(selection("realm")), isTrue);
    expect(catalog.isRealmSection(selection("library")), isTrue);
    expect(catalog.isRealmSection(selection("taxonomy")), isTrue);
    expect(catalog.isRealmSection(selection("book")), isFalse);
  });

  test("creation templates are keyed by creatable types", () {
    expect(
      catalog.resourceCreationTemplate(fixtureResourceType("book")),
      ResourceCreationTemplate(
        type: fixtureResourceType("book"),
        configuration: selection("book"),
      ),
    );
    expect(
      catalog.resourceCreationTemplate(fixtureResourceType("library")),
      isNull,
    );
    expect(
      catalog.resourceCreationTemplate(fixtureResourceType("realm")),
      isNull,
    );
  });

  test(
    "owning fields name the link fields a resource owns members through",
    () {
      final pages = catalog.owningFields(selection("book")).single;
      expect(pages.field, "pages");
      expect(pages.memberType, fixtureResourceType("page"));
      expect(
        pages.ownership.member.id.value,
        "$fixtureBookPagesRelation:second",
      );
      expect(
        catalog.owningFieldAt(selection("book"), editorRootPath.field("pages")),
        pages,
      );
      expect(
        catalog.owningFieldAt(selection("book"), editorRootPath.field("tags")),
        isNull,
      );
      expect(catalog.owningFields(selection("tag")), isEmpty);
    },
  );

  test("declared presentations ignore role fallbacks", () {
    expect(
      catalog.declaresPresentation(
        selection("page"),
        skir.PresentationRole.workspace,
      ),
      isTrue,
    );
    expect(
      catalog.declaresPresentation(
        selection("book"),
        skir.PresentationRole.workspace,
      ),
      isFalse,
    );
    expect(
      catalog.declaresPresentation(
        selection("book"),
        skir.PresentationRole.navigator,
      ),
      isTrue,
    );
  });
}
