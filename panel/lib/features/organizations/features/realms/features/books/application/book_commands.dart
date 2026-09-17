import "package:collection/collection.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Book mutations expressed in the shared authoring session boundary.
///
/// These methods do not update local state directly. The session submits the
/// wire operation, validates its application, and later publishes the
/// confirmed resource change to its listeners.
extension BookCommands on AuthoringSession {
  Future<skir.ApplyAuthoringBatchResponse> createBook(skir.Book book) =>
      apply([skir.AuthoringOperation.createCreateBook(book: book)]);

  Future<skir.ApplyAuthoringBatchResponse> patchBook(
    Book book, {
    required Book expected,
  }) {
    return apply([bookPatchOperation(book, expected: expected)]);
  }
}

/// Builds a conditional patch containing only fields changed from [expected].
///
/// Null patch fields mean no requested change. Non null fields carry the
/// expected old value, allowing the authoring boundary to detect stale editor
/// state and reject the write instead of overwriting a concurrent update.
skir.AuthoringOperation bookPatchOperation(
  Book book, {
  required Book expected,
}) {
  final before = expected;
  return skir.AuthoringOperation.createPatchBook(
    id: book.bookId,
    title: before.title == book.title
        ? null
        : skir.StringChange(expected: before.title, value: book.title),
    icon: before.icon == book.icon
        ? null
        : skir.StringChange(expected: before.icon, value: book.icon),
    color: before.color == book.color
        ? null
        : skir.ColorChange(
            expected: before.color.toSkirColor(),
            value: book.color.toSkirColor(),
          ),
    tags: const ListEquality<skir.RecordId>().equals(before.tagIds, book.tagIds)
        ? null
        : skir.RecordIdListChange(expected: before.tagIds, value: book.tagIds),
  );
}
