import "package:collection/collection.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

extension BookCommands on AuthoringSession {
  Future<wire.ApplyAuthoringBatchResponse> createBook(wire.Book book) =>
      apply([wire.AuthoringOperation.createCreateBook(book: book)]);

  Future<wire.ApplyAuthoringBatchResponse> patchBook(
    Book book, {
    required Book expected,
  }) {
    final before = expected;
    final operation = wire.AuthoringOperation.createPatchBook(
      id: book.bookId,
      title: before.title == book.title
          ? null
          : wire.StringChange(expected: before.title, value: book.title),
      icon: before.icon == book.icon
          ? null
          : wire.StringChange(expected: before.icon, value: book.icon),
      color: before.color == book.color
          ? null
          : wire.ColorChange(
              expected: before.color.toSkirColor(),
              value: book.color.toSkirColor(),
            ),
      tags:
          const ListEquality<skir.RecordId>().equals(before.tagIds, book.tagIds)
          ? null
          : wire.RecordIdListChange(
              expected: before.tagIds,
              value: book.tagIds,
            ),
    );
    return apply([operation]);
  }
}
