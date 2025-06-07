import "package:faker/faker.dart";
import "package:mocktail/mocktail.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/tag.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:widgetbook_workspace/logic/tag.mock.dart";

enum MockBooksState { loading, noBooks, fewBooks, manyBooks, error }

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

List<Book> generateBooks(int count) =>
    List.generate(count, (_) => generateRandomBook());

BooksMock createBooksMockForState(MockBooksState state) {
  final books = BooksMock();
  when(books.build).thenAnswer(
    (_) => switch (state) {
      MockBooksState.loading => Future.delayed(
        Duration(days: 100000),
        () => [],
      ),
      MockBooksState.noBooks => Future.value([]),
      MockBooksState.fewBooks => Future.value(generateBooks(5)),
      MockBooksState.manyBooks => Future.value(generateBooks(100)),
      MockBooksState.error => Future.error(Exception("Error")),
    },
  );
  return books;
}

List<Override> booksProviderOverrides({
  MockBooksState state = MockBooksState.loading,
}) => [booksProvider.overrideWith(() => createBooksMockForState(state))];
