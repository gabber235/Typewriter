import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/generated/models/common.pb.dart" as proto;
import "package:typewriter_panel/logic/books.dart";

class _MockBooks extends Books {
  _MockBooks(this._books);

  final List<Book> _books;

  @override
  Stream<List<Book>> build() async* {
    yield _books;
  }
}

void main() {
  group("filteredBooks", () {
    final testBooks = [
      Book()
        ..id = "book-1"
        ..title = "Quest for Glory"
        ..tags.add(Tag()..name = "adventure"),
      Book()
        ..id = "book-2"
        ..title = "Mystery Manor"
        ..tags.addAll([Tag()..name = "mystery", Tag()..name = "horror"]),
      Book()
        ..id = "book-3"
        ..title = "Space Explorers"
        ..tags.add(Tag()..name = "scifi"),
    ];

    Future<List<Book>> getFilteredBooks(
      ProviderContainer container,
      String query,
    ) async {
      final completer = Completer<List<Book>>();
      final sub = container.listen(filteredBooksProvider(query), (
        previous,
        next,
      ) {
        if (next is AsyncData<List<Book>>) {
          if (!completer.isCompleted) {
            completer.complete(next.value);
          }
        } else if (next is AsyncError) {
          if (!completer.isCompleted) {
            completer.completeError(
              next.error ?? StateError("Unknown error"),
              next.stackTrace,
            );
          }
        }
      }, fireImmediately: true);
      try {
        return await completer.future;
      } finally {
        sub.close();
      }
    }

    test("returns all books when query is empty", () async {
      final container = ProviderContainer(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "");

      expect(result.length, 3);
    });

    test("matches book title case-insensitively", () async {
      final container = ProviderContainer(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "QUEST");

      expect(result.length, 1);
      expect(result.first.id, "book-1");
    });

    test("matches book title with partial query", () async {
      final container = ProviderContainer(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "glory");

      expect(result.length, 1);
      expect(result.first.title, "Quest for Glory");
    });

    test("matches book tags case-insensitively", () async {
      final container = ProviderContainer(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "ADVENTURE");

      expect(result.length, 1);
      expect(result.first.id, "book-1");
    });

    test("matches any of multiple tags", () async {
      final container = ProviderContainer(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "horror");

      expect(result.length, 1);
      expect(result.first.id, "book-2");
    });

    test("returns empty list when no matches", () async {
      final container = ProviderContainer(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "zombies");

      expect(result, isEmpty);
    });

    test("handles books with no tags", () async {
      final booksWithNoTags = [
        Book()
          ..id = "book-no-tags"
          ..title = "Tagless Adventure",
      ];

      final container = ProviderContainer(
        overrides: [
          booksProvider.overrideWith(() => _MockBooks(booksWithNoTags)),
        ],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "adventure");

      expect(result.length, 1);
      expect(result.first.id, "book-no-tags");
    });

    test("handles empty book list", () async {
      final container = ProviderContainer(
        overrides: [booksProvider.overrideWith(() => _MockBooks(<Book>[]))],
      );
      addTearDown(container.dispose);

      final result = await getFilteredBooks(container, "anything");

      expect(result, isEmpty);
    });
  });

  group("BookExtension.withColor", () {
    test("creates copy with new color preserving other fields", () {
      final original = Book()
        ..id = "book-123"
        ..title = "Original Title"
        ..color = (proto.Color()..value = 0xFF646464);

      final updated = original.withColor(Colors.red);

      expect(updated.id, "book-123");
      expect(updated.title, "Original Title");
      expect(updated.color.value, Colors.red.toARGB32());
    });

    test("does not modify original book", () {
      final original = Book()
        ..id = "book-123"
        ..title = "Test"
        ..color = (proto.Color()..value = 0xFF323232);

      original.withColor(Colors.blue);

      expect(original.color.value, 0xFF323232);
    });
  });

  group("BookIdentifier", () {
    test("equality works correctly", () {
      final id1 = BookIdentifier("book-abc");
      final id2 = BookIdentifier("book-abc");
      final id3 = BookIdentifier("book-xyz");

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
    });

    test("hashCode is consistent with equality", () {
      final id1 = BookIdentifier("book-abc");
      final id2 = BookIdentifier("book-abc");

      expect(id1.hashCode, equals(id2.hashCode));
    });

    test("can be used as map key", () {
      final map = <BookIdentifier, String>{};
      final id1 = BookIdentifier("book-1");
      final id2 = BookIdentifier("book-1");

      map[id1] = "value1";
      map[id2] = "value2";

      expect(map.length, 1);
      expect(map[id1], "value2");
    });

    test("toString returns descriptive string", () {
      final id = BookIdentifier("book-123");

      expect(id.toString(), contains("book-123"));
    });
  });
}
