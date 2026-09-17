import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

Book? resolveSearchBook(SearchQueryContext query, List<Book> books) {
  final value = _singleSelectorValue(query, authoringBookSearchSelector.id);
  if (value == null) return null;
  return books
      .where((book) => book.title.toLowerCase() == value.toLowerCase())
      .singleOrNull;
}

bool hasSearchSelector(
  SearchQueryContext query,
  QuerySelectorDefinition selector,
) => query.selectors.any((value) => value.selectorId == selector.id);

Page? resolveSearchPage(
  SearchQueryContext query,
  List<Book> books,
  List<Page> pages,
) {
  final value = _singleSelectorValue(query, authoringPageSearchSelector.id);
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
  if (hasSearchSelector(query, authoringPageSearchSelector)) {
    return resolveSearchPage(query, books, pages);
  }
  if (hasSearchSelector(query, authoringBookSearchSelector)) {
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

String authoringBookInitialQuery(Book? book) {
  if (book == null) return "";
  final value = book.title.contains(" ")
      ? "\"${book.title.replaceAll("\"", "")}\""
      : book.title;
  return "${authoringBookSearchSelector.key}$value";
}

SearchScope primarySearchScope({
  required ValueListenable<AsyncValue<List<Book>>> books,
  required ValueListenable<AsyncValue<List<Page>>> pages,
  required ValueListenable<
    AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
  >
  pagePolicies,
  required ValueListenable<AsyncValue<RealmEditorCatalogState>> catalog,
}) => PredicateSearchScope(
  dependencies: [books, pages, pagePolicies, catalog],
  evaluate: (result, query) {
    if (result.payload case RealmPageDefinition()) {
      final values = books.value.value;
      return values != null && resolveSearchBook(query, values) != null
          ? const SearchResultVisibility.visible()
          : const SearchResultVisibility.hidden();
    }
    if (result.payload case ElementDefinition(:final rootType)) {
      if (hasSearchSelector(query, authoringPageSearchSelector)) {
        final bookValues = books.value.value;
        final pageValues = pages.value.value;
        final policies = pagePolicies.value.value;
        if (bookValues == null || pageValues == null || policies == null) {
          return const SearchResultVisibility.hidden();
        }
        final page = resolveSearchPage(query, bookValues, pageValues);
        if (page == null || policies[page.kind]?.accepts(rootType) != true) {
          return const SearchResultVisibility.hidden();
        }
      }

      if (hasSearchSelector(query, authoringTypeSearchSelector)) {
        final snapshot = catalog.value.value?.snapshot;
        if (snapshot == null) return const SearchResultVisibility.hidden();
        final definitions = snapshot.elements.values
            .where((entry) => entry.eligible && entry.available)
            .map((entry) => entry.definition.toElementDefinition())
            .toList(growable: false);
        if (!_matchesTypeSelectors(
          query,
          rootType,
          definitions,
          TypeRegistry(snapshot.catalog),
        )) {
          return const SearchResultVisibility.hidden();
        }
      }

      return const SearchResultVisibility.visible();
    }
    return const SearchResultVisibility.visible();
  },
);

bool _matchesTypeSelectors(
  SearchQueryContext query,
  ResolvedTypeRef candidate,
  List<ElementDefinition> definitions,
  TypeRegistry registry,
) {
  final selected = query.selectors
      .where(
        (selector) => selector.selectorId == authoringTypeSearchSelector.id,
      )
      .map((selector) => selector.value)
      .nonNulls
      .map((value) => _resolveElementType(value, definitions))
      .toList(growable: false);
  if (selected.isEmpty || selected.any((definition) => definition == null)) {
    return false;
  }
  final resolved = registry.resolveExact(candidate).valueOrNull;
  if (resolved == null) return false;
  return selected.every(
    (definition) =>
        candidate == definition!.rootType ||
        resolved.ancestors.contains(definition.rootType),
  );
}

ElementDefinition? _resolveElementType(
  String value,
  List<ElementDefinition> definitions,
) {
  final normalized = value.trim().toLowerCase();
  return definitions
      .where(
        (definition) =>
            definition.typeId.uuid.toLowerCase() == normalized ||
            definition.name.toLowerCase() == normalized ||
            definition.qualifiedName.toLowerCase() == normalized,
      )
      .singleOrNull;
}

/// Restricts an element type picker to definitions accepted by one live page.
///
/// Unavailable policy state exposes no definitions. The source remains the
/// owner of loading and catalog failures, while the command revalidates the
/// policy immediately before mutation.
SearchScope pageElementTypeScope({
  required ValueListenable<AsyncValue<PageEntryCreationPolicy>> policy,
}) => PredicateSearchScope(
  dependencies: [policy],
  evaluate: (result, query) {
    final current = policy.value.value;
    return switch (result.payload) {
      ElementDefinition(:final rootType)
          when current?.accepts(rootType) == true =>
        const SearchResultVisibility.visible(),
      _ => const SearchResultVisibility.hidden(),
    };
  },
);

SearchScope elementDestinationScope({
  required ValueListenable<AsyncValue<List<Book>>> books,
  required ValueListenable<
    AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
  >
  compatibleKinds,
}) => PredicateSearchScope(
  dependencies: [books, compatibleKinds],
  evaluate: (result, query) {
    final policies = compatibleKinds.value.value;
    if (policies == null) return const SearchResultVisibility.hidden();
    return switch (result.payload) {
      skir.AuthoringSearchPage(:final kind) =>
        policies.containsKey(PageKindRef.fromSkir(kind))
            ? const SearchResultVisibility.visible()
            : const SearchResultVisibility.hidden(),
      RealmPageDefinition(:final kind) =>
        policies.containsKey(kind) &&
                books.value.value != null &&
                resolveSearchBook(query, books.value.requireValue) != null
            ? const SearchResultVisibility.visible()
            : const SearchResultVisibility.hidden(),
      _ => const SearchResultVisibility.hidden(),
    };
  },
);
