import "package:faker/faker.dart";
import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/application/books.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/presentation/book.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/extensions.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/shared/utilities/collection.dart";
import "package:typewriter_panel/shared/utilities/color.dart";
import "package:typewriter_panel/shared/utilities/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

Book generateRandomBook() {
  final icon = Fa6Solid.iconsList.randomOrNull();

  final title = faker.lorem
      .words(random.integer(4, min: 1))
      .join(" ")
      .snakeCase();
  return Book()
    ..bookId = title
    ..title = title
    ..icon = icon ?? "book"
    ..color = safeColors.randomElement().toProtoColor();
}

@widgetbook.UseCase(name: "Default", type: BookWidget)
Widget bookUseCase(BuildContext context) {
  final book = generateRandomBook();

  final tags = <Tag>[];
  var chance = 0.9;
  while (random.decimal() < chance) {
    chance *= 0.7;
    final tag = generateRandomTag();
    tags.add(tag);
  }

  return FakeApp(
    child: BookWidget(
      id: book.bookId,
      title: book.title,
      icon: Icones(book.icon),
      color: book.flutterColor,
      tags: tags,
    ),
  );
}
