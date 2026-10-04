import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const authoringBookSelectorId = "book";
const authoringPageSelectorId = "page";
const authoringTagSelectorId = "tag";
const authoringTypeSelectorId = "type";

Book? resolveSearchBook(SearchQueryContext query, List<Book> books) {
  final value = _singleSelectorValue(query, authoringBookSelectorId);
  if (value == null) return null;
  return books
      .where((book) => book.title.toLowerCase() == value.toLowerCase())
      .singleOrNull;
}

bool hasSearchSelector(SearchQueryContext query, String selectorId) =>
    query.selectors.any((value) => value.selectorId == selectorId);

Page? resolveSearchPage(
  SearchQueryContext query,
  List<Book> books,
  List<Page> pages,
) {
  final value = _singleSelectorValue(query, authoringPageSelectorId);
  if (value == null) return null;
  final book = resolveSearchBook(query, books);
  return pages
      .where(
        (page) =>
            page.name.toLowerCase() == value.toLowerCase() &&
            (book == null || page.bookId == book.bookId),
      )
      .singleOrNull;
}

/// Prefers an explicit page selector over ambient route context.
Page? resolveElementCreationPage({
  required SearchQueryContext query,
  required List<Book> books,
  required List<Page> pages,
  required Page? currentPage,
}) {
  if (hasSearchSelector(query, authoringPageSelectorId)) {
    return resolveSearchPage(query, books, pages);
  }
  if (hasSearchSelector(query, authoringBookSelectorId)) {
    final selectedBook = resolveSearchBook(query, books);
    if (currentPage?.bookId != selectedBook?.bookId) return null;
  }
  return currentPage;
}

String? _singleSelectorValue(SearchQueryContext query, String selectorId) {
  final values = query.selectors
      .where((selector) => selector.selectorId == selectorId)
      .map((selector) => selector.value)
      .nonNulls
      .toSet();
  return values.singleOrNull;
}

String authoringBookInitialQuery(
  Book? book,
  Iterable<QuerySelectorDefinition> selectors,
) {
  if (book == null) return "";
  final selector = selectors
      .where((selector) => selector.id == authoringBookSelectorId)
      .whereType<KeyValueSelectorDefinition>()
      .singleOrNull;
  if (selector == null) return "";
  final value = book.title.contains(" ")
      ? "\"${book.title.replaceAll("\"", "")}\""
      : book.title;
  return "${selector.key}$value";
}
