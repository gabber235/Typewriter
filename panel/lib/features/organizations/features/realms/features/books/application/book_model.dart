part of "books.dart";

@freezed
abstract class Book with _$Book {
  @Assert("title != \"\"", "Title must not be empty.")
  @Assert("icon != \"\"", "Icon must not be empty.")
  const factory Book({
    required skir.RecordId bookId,
    required int revision,
    required String title,
    required String icon,
    required Color color,
    required List<skir.RecordId> tagIds,
  }) = _Book;

  const Book._();

  factory Book.fromSkir(skir.Book book) => Book(
    bookId: book.bookId,
    revision: book.revision,
    title: book.title,
    icon: book.icon,
    color: book.color.toFlutterColor(),
    tagIds: book.tagIds.toList(),
  );

  skir.Book toSkir() => skir.Book(
    bookId: this.bookId,
    revision: revision,
    title: title,
    icon: icon,
    color: color.toSkirColor(),
    tagIds: tagIds,
  );
}

({List<Book> values, Book canonical}) _upsertCanonicalBook(
  List<Book>? values,
  Book incoming,
) {
  final current = values ?? const <Book>[];
  final existing = current.firstWhereOrNull(
    (book) => book.bookId == incoming.bookId,
  );
  if (existing != null && existing.revision >= incoming.revision) {
    if (existing.revision == incoming.revision && existing != incoming) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError(
            "Book ${incoming.bookId.id} has different values at revision ${incoming.revision}",
          ),
          library: "typewriter_panel",
          context: ErrorDescription("while reconciling a canonical Book"),
        ),
      );
    }
    return (values: current, canonical: existing);
  }
  return (
    values: current.upsertByKey((book) => book.bookId, incoming),
    canonical: incoming,
  );
}
