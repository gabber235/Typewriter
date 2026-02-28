import "dart:async";

import "package:faker/faker.dart" hide Color;
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

Book Function() generateRandomBook(List<Tag> tags) {
  return () {
    final icon = "book";
    final possibleTagIds = tags.map((tag) => tag.tagId).toList();
    final tagIds = <String>[];
    var chance = 0.9;
    while (random.decimal() < chance && tagIds.length < tags.length) {
      chance *= 0.7;
      final tag = possibleTagIds.randomElement();
      tagIds.add(tag);
      possibleTagIds.remove(tag);
    }
    final title = faker.lorem
        .words(random.integer(4, min: 1))
        .join(" ")
        .snakeCase();

    return Book(
      bookId: title,
      title: title,
      icon: icon,
      color: safeColors.randomElement().toProtoColor(),
      tagIds: tagIds,
    );
  };
}

class BooksMock extends Books {
  BooksMock(this.displayState);
  final DisplayState displayState;

  @override
  Stream<List<Book>> build() async* {
    final tagsIds = await ref.watch(tagsProvider.future);
    yield await displayState.generate(generateRandomBook(tagsIds));
  }

  @override
  Future<Book> createBook({
    required String title,
    String? icon,
    Color? color,
    List<String> tagIds = const [],
  }) async {
    await Future.delayed(500.ms);
    final newBook = Book(
      bookId: faker.lorem
          .words(random.integer(4, min: 1))
          .join(" ")
          .snakeCase(),
      title: title,
      icon: icon ?? "book",
      color: (color ?? safeColors.randomElement()).toProtoColor(),
      tagIds: tagIds.isEmpty ? [] : tagIds,
    );

    final books = await future;
    state = AsyncData([...books, newBook]);
    return newBook;
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
}) => [booksProvider.overrideWith(() => BooksMock(state))];
