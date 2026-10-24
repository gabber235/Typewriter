import "package:faker/faker.dart" hide Color, random;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

part "authoring_seed_layout.dart";

/// A Book a fixture document starts with. Seeds describe fixture content; the
/// panel reads it back through the working document like any resource.
final class Book {
  const Book({
    required this.bookId,
    required this.title,
    required this.icon,
    required this.color,
    this.tagIds = const [],
  });

  final skir.ResourceId bookId;
  final String title;
  final String icon;
  final Color color;
  final List<skir.ResourceId> tagIds;

  Book copyWith({
    skir.ResourceId? bookId,
    String? title,
    String? icon,
    Color? color,
    List<skir.ResourceId>? tagIds,
  }) => Book(
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    tagIds: tagIds ?? this.tagIds,
  );
}

/// A Tag a fixture document starts with, placed on the tag graph.
final class Tag {
  const Tag({
    required this.tagId,
    required this.name,
    required this.color,
    this.parentIds = const [],
    this.placement = const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
  });

  final skir.ResourceId tagId;
  final String name;
  final Color color;
  final List<skir.ResourceId> parentIds;
  final GraphPlacement placement;

  Tag copyWith({
    skir.ResourceId? tagId,
    String? name,
    Color? color,
    List<skir.ResourceId>? parentIds,
    GraphPlacement? placement,
  }) => Tag(
    tagId: tagId ?? this.tagId,
    name: name ?? this.name,
    color: color ?? this.color,
    parentIds: parentIds ?? this.parentIds,
    placement: placement ?? this.placement,
  );
}

/// A page a fixture document starts with, owned by [bookId] when present.
final class Page {
  const Page({
    required this.pageId,
    required this.name,
    this.bookId,
    this.chapter = "",
    this.priority = 0,
  });

  final skir.ResourceId pageId;
  final skir.ResourceId? bookId;
  final String name;
  final String chapter;
  final int priority;

  Page copyWith({
    skir.ResourceId? pageId,
    skir.ResourceId? bookId,
    String? name,
    String? chapter,
    int? priority,
  }) => Page(
    pageId: pageId ?? this.pageId,
    bookId: bookId ?? this.bookId,
    name: name ?? this.name,
    chapter: chapter ?? this.chapter,
    priority: priority ?? this.priority,
  );
}

Book Function() generateRandomBook(List<Tag> tags) {
  return () {
    final possibleTagIds = tags.map((tag) => tag.tagId).toList();
    final tagIds = <skir.ResourceId>[];
    var chance = 0.9;
    while (faker.randomGenerator.decimal() < chance &&
        tagIds.length < tags.length) {
      chance *= 0.7;
      final tag = possibleTagIds.randomElement();
      tagIds.add(tag);
      possibleTagIds.remove(tag);
    }
    final title = faker.lorem
        .words(faker.randomGenerator.integer(4, min: 1))
        .join(" ")
        .snakeCase();

    return Book(
      bookId: skir.ResourceId(value: "book:$title"),
      title: title,
      icon: "book",
      color: safeColors.randomElement(),
      tagIds: tagIds,
    );
  };
}

Page generateRandomPage({skir.ResourceId? bookId}) {
  final pageName = faker.lorem
      .words(faker.randomGenerator.integer(3, min: 1))
      .join("_")
      .snakeCase();
  final chapters = [
    "",
    "intro",
    "example.test",
    "main",
    "main.side_quests",
    "main.epilogue",
  ];
  return Page(
    pageId: skir.ResourceId(value: "page:${faker.guid.guid()}"),
    bookId: bookId,
    name: pageName,
    chapter: chapters.randomOrNull() ?? "",
    priority: faker.randomGenerator.integer(100, min: -10),
  );
}

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
