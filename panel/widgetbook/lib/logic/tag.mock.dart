import "package:faker/faker.dart";
import "package:typewriter_panel/logic/tag.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/number.dart";
import "package:typewriter_panel/utils/string.dart";

Tag? generateRandomTag([double change = 1, double decrease = 0.6]) {
  if (change <= epsilon) return null;
  final r = random.decimal();
  if (r > change) return null;
  final parents = <Tag>[];
  while (true) {
    final parent = generateRandomTag(change * decrease, decrease);
    if (parent == null) break;
    parents.add(parent);
  }
  return Tag(
    id: faker.guid.guid(),
    name: faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase(),
    color: safeColors.randomOrNull()!,
    parents: parents,
  );
}

Tag ensureRandomTag([double change = 1, double decrease = 0.6]) {
  var tag = generateRandomTag(change, decrease);
  while (tag == null) {
    tag = generateRandomTag(change, decrease);
  }
  return tag;
}
