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
    final content = resource.content;
    final iconValue = content.authoredField("icon");
    final icon =
        iconValue?.authoredField("value")?.authoredString ??
        iconValue?.authoredField("source")?.authoredString;
    final color = content.authoredField("color")?.authoredInteger;
    final tags =
        content.authoredField("tags")?.authoredItems ?? const <skir.ListItem>[];
    return Book(
      bookId: resource.id,
      title: (content.authoredField("title")?.authoredString).displayLabel(
        "Unnamed Book",
      ),
      icon: icon.displayLabel("material-symbols:book"),
      color: Color((color ?? BigInt.from(0xff3f51b5)).toUnsigned(32).toInt()),
      tagIds: tags
          .map((item) => item.value.authoredLink?.target.resource)
          .nonNulls
          .toList(growable: false),
    );
  }
}
