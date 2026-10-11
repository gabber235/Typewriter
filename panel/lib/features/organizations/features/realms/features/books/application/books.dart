import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "book_model.dart";
part "book_queries.dart";
part "books.freezed.dart";
part "books.g.dart";

/// Typed book views of the shared working document.
@riverpod
AsyncValue<List<Book>> workingBooks(Ref ref) {
  final source = ref.watch(selectedWorkingAuthoringDocumentProvider);
  if (source.mapUnready<List<Book>>() case final pending?) return pending;
  return AsyncData(
    source.requireValue.entries.values
        .where((entry) => entry.definition == coreBookResourceDefinition)
        .map(Book.fromAuthoring)
        .toList(growable: false),
  );
}

@riverpod
AsyncValue<Book?> workingBook(Ref ref, skir.ResourceId bookId) {
  final source = ref.watch(workingBooksProvider);
  if (source.mapUnready<Book?>() case final pending?) return pending;
  return AsyncData(
    source.requireValue.firstWhereOrNull((book) => book.bookId == bookId),
  );
}
