import "package:flutter/material.dart" hide Page;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("Tag projection overlays edited fields onto fresh canonical data", () {
    final canonical = Tag(
      tagId: skir.ResourceId(value: "test"),
      name: "Remote name",
      color: Colors.blue,
      parentIds: const [],
      placement: GraphPlacement(x: 1, y: 2, width: 3, height: 4),
    );
    final withDraftName = DataPath.root
        .field("name")
        .replace(canonical.inspectorValue, "Draft name".asValue)
        .valueOrNull!;
    final draft = DataPath.root
        .field("color")
        .replace(withDraftName, Colors.red.asValue)
        .valueOrNull!;

    final projected = canonical.projected(
      LocalEditorValue(
        value: draft,
        editedPaths: {DataPath.root.field("name")},
      ),
    );

    expect(projected.name, "Draft name");
    expect(projected.color.toARGB32(), Colors.blue.toARGB32());
    expect(projected.placement, canonical.placement);
  });

  test("Book and Page projections decode domain values", () {
    final book = Book(
      bookId: skir.ResourceId(value: "test"),
      title: "Remote title",
      icon: "mdi:book",
      color: Colors.blue,
      tagIds: const [],
    );
    final bookDraft = DataPath.root
        .field("color")
        .replace(book.inspectorValue, Colors.red.asValue)
        .valueOrNull!;
    expect(
      book
          .projected(
            LocalEditorValue(
              value: bookDraft,
              editedPaths: {DataPath.root.field("color")},
            ),
          )
          .color
          .toARGB32(),
      Colors.red.toARGB32(),
    );

    final page = Page(
      pageId: skir.ResourceId(value: "test"),
      bookId: book.bookId,
      name: "Remote page",
      kind: const PageKindRef(id: "kind", revision: 1),
      chapter: "remote",
      priority: 1,
    );
    final pageDraft = DataPath.root
        .field("chapter")
        .replace(page.editorValue, "draft".asValue)
        .valueOrNull!;
    final projectedPage = page.projected(
      LocalEditorValue(
        value: pageDraft,
        editedPaths: {DataPath.root.field("chapter")},
      ),
    );
    expect(projectedPage.chapter, "draft");
    expect(projectedPage.name, "Remote page");
  });
}
