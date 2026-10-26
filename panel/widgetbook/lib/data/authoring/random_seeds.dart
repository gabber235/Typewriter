import "package:faker/faker.dart" hide Color, random;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

part "random_tags.dart";

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
