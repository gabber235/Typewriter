import "package:flutter/material.dart" hide Page;
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("element type source participates in destination selectors", () {
    final definitions = ValueNotifier<AsyncValue<List<ElementDefinition>>>(
      const AsyncData([]),
    );
    final source = ElementTypeSearchSource(
      definitions: definitions,
      querySelectors: const [
        KeyValueSelectorDefinition(id: authoringBookSelectorId, key: "book:"),
        KeyValueSelectorDefinition(id: authoringPageSelectorId, key: "page:"),
        KeyValueSelectorDefinition(id: authoringTypeSelectorId, key: "type:"),
      ],
    );
    addTearDown(definitions.dispose);
    addTearDown(source.dispose);

    expect(source.selectors.map((selector) => selector.id), [
      "book",
      "page",
      "type",
    ]);
  });

  test("explicit book and page selectors override the current page", () {
    expect(
      resolveElementCreationPage(
        query: _query(book: _otherBook.title, page: _otherPage.name),
        books: [_currentBook, _otherBook],
        pages: [_currentPage, _otherPage],
        currentPage: _currentPage,
      ),
      _otherPage,
    );
    expect(
      resolveElementCreationPage(
        query: _query(book: _otherBook.title),
        books: [_currentBook, _otherBook],
        pages: [_currentPage, _otherPage],
        currentPage: _currentPage,
      ),
      isNull,
    );
  });
}

SearchQueryContext _query({String? book, String? page, String? type}) =>
    SearchQueryContext(
      normalizedQuery: "",
      selectors: [
        if (book != null)
          SearchParsedSelector(selectorId: "book", key: "book:", value: book),
        if (page != null)
          SearchParsedSelector(selectorId: "page", key: "page:", value: page),
        if (type != null)
          SearchParsedSelector(selectorId: "type", key: "type:", value: type),
      ],
    );

final _currentBook = Book(
  bookId: skir.ResourceId(value: "current"),
  title: "Current",
  icon: "mdi:book",
  color: Colors.blue,
  tagIds: const [],
);
final _otherBook = Book(
  bookId: skir.ResourceId(value: "other"),
  title: "Other",
  icon: "mdi:book",
  color: Colors.green,
  tagIds: const [],
);
final _pageType = referenceResourceTypes.page;
final _currentPage = Page(
  pageId: skir.ResourceId(value: "current"),
  bookId: _currentBook.bookId,
  name: "Intro",
  rootType: _pageType,
  chapter: "",
  priority: 0,
);
final _otherPage = Page(
  pageId: skir.ResourceId(value: "other"),
  bookId: _otherBook.bookId,
  name: "Intro",
  rootType: _pageType,
  chapter: "",
  priority: 0,
);
