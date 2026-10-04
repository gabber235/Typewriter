part of "books.dart";

/// Immutable panel representation of a library book.
///
/// A book owns presentation metadata and direct tag references. [bookId] is
/// the stable authoring identity. The wire conversion preserves that identity,
/// while color conversion stays at this panel boundary. Unfinished authored
/// fields receive display values here without changing the authoring record.
@freezed
abstract class Book with _$Book {
  @Assert("title != \"\"", "Title must not be empty.")
  @Assert("icon != \"\"", "Icon must not be empty.")
  const factory Book({
    required skir.ResourceId bookId,
    required String title,
    required String icon,
    required Color color,
    required List<skir.ResourceId> tagIds,
  }) = _Book;

  const Book._();

  factory Book.fromAuthoring(skir.AuthoringResource resource) {
    final value = decodeAuthoredBook(resource);
    return Book(
      bookId: value.id,
      title: value.title,
      icon: value.icon,
      color: Color(value.argb),
      tagIds: value.tags,
    );
  }
}
