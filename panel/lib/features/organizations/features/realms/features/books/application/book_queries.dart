part of "books.dart";

@riverpod
Future<List<Book>> filteredBooks(Ref ref, String query) async {
  final books = await ref.watch(booksProvider.future);
  if (query.isEmpty) return books;
  final tags = await ref.watch(tagsProvider.future);
  final lowercaseQuery = query.toLowerCase();
  return books.where((book) {
    if (book.title.toLowerCase().contains(lowercaseQuery)) return true;
    return book.tagIds
        .map((tagId) => tags.firstWhereOrNull((tag) => tag.tagId == tagId))
        .nonNulls
        .any((tag) => tag.name.toLowerCase().contains(lowercaseQuery));
  }).toList();
}

@riverpod
skir.RecordId? bookId(Ref ref) {
  final id = ref.watch(routeParamProvider("bookId"));
  if (id == null) return null;
  return recordId("book:$id");
}

@riverpod
Future<Book?> book(Ref ref, skir.RecordId bookId) async {
  final books = await ref.watch(booksProvider.future);
  return books.firstWhereOrNull((book) => book.bookId == bookId);
}
