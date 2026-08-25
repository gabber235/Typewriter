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

  factory Book.fromSkir(wire_v1.Book book) => Book(
    bookId: book.bookId,
    revision: book.revision,
    title: book.title,
    icon: book.icon,
    color: book.color.toFlutterColor(),
    tagIds: book.tagIds.toList(),
  );

  factory Book.fromV2(wire_v2.Book book) => Book(
    bookId: book.id,
    revision: book.revision,
    title: book.title,
    icon: book.icon,
    color: book.color.toFlutterColor(),
    tagIds: book.tags.toList(),
  );

  wire_v1.Book toSkir() => wire_v1.Book(
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
) => reconcileCanonicalRevision(
  values: values,
  incoming: incoming,
  keyOf: (book) => book.bookId,
  revisionOf: (book) => book.revision,
  identityOf: (book) => "Book ${book.bookId.id}",
  entityName: "Book",
);
