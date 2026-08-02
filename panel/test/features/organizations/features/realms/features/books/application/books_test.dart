import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

class _MockBooks extends Books {
  _MockBooks(this._books);

  final List<Book> _books;

  @override
  Stream<List<Book>> build() async* {
    yield _books;
  }
}

Book _book(String id, String title, {List<skir.RecordId> tagIds = const []}) {
  return Book(
    bookId: recordId("book:$id"),
    title: title,
    icon: "book",
    color: Colors.blue,
    tagIds: tagIds,
  );
}

Tag _tag(String id) {
  return Tag(
    tagId: recordId("tag:$id"),
    name: id,
    color: Colors.blue,
    parentIds: const [],
    placement: const Placement(x: 0, y: 0, width: 4, height: 1),
  );
}

void main() {
  group("filteredBooks", () {
    final testBooks = [
      _book("book1", "Quest for Glory", tagIds: [recordId("tag:adventure")]),
      _book(
        "book2",
        "Mystery Manor",
        tagIds: [recordId("tag:mystery"), recordId("tag:horror")],
      ),
      _book("book3", "Space Explorers", tagIds: [recordId("tag:scifi")]),
    ];

    final testTags = [
      _tag("adventure"),
      _tag("mystery"),
      _tag("horror"),
      _tag("scifi"),
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
      final container = ProviderContainer.test(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );

      final result = await getFilteredBooks(container, "");

      expect(result.length, 3);
    });

    test("matches book title case-insensitively", () async {
      final container = ProviderContainer.test(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );

      final result = await getFilteredBooks(container, "QUEST");

      expect(result.length, 1);
      expect(result.first.bookId, recordId("book:book1"));
    });

    test("matches book title with partial query", () async {
      final container = ProviderContainer.test(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );

      final result = await getFilteredBooks(container, "glory");

      expect(result.length, 1);
      expect(result.first.title, "Quest for Glory");
    });

    test("matches book tags case-insensitively", () async {
      final container = ProviderContainer.test(
        overrides: [
          booksProvider.overrideWith(() => _MockBooks(testBooks)),
          ...tagsProviderOverrides(
            state: DisplayState.fewItems,
            tags: testTags,
          ),
        ],
      );

      final result = await getFilteredBooks(container, "ADVENTURE");

      expect(result.length, 1);
      expect(result.first.bookId, recordId("book:book1"));
    });

    test("matches any of multiple tags", () async {
      final container = ProviderContainer.test(
        overrides: [
          booksProvider.overrideWith(() => _MockBooks(testBooks)),
          ...tagsProviderOverrides(
            state: DisplayState.fewItems,
            tags: testTags,
          ),
        ],
      );

      final result = await getFilteredBooks(container, "horror");

      expect(result.length, 1);
      expect(result.first.bookId, recordId("book:book2"));
    });

    test("returns empty list when no matches", () async {
      final container = ProviderContainer.test(
        overrides: [booksProvider.overrideWith(() => _MockBooks(testBooks))],
      );

      final result = await getFilteredBooks(container, "zombies");

      expect(result, isEmpty);
    });

    test("handles books with no tags", () async {
      final booksWithNoTags = [_book("book_no_tags", "Tagless Adventure")];

      final container = ProviderContainer.test(
        overrides: [
          booksProvider.overrideWith(() => _MockBooks(booksWithNoTags)),
          tagsProvider.overrideWith(
            () => TagsMock(
              displayState: DisplayState.fewItems,
              specificTags: testTags,
            ),
          ),
        ],
      );

      final result = await getFilteredBooks(container, "adventure");

      expect(result, isNotEmpty);
    });

    test("handles empty book list", () async {
      final container = ProviderContainer.test(
        overrides: [booksProvider.overrideWith(() => _MockBooks(<Book>[]))],
      );

      final result = await getFilteredBooks(container, "anything");

      expect(result, isEmpty);
    });
  });

  group("Book.copyWith", () {
    test("creates copy with new color preserving other fields", () {
      final original = _book(
        "book123",
        "Original Title",
      ).copyWith(color: const Color(0xFF646464));

      final updated = original.copyWith(color: Colors.red);

      expect(updated.bookId, recordId("book:book123"));
      expect(updated.title, "Original Title");
      expect(updated.color, Colors.red);
    });

    test("does not modify original book", () {
      final original = _book(
        "book123",
        "Test",
      ).copyWith(color: const Color(0xFF323232));

      final updated = original.copyWith(color: Colors.blue);

      expect(original.color, const Color(0xFF323232));
      expect(updated.color, Colors.blue);
    });
  });

  group("BookIdentifier", () {
    test("equality works correctly", () {
      final id1 = BookIdentifier(recordId("book:abc"));
      final id2 = BookIdentifier(recordId("book:abc"));
      final id3 = BookIdentifier(recordId("book:xyz"));

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
    });

    test("hashCode is consistent with equality", () {
      final id1 = BookIdentifier(recordId("book:abc"));
      final id2 = BookIdentifier(recordId("book:abc"));

      expect(id1.hashCode, equals(id2.hashCode));
    });

    test("can be used as map key", () {
      final map = <BookIdentifier, String>{};
      final id1 = BookIdentifier(recordId("book:one"));
      final id2 = BookIdentifier(recordId("book:one"));

      map[id1] = "value1";
      map[id2] = "value2";

      expect(map.length, 1);
      expect(map[id1], "value2");
    });

    test("toString returns descriptive string", () {
      final id = BookIdentifier(recordId("book:book123"));

      expect(id.toString(), contains("book123"));
    });
  });
}
