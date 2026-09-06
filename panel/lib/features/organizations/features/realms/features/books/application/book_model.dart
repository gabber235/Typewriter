part of "books.dart";

@freezed
abstract class Book with _$Book {
  @Assert("title != \"\"", "Title must not be empty.")
  @Assert("icon != \"\"", "Icon must not be empty.")
  const factory Book({
    required skir.RecordId bookId,
    required int authoringSequence,
    required String title,
    required String icon,
    required Color color,
    required List<skir.RecordId> tagIds,
  }) = _Book;

  const Book._();

  factory Book.fromWire(wire.Book book, int authoringSequence) => Book(
    bookId: book.id,
    authoringSequence: authoringSequence,
    title: book.title,
    icon: book.icon,
    color: book.color.toFlutterColor(),
    tagIds: book.tags.toList(),
  );

  wire.Book toWire() => wire.Book(
    id: this.bookId,
    title: title,
    icon: icon,
    color: color.toSkirColor(),
    tags: tagIds,
  );
}
