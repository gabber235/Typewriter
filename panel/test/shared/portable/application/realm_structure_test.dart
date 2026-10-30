import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final catalog = libraryCatalog();

  test("creatable types exclude the realm root and its sections", () {
    expect(catalog.creatableTypes.toSet(), {
      libraryType("book"),
      libraryType("page"),
      libraryType("tag"),
      libraryType("track"),
      libraryType("cue"),
    });
    expect(
      catalog.isRealmRoot(catalog.beginSelection(libraryType("realm"))),
      isTrue,
    );
    expect(
      catalog.isRealmSection(catalog.beginSelection(libraryType("library"))),
      isTrue,
    );
    expect(
      catalog.isRealmSection(catalog.beginSelection(libraryType("taxonomy"))),
      isTrue,
    );
    expect(
      catalog.isRealmSection(catalog.beginSelection(libraryType("scene"))),
      isTrue,
    );
    expect(
      catalog.isRealmSection(catalog.beginSelection(libraryType("book"))),
      isFalse,
    );
  });

  test("creation templates are keyed by creatable types", () {
    expect(
      catalog.resourceCreationTemplate(libraryType("book")),
      ResourceCreationTemplate(
        type: libraryType("book"),
        configuration: catalog.beginSelection(libraryType("book")),
      ),
    );
    expect(catalog.resourceCreationTemplate(libraryType("library")), isNull);
    expect(catalog.resourceCreationTemplate(libraryType("realm")), isNull);
  });

  test(
    "owning fields name the link fields a resource owns members through",
    () {
      final pages = catalog
          .owningFields(catalog.beginSelection(libraryType("book")))
          .single;
      expect(pages.field, "pages");
      expect(pages.memberType, libraryType("page"));
      expect(pages.ownership.member.id.value, "$bookPagesRelation:second");
      expect(
        catalog.owningFieldAt(
          catalog.beginSelection(libraryType("book")),
          editorRootPath.field("pages"),
        ),
        pages,
      );
      expect(
        catalog.owningFieldAt(
          catalog.beginSelection(libraryType("book")),
          editorRootPath.field("tags"),
        ),
        isNull,
      );
      expect(
        catalog.owningFields(catalog.beginSelection(libraryType("tag"))),
        isEmpty,
      );
    },
  );

  test("declared presentations ignore role fallbacks", () {
    expect(
      catalog.declaresPresentation(
        catalog.beginSelection(libraryType("page")),
        skir.PresentationRole.workspace,
      ),
      isTrue,
    );
    expect(
      catalog.declaresPresentation(
        catalog.beginSelection(libraryType("book")),
        skir.PresentationRole.workspace,
      ),
      isFalse,
    );
    expect(
      catalog.declaresPresentation(
        catalog.beginSelection(libraryType("book")),
        skir.PresentationRole.navigator,
      ),
      isTrue,
    );
  });
}
