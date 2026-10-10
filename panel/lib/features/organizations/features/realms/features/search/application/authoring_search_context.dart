import "package:typewriter_panel/typewriter_panel.dart";

const authoringBookSelectorId = "book";
const authoringPageSelectorId = "page";
const authoringTagSelectorId = "tag";
const authoringTypeSelectorId = "type";

extension AuthoringQueryOperations on SearchQueryContext {
  bool hasSelector(String selectorId) =>
      selectors.any((selector) => selector.selectorId == selectorId);

  Book? resolveBook(List<Book> books) {
    final value = _singleSelectorValue(authoringBookSelectorId);
    if (value == null) return null;
    return books
        .where((book) => book.title.toLowerCase() == value.toLowerCase())
        .singleOrNull;
  }

  Page? resolvePage(List<Book> books, List<Page> pages) {
    final value = _singleSelectorValue(authoringPageSelectorId);
    if (value == null) return null;
    final book = resolveBook(books);
    if (hasSelector(authoringBookSelectorId) && book == null) return null;
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
    required List<Book> books,
    required List<Page> pages,
    required Page? currentPage,
  }) {
    if (hasSelector(authoringPageSelectorId)) {
      return resolvePage(books, pages);
    }
    if (hasSelector(authoringBookSelectorId)) {
      final selectedBook = resolveBook(books);
      if (currentPage?.bookId != selectedBook?.bookId) return null;
    }
    return currentPage;
  }

  String? _singleSelectorValue(String selectorId) => selectors
      .where((selector) => selector.selectorId == selectorId)
      .map((selector) => selector.value)
      .nonNulls
      .toSet()
      .singleOrNull;
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
