import "dart:async";

import "package:faker/faker.dart" hide Color;
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/editor.dart";
import "package:typewriter_testkit/src/shared/testing/testing.dart";

export "features/features.dart";

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

class BooksMock extends CanonicalBooks {
  BooksMock(this.displayState, {this.specificBooks});
  final DisplayState displayState;
  final List<Book>? specificBooks;

  @override
  Future<List<Book>> build() async {
    if (specificBooks != null) return specificBooks!;
    final tagsIds = await ref.watch(canonicalTagsProvider.future);
    return displayState.generate(generateRandomBook(tagsIds));
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
      icon: icon ?? "mdi:book",
      color: color ?? safeColors.randomElement(),
      tagIds: tagIds.isEmpty ? [] : tagIds,
    );

    final books = await future;
    state = AsyncData([...books, newBook]);
    return newBook;
  }

  @override
  Future<TypedMutationResult> updateBook(Book book, {Book? expected}) async {
    await Future.delayed(500.ms);
    final canonical = book;
    state = AsyncData(
      (await future)
          .map((value) => value.bookId == book.bookId ? canonical : value)
          .toList(),
    );
    return TypedMutationResult.success(
      revision: 1,
      value: canonical.inspectorValue,
    );
  }
}

List<Override> booksProviderOverrides({
  DisplayState state = DisplayState.loading,
  List<Book>? books,
}) => [
  canonicalBooksProvider.overrideWith(
    () => BooksMock(state, specificBooks: books),
  ),
];
