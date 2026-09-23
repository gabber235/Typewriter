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

/// Overlays local editor values on the confirmed book collection.
///
/// The authoring session remains canonical. Local values belong to the
/// resource key for the current organization and realm. An invalid projection
/// is ignored, leaving the confirmed value visible to this view.
@riverpod
AsyncValue<List<Book>> projectedBooks(Ref ref) {
  final canonical = ref.watch(canonicalBooksProvider);
  if (canonical.mapUnready<List<Book>>() case final value?) return value;
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) {
    return AsyncData(canonical.requireValue);
  }
  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues),
  );
  return AsyncData([
    for (final book in canonical.requireValue)
      book.projected(
        local[EditorResourceKey(
          scope: EditorResourceScope(
            organizationId: organizationId,
            realmId: realmId,
          ),
          identity: book.bookId,
        )],
      ),
  ]);
}

/// Returns one book with its local editor projection, if present.
///
/// This is the read model for consumers that need edits before confirmation.
/// It retains the canonical loading or missing value state until the local
/// overlay can be applied.
@riverpod
AsyncValue<Book?> projectedBook(Ref ref, skir.ResourceId bookId) {
  final canonical = ref.watch(canonicalBookProvider(bookId));
  if (canonical.mapUnready<Book?>() case final value?) return value;
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) return canonical;
  final key = EditorResourceKey(
    scope: EditorResourceScope(
      organizationId: organizationId,
      realmId: realmId,
    ),
    identity: bookId,
  );
  final local = ref.watch(
    localWorkProvider.select((state) => state.editorValues[key]),
  );
  return AsyncData(canonical.requireValue?.projected(local));
}
