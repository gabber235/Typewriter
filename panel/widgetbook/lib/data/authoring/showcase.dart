import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The chaptered Book of the [showcaseRealm].
final showcaseBook = Book(
  bookId: skir.ResourceId(value: "book:the_lost_village"),
  title: "The Lost Village",
  icon: "material-symbols:book",
  color: const Color(0xff3f51b5),
  tagIds: [_quest.tagId],
);

/// A page of [showcaseBook] inside the chapter `act1.arrival`.
final showcasePage = Page(
  pageId: skir.ResourceId(value: "page:arrival"),
  bookId: showcaseBook.bookId,
  name: "Arrival",
  chapter: "act1.arrival",
);

final _quest = Tag(
  tagId: skir.ResourceId(value: "tag:quest"),
  name: "Quest",
  color: const Color(0xff3f51b5),
  placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
);

final _mainStory = Tag(
  tagId: skir.ResourceId(value: "tag:main_story"),
  name: "Main story",
  color: const Color(0xff009688),
  parentIds: [_quest.tagId],
  placement: const GraphPlacement(x: 0, y: 3, width: 4, height: 1),
);

/// A Realm named [name] with a few Books, a chaptered Book and placed tags:
/// enough to show every place of the realm shell.
Trait showcaseRealm({String name = "Main"}) => realm(
  name: name,
  tags: [_quest, _mainStory],
  books: [
    showcaseBook,
    Book(
      bookId: skir.ResourceId(value: "book:atlas_of_echoes"),
      title: "Atlas of Echoes",
      icon: "material-symbols:map",
      color: const Color(0xff795548),
    ),
  ],
  pages: [
    Page(
      pageId: skir.ResourceId(value: "page:prologue"),
      bookId: showcaseBook.bookId,
      name: "Prologue",
    ),
    showcasePage,
    Page(
      pageId: skir.ResourceId(value: "page:market"),
      bookId: showcaseBook.bookId,
      name: "Market",
      chapter: "act1",
    ),
    Page(
      pageId: skir.ResourceId(value: "page:finale"),
      bookId: showcaseBook.bookId,
      name: "Finale",
      chapter: "act2",
    ),
  ],
);
