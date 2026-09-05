import "dart:async";

import "package:faker/faker.dart" hide Color;
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/typed_data.dart";
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
      authoringSequence: 1,
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
  Future<List<Book>> build() async {
    final tagsIds = await ref.watch(tagsProvider.future);
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
      authoringSequence: 1,
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
    final canonical = book.copyWith(
      authoringSequence: book.authoringSequence + 1,
    );
    state = AsyncData(
      (await future)
          .map((value) => value.bookId == book.bookId ? canonical : value)
          .toList(),
    );
    return TypedMutationResult.success(
      revision: canonical.authoringSequence,
      value: bookMockInspectorValue(canonical),
    );
  }
}

List<Override> booksProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [booksProvider.overrideWith(() => BooksMock(state))];

RecordValue bookMockInspectorValue(Book book) => RecordValue({
  "title": StringValue(book.title),
  "icon": IconValue.from(book.icon).typedValue,
  "color": book.color.integerValue,
  "tags": ListValue(book.tagIds.map((tagId) => StringValue(tagId.id)).toList()),
});
