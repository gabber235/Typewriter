import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "book_model.dart";
part "book_queries.dart";
part "book_selection.dart";
part "books.freezed.dart";
part "books.g.dart";

/// Owns the confirmed book collection for the selected organization and realm.
///
/// The realm authoring session remains the source of truth. This provider waits
/// for the registered book selection to become ready, then projects records into
/// immutable [Book] values and listens for later session sequences. Consumers
/// that render or edit immediately should choose [projectedBooksProvider] or
/// [projectedBookProvider] when local editor values must be visible.
@riverpod
class CanonicalBooks extends _$CanonicalBooks {
  @override
  Future<List<Book>> build() async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return [];
    }

    final provider = authoringSessionProvider(organizationId, realmId);
    var session = ref.watch(provider);
    if (session.failure case final failure?) {
      throw StateError("Authoring is unavailable: $failure");
    }
    if (session.snapshot == null) {
      await ref.read(provider.notifier).ready;
      session = ref.read(provider);
      if (session.failure case final failure?) {
        throw StateError("Authoring is unavailable: $failure");
      }
    }
    return _projectBooks(session);
  }

  Future<void> updateBook(Book book, {Book? expected}) async {
    state.ensureReady();
    final before =
        expected ??
        state.requireValue.singleWhere(
          (candidate) => candidate.bookId == book.bookId,
          orElse: () => throw ApiException.notFound("Book"),
        );
    final access = ref.readAuthoringSession();
    final source = access.state.resources[book.bookId];
    final baseline = access.state.draft;
    if (source == null || baseline == null) {
      throw ApiException.notFound("Book");
    }
    if (Book.fromAuthoring(source) != before) {
      throw ApiException.conflict("The Book changed before this edit");
    }
    final draft = baseline.fork();
    if (book.title != before.title) {
      setAuthoredFieldPayload(
        draft: draft,
        resource: book.bookId,
        fields: const ["title"],
        payload: skir.DataValue.wrapStringValue(book.title),
      );
    }
    if (book.icon != before.icon) {
      final icon = source.content.authoredField("icon");
      final field = icon?.authoredField("value") != null
          ? "value"
          : icon?.authoredField("source") != null
          ? "source"
          : null;
      if (field == null) {
        throw StateError("The Book icon is unavailable");
      }
      setAuthoredFieldPayload(
        draft: draft,
        resource: book.bookId,
        fields: ["icon", field],
        payload: skir.DataValue.wrapStringValue(book.icon),
      );
    }
    if (book.color != before.color) {
      setAuthoredFieldPayload(
        draft: draft,
        resource: book.bookId,
        fields: const ["color"],
        payload: skir.DataValue.wrapInteger(
          book.color.toARGB32().toUnsigned(32).toString(),
        ),
      );
    }
    if (!const ListEquality<skir.ResourceId>().equals(
      book.tagIds,
      before.tagIds,
    )) {
      replacePortableLinkCollection(
        draft: AuthoredDraftAuthoringDocument(draft),
        catalog: access.state.catalog!,
        resource: book.bookId,
        field: "tags",
        expected: before.tagIds,
        proposed: book.tagIds,
      );
    }
    await access.notifier.commitDraft(
      draft,
      conflictMessage: "The Book changed before this edit was saved",
    );
  }
}

List<Book> _projectBooks(AuthoringSessionState value) {
  return value.resources.values
      .where((resource) => resource.definition == _bookDefinition)
      .map(Book.fromAuthoring)
      .toList();
}

final _bookDefinition = skir.ResourceDefinitionId(value: "typewriter.book");
