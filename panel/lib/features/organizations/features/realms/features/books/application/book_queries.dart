part of "books.dart";

/// Filters confirmed or locally projected books for the library search.
///
/// Title and resolved tag names are matched case insensitively. An empty query
/// avoids loading tags because every book is already a match. Loading and
/// failure states from either dependency are returned unchanged to the UI.
@riverpod
AsyncValue<List<Book>> filteredBooks(Ref ref, String query) {
  final books = ref.watch(projectedBooksProvider);
  if (books.mapUnready<List<Book>>() case final value?) return value;
  if (query.isEmpty) return AsyncData(books.requireValue);
  final tags = ref.watch(projectedTagsProvider);
  if (tags.mapUnready<List<Book>>() case final value?) return value;
  final lowercaseQuery = query.toLowerCase();
  return AsyncData(
    books.requireValue.where((book) {
      if (book.title.toLowerCase().contains(lowercaseQuery)) return true;
      return book.tagIds
          .map(
            (tagId) =>
                tags.requireValue.firstWhereOrNull((tag) => tag.tagId == tagId),
          )
          .nonNulls
          .any((tag) => tag.name.toLowerCase().contains(lowercaseQuery));
    }).toList(),
  );
}

/// Resolves the current route parameter into the typed book record identity.
@riverpod
skir.ResourceId? bookId(Ref ref) {
  final id = ref.watch(routeParamProvider("bookId"));
  if (id == null) return null;
  return skir.ResourceId(value: id);
}

/// Finds one confirmed book in the authoritative realm session.
@riverpod
Future<Book?> canonicalBook(Ref ref, skir.ResourceId bookId) async {
  final books = await ref.watch(canonicalBooksProvider.future);
  return books.firstWhereOrNull((book) => book.bookId == bookId);
}

@riverpod
AsyncValue<List<Book>> projectedBooks(Ref ref) =>
    ref.watch(canonicalBooksProvider);

@riverpod
AsyncValue<Book?> projectedBook(Ref ref, skir.ResourceId bookId) =>
    ref.watch(canonicalBookProvider(bookId));
