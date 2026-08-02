import "dart:async";

import "package:faker/faker.dart" hide Color;
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/data_blueprint.dart";
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

Book Function() generateRandomBook(List<Tag> tags) {
  return () {
    final possibleTagIds = tags.map((tag) => tag.tagId).toList();
    final tagIds = <skir.RecordId>[];
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
      bookId: recordId("book:$title"),
      title: title,
      icon: generateRandomIconName(),
      color: safeColors.randomElement(),
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
    List<skir.RecordId> tagIds = const [],
  }) async {
    await Future.delayed(500.ms);
    final newBook = Book(
      bookId: recordId(
        "book:${faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase()}",
      ),
      title: title,
      icon: icon ?? "book",
      color: color ?? safeColors.randomElement(),
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
  Future<skir.RecordId> createPage(
    skir.RecordId bookId,
    String name,
    skir.PageType type,
    String chapter,
    int priority,
  ) async {
    await Future.delayed(500.ms);
    final id = faker.lorem
        .words(random.integer(4, min: 1))
        .join(" ")
        .snakeCase();
    return recordId("page:$id");
  }

  @override
  Future<void> deletePage(skir.RecordId pageId) async {
    await Future.delayed(500.ms);
  }

  @override
  Future<void> changePagesChapters(
    skir.RecordId bookId,
    String oldChapter,
    String newChapter,
  ) async {
    await Future.delayed(500.ms);
  }
}

List<Override> booksProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [booksProvider.overrideWith(() => BooksMock(state))];
