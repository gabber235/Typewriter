import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
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

/// Restricts an element type picker to definitions accepted by one live page.
///
/// Unavailable policy state exposes no definitions. The source remains the
/// owner of loading and catalog failures, while the command revalidates the
/// policy immediately before mutation.
SearchScope pageCreationSlotScope({
  required ValueListenable<AsyncValue<RealmAuthoringCreationSlot>> slot,
}) => PredicateSearchScope(
  dependencies: [slot],
  evaluate: (result, query) {
    final current = slot.value.value;
    return switch (result.payload) {
      ElementDefinition(:final rootType)
          when current?.acceptsRoot(rootType) == true =>
        const SearchResultVisibility.visible(),
      _ => const SearchResultVisibility.hidden(),
    };
  },
);

SearchScope elementDestinationScope({
  required ValueListenable<AsyncValue<List<Book>>> books,
  required ValueListenable<
    AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>
  >
  compatibleKinds,
}) => PredicateSearchScope(
  dependencies: [books, compatibleKinds],
  evaluate: (result, query) {
    final slots = compatibleKinds.value.value;
    if (slots == null) return const SearchResultVisibility.hidden();
    return switch (result.payload) {
      AuthoringSearchResultPayload(:final pageKind) when pageKind != null =>
        slots.containsKey(pageKind)
            ? const SearchResultVisibility.visible()
            : const SearchResultVisibility.hidden(),
      RealmPageDefinition(:final kind) =>
        slots.containsKey(kind) &&
                books.value.value != null &&
                resolveSearchBook(query, books.value.requireValue) != null
            ? const SearchResultVisibility.visible()
            : const SearchResultVisibility.hidden(),
      _ => const SearchResultVisibility.hidden(),
    };
  },
);
