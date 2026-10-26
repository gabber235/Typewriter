import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The Book of [fixtureRealmShowcase].
final fixtureShowcaseBook = skir.ResourceId(value: "book:showcase");

/// A page of [fixtureRealmShowcase] inside the chapter `act1.arrival`.
final fixtureShowcasePage = skir.ResourceId(value: "page:showcase:arrival");

/// A provisioned realm with a few Books, a chaptered Book, and placed tags:
/// enough to show every place of the realm shell.
AuthoringDocument fixtureRealmShowcase() {
  final tags = [
    Tag(
      tagId: _questTag,
      name: "Quest",
      color: Color(0xff3f51b5),
      placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
    ),
    Tag(
      tagId: skir.ResourceId(value: "tag:showcase:main"),
      name: "Main story",
      color: const Color(0xff009688),
      parentIds: [_questTag],
      placement: const GraphPlacement(x: 0, y: 3, width: 4, height: 1),
    ),
  ];
  return fixtureAuthoringDocument(
    realm: true,
    tags: tags,
    books: [
      Book(
        bookId: fixtureShowcaseBook,
        title: "The Lost Village",
        icon: "material-symbols:book",
        color: const Color(0xff3f51b5),
        tagIds: [tags.first.tagId],
      ),
      Book(
        bookId: skir.ResourceId(value: "book:showcase:atlas"),
        title: "Atlas of Echoes",
        icon: "material-symbols:map",
        color: const Color(0xff795548),
      ),
    ],
    pages: [
      Page(
        pageId: skir.ResourceId(value: "page:showcase:prologue"),
        bookId: fixtureShowcaseBook,
        name: "Prologue",
      ),
      Page(
        pageId: fixtureShowcasePage,
        bookId: fixtureShowcaseBook,
        name: "Arrival",
        chapter: "act1.arrival",
      ),
      Page(
        pageId: skir.ResourceId(value: "page:showcase:market"),
        bookId: fixtureShowcaseBook,
        name: "Market",
        chapter: "act1",
      ),
      Page(
        pageId: skir.ResourceId(value: "page:showcase:finale"),
        bookId: fixtureShowcaseBook,
        name: "Finale",
        chapter: "act2",
      ),
    ],
  );
}

final _questTag = skir.ResourceId(value: "tag:showcase:quest");
