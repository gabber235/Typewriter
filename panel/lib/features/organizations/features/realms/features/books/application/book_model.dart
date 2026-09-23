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
    required skir.ResourceId bookId,
    required String title,
    required String icon,
    required Color color,
    required List<skir.ResourceId> tagIds,
  }) = _Book;

  const Book._();

  factory Book.fromTyped(TypedAuthoringResource resource) {
    final value = resource.content.rootValue;
    final provisional = Book(
      bookId: resource.id,
      title: "_",
      icon: "_",
      color: Colors.black,
      tagIds: const [],
    );
    final decoded = provisional.withInspectorValue(value);
    if (decoded == null) throw StateError("The Book content is invalid");
    return decoded;
  }
}
