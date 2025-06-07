import "package:faker/faker.dart";
import "package:flutter/material.dart";
import "package:iconify_flutter/icons/fa6_solid.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/tag.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/generic/components/book.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/logic/tag.mock.dart";

Book generateRandomBook() {
  final icon = Fa6Solid.iconsList.randomOrNull();

  final tags = <Tag>[];
  var chance = 0.9;
  while (random.decimal() < chance) {
    chance *= 0.7;
    final tag = generateRandomTag();
    if (tag == null) break;
    tags.add(tag);
  }

  final title =
      faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase();
  return Book(
    id: title,
    title: title,
    icon: icon ?? "book",
    color: safeColors.randomOrNull()!,
    tags: tags,
  );
}

@widgetbook.UseCase(name: "Default", type: BookWidget)
Widget bookUseCase(BuildContext context) {
  final book = generateRandomBook();
  return BookWidget(
    title: book.title,
    icon: Icones(book.icon),
    color: book.color,
    tags: book.tags,
  );
}
