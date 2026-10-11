import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test("ownership follows the declared endpoint direction", () {
    final document = _document();

    expect(document.relations.ownerPath(_pageId).owners, [_firstBookId]);
    expect(document.relations.ownedBy(_firstBookId), [_pageId]);
  });

  test(
    "ownership projections cannot be mutated through nested collections",
    () {
      final relations = _document().relations;

      expect(
        () => relations.parents[_pageId]!.add(_secondBookId),
        throwsUnsupportedError,
      );
      expect(
        () => relations.ownedBy(_firstBookId).clear(),
        throwsUnsupportedError,
      );
    },
  );

  test("ownership reports ambiguous parents", () {
    final document = _document();
    final ambiguous = document.copyWith(
      links: [
        ...document.links,
        skir.LinkProjection(
          contract: skir.RelationId(value: "fixture.book.pages"),
          first: _secondBookId,
          second: _pageId,
          firstLocation: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "pages")],
          ),
          secondLocation: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "book")],
          ),
        ),
      ],
    );

    expect(
      ambiguous.relations.ownerPath(_pageId).problem,
      "Resource has multiple owners",
    );
  });

  test("ownership keeps diagnostics local to touched resources", () {
    final document = _document();
    final missing = skir.ResourceId(value: "page:missing");
    final invalid = document.copyWith(
      links: [
        ...document.links,
        skir.LinkProjection(
          contract: skir.RelationId(value: "fixture.book.pages"),
          first: _secondBookId,
          second: missing,
          firstLocation: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "pages")],
          ),
          secondLocation: null,
        ),
      ],
    );

    expect(invalid.relations.ownerPath(_pageId).problem, isNull);
    expect(
      invalid.relations.ownerPath(missing).problem,
      contains("references an absent resource"),
    );
  });
}

final _firstBookId = skir.ResourceId(value: "book:first");
final _secondBookId = skir.ResourceId(value: "book:second");
final _pageId = skir.ResourceId(value: "page:owned");

AuthoringDocument _document() => fixtureAuthoringDocument(
  books: [
    Book(
      bookId: _firstBookId,
      title: "First",
      icon: "mdi:book",
      color: Colors.blue,
      tagIds: const [],
    ),
    Book(
      bookId: _secondBookId,
      title: "Second",
      icon: "mdi:book",
      color: Colors.red,
      tagIds: const [],
    ),
  ],
  pages: [
    Page(
      pageId: _pageId,
      bookId: _firstBookId,
      name: "Owned",
      configuration: skir.TypeSelection.unknown,
      chapter: "",
      priority: 0,
    ),
  ],
);
