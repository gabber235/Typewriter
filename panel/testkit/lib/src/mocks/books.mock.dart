import "dart:async";

import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/pages/pages.dart";
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

class BooksMock extends Books {
  BooksMock(this.displayState);
  final DisplayState displayState;

  @override
  FutureOr<List<Book>> build() async {
    return displayState.generate(generateRandomBook);
  }

  @override
  Future<void> updateBook(Book book) async {
    await Future.delayed(500.ms);
  }

  @override
  Future<String> createPage(
    String bookId,
    String name,
    PageType type,
    String chapter,
    int priority,
  ) async {
    await Future.delayed(500.ms);
    return faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase();
  }

  @override
  Future<void> deletePage(String pageId) async {
    await Future.delayed(500.ms);
  }

  @override
  Future<void> changePagesChapters(
    String bookId,
    String oldChapter,
    String newChapter,
  ) async {
    await Future.delayed(500.ms);
  }
}

List<Override> booksProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [booksProvider.overrideWith(() => BooksMock(state))];
