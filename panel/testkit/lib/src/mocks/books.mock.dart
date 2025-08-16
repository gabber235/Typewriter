import "package:faker/faker.dart";
import "package:mocktail/mocktail.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/tag.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

Book generateRandomBook() {
  final icon = "book";
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
    icon: icon,
    color: safeColors.randomOrNull()!,
    tags: tags,
  );
}

BooksMock createBooksMockForState(DisplayState state) {
  final books = BooksMock();
  when(books.build).thenAnswer(
    (_) => state.generate(generateRandomBook),
  );
  when(() => books.updateBook(any())).thenAnswer((_) => Future.value());
  return books;
}

List<Override> booksProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [booksProvider.overrideWith(() => createBooksMockForState(state))];
