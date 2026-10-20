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

  /// The title, color and icon come from the Book's [appearance], so a Book
  /// reads the same here as on every other surface.
  factory Book.fromAuthoring(
    skir.AuthoringResource resource,
    ResourceAppearance appearance,
  ) {
    final content = resource.content;
    final tags =
        content.authoredField("tags")?.authoredItems ?? const <skir.ListItem>[];
    return Book(
      bookId: resource.id,
      title: appearance.label,
      icon: switch (appearance.icon) {
        skir.Icon_iconifyWrapper(:final value) => value,
        skir.Icon_svgWrapper(:final value) => value,
        _ => "material-symbols:book",
      },
      color: appearance.accent,
      tagIds: tags
          .map((item) => item.value.authoredLink?.target.resource)
          .nonNulls
          .toList(growable: false),
    );
  }
}
