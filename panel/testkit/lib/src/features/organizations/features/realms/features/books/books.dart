import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:faker/faker.dart" hide Color, random;

// ignore: depend_on_referenced_packages, implementation_imports

export "features/features.dart";

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
