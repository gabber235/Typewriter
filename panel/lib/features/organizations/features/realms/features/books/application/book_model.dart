part of "books.dart";

/// Immutable panel representation of a library book.
///
/// A book owns presentation metadata and direct tag references. [bookId] is
/// the stable authoring identity. The wire conversion preserves that identity,
/// while color conversion stays at this panel boundary. The title and icon
/// assertions protect values created inside the panel; wire input is still
/// decoded through [fromWire] and can be rejected later by editor decoding.
@freezed
abstract class Book with _$Book {
  @Assert("title != \"\"", "Title must not be empty.")
  @Assert("icon != \"\"", "Icon must not be empty.")
  const factory Book({
    required skir.RecordId bookId,
    required String title,
    required String icon,
    required Color color,
    required List<skir.RecordId> tagIds,
  }) = _Book;

  const Book._();

  /// Converts the authoring contract into the value used by providers and UI.
  factory Book.fromWire(skir.Book book) => Book(
    bookId: book.id,
    title: book.title,
    icon: book.icon,
    color: book.color.toFlutterColor(),
    tagIds: book.tags.toList(),
  );

  /// Converts this immutable value into the authoring operation payload.
  skir.Book toWire() => skir.Book(
    id: this.bookId,
    title: title,
    icon: icon,
    color: color.toSkirColor(),
    tags: tagIds,
  );
}
