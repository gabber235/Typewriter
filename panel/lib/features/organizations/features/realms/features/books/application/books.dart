import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/book.dart"
    as wire_v1;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v2/authoring.dart"
    as wire_v2;
import "package:typewriter_panel/typewriter_panel.dart";

part "book_model.dart";
part "book_queries.dart";
part "book_selection.dart";
part "books.freezed.dart";
part "books.g.dart";

@riverpod
class Books extends _$Books {
  @override
  Stream<List<Book>> build() async* {
    ref.watch(libraryInvalidationsProvider(skir.LibraryResourceKind.book));
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null || organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchBooksRequest();
    final address = RealmServiceAddress(
      organizationId: organizationId,
      realmId: realmId,
    );
    yield* ref.watchRequest(
      subject: address.request("book.watch"),
      listenSubject: address.event("book.watch"),
      requestBytes: skir.WatchBooksRequest.serializer.toBytes(request),
      serializer: skir.WatchBooksResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchBooksResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchBooksResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchBooksResponse_listWrapper(:final value):
            return value.map(Book.fromSkir).toList();
          case skir.WatchBooksResponse_addWrapper(:final value):
            return _upsertCanonicalBook(previous, Book.fromSkir(value)).values;
          case skir.WatchBooksResponse_updateWrapper(:final value):
            return _upsertCanonicalBook(previous, Book.fromSkir(value)).values;
          case skir.WatchBooksResponse_removeWrapper(:final value):
            return previous?.where((book) => book.bookId != value).toList() ??
                [];
        }
      },
    );
  }

  Future<Book> createBook({
    required String title,
    String? icon,
    Color? color,
    List<skir.RecordId> tagIds = const [],
  }) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.CreateBooksRequest(
      batchId: uuid.v4(),
      books: [
        skir.BookCreate(
          id: recordId("book:${uuid.v4()}"),
          title: title,
          icon: icon ?? "mdi:book",
          color: (color ?? Colors.grey).toSkirColor(),
          tags: tagIds,
        ),
      ],
    );

    try {
      final response = await ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("book.create.v2"),
        skir.CreateBooksRequest.serializer.toBytes(request),
        skir.CreateBooksResponse.serializer,
      );
      switch (response) {
        case skir.CreateBooksResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.CreateBooksResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.CreateBooksResponse_conflictWrapper():
          throw ApiException.conflict("The book already exists");
        case skir.CreateBooksResponse_invalidWrapper(:final value):
          throw ApiException.badRequest(value.join("; "));
        case skir.CreateBooksResponse_successWrapper(:final value):
          final book = Book.fromV2(value.single);
          final upsert = _upsertCanonicalBook(state.requireValue, book);
          state = AsyncData(upsert.values);
          return upsert.canonical;
      }
    } on Object catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<TypedMutationResult> updateBook(Book book) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.UpdateBooksRequest(
      batchId: uuid.v4(),
      books: [
        skir.BookUpdate(
          id: book.bookId,
          expectedRevision: book.revision,
          title: book.title,
          icon: book.icon,
          color: book.color.toSkirColor(),
          tags: book.tagIds,
        ),
      ],
    );

    try {
      final response = await ref.requestSkir(
        RealmServiceAddress(
          organizationId: organizationId,
          realmId: realmId,
        ).request("book.update.v2"),
        skir.UpdateBooksRequest.serializer.toBytes(request),
        skir.UpdateBooksResponse.serializer,
      );
      switch (response) {
        case skir.UpdateBooksResponse_unknown():
          return unavailableMutation("The server returned an unknown response");
        case skir.UpdateBooksResponse_internalErrorWrapper():
          return unavailableMutation("The server could not update the book");
        case skir.UpdateBooksResponse_conflictWrapper(:final value):
          final actual = value.single.actual;
          if (actual == null) {
            return unavailableMutation(
              "The book no longer exists",
              targetDeleted: true,
            );
          }
          final actualBook = Book.fromV2(actual);
          final upsert = _upsertCanonicalBook(state.requireValue, actualBook);
          state = AsyncData(upsert.values);
          return TypedMutationResult.conflict(
            expectedRevision: book.revision,
            actualRevision: actualBook.revision,
            actualValue: actualBook.inspectorValue,
          );
        case skir.UpdateBooksResponse_invalidWrapper(:final value):
          return invalidMutation(value.join("; "));
        case skir.UpdateBooksResponse_successWrapper(:final value):
          final updatedBook = Book.fromV2(value.single);
          final upsert = _upsertCanonicalBook(state.requireValue, updatedBook);
          state = AsyncData(upsert.values);
          return TypedMutationResult.success(
            revision: upsert.canonical.revision,
            value: upsert.canonical.inspectorValue,
          );
      }
    } on Object catch (_) {
      return unavailableMutation("The book update could not be completed");
    }
  }

  Future<skir.RecordId> createPage(
    skir.RecordId bookId,
    String name,
    PageKindRef kind,
    String chapter,
    int priority,
  ) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final pageId = recordId("page:${uuid.v4()}");
    final request = skir.CreatePagesRequest(
      batchId: uuid.v4(),
      pages: [
        skir.PageCreate(
          id: pageId,
          book: bookId,
          name: name,
          kind: kind.toSkir(),
          chapter: chapter,
          priority: priority,
        ),
      ],
    );
    final response = await ref.requestSkir(
      RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      ).request("page.create.v2"),
      skir.CreatePagesRequest.serializer.toBytes(request),
      skir.CreatePagesResponse.serializer,
    );

    return switch (response) {
      skir.CreatePagesResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.CreatePagesResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.CreatePagesResponse_conflictWrapper() => throw ApiException.conflict(
        "The page already exists",
      ),
      skir.CreatePagesResponse_invalidWrapper(:final value) =>
        throw ApiException.badRequest(value.join("; ")),
      skir.CreatePagesResponse_successWrapper() => pageId,
    };
  }

  Future<void> deletePage(skir.RecordId pageId) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final page = await ref.read(pagesProvider(pageId).future);
    final request = skir.DeletePagesRequest(
      batchId: uuid.v4(),
      pages: [skir.PageDeletion(id: pageId, expectedRevision: page.revision)],
    );
    final response = await ref.requestSkir(
      RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      ).request("page.delete.v2"),
      skir.DeletePagesRequest.serializer.toBytes(request),
      skir.DeletePagesResponse.serializer,
    );
    switch (response) {
      case skir.DeletePagesResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.DeletePagesResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.DeletePagesResponse_conflictWrapper():
        throw ApiException.conflict("The page changed before deletion");
      case skir.DeletePagesResponse_invalidWrapper(:final value):
        throw ApiException.badRequest(value.join("; "));
      case skir.DeletePagesResponse_successWrapper():
    }
  }

  Future<void> changePagesChapters(
    skir.RecordId bookId,
    String oldChapter,
    String newChapter,
  ) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final pages = await ref.read(bookPagesProvider(bookId, "").future);
    final changed = pages.where(
      (page) =>
          page.chapter == oldChapter || page.chapter.startsWith("$oldChapter."),
    );
    if (changed.isEmpty) return;
    String replacement(String chapter) {
      final suffix = chapter.substring(oldChapter.length);
      if (newChapter.isEmpty && suffix.startsWith(".")) {
        return suffix.substring(1);
      }
      return "$newChapter$suffix";
    }

    final request = skir.UpdatePagesRequest(
      batchId: uuid.v4(),
      pages: [
        for (final page in changed)
          skir.PageUpdate(
            id: page.pageId,
            expectedRevision: page.revision,
            name: page.name,
            chapter: replacement(page.chapter),
            priority: page.priority,
          ),
      ],
    );
    final response = await ref.requestSkir(
      RealmServiceAddress(
        organizationId: organizationId,
        realmId: realmId,
      ).request("page.update.v2"),
      skir.UpdatePagesRequest.serializer.toBytes(request),
      skir.UpdatePagesResponse.serializer,
    );
    switch (response) {
      case skir.UpdatePagesResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.UpdatePagesResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.UpdatePagesResponse_conflictWrapper():
        throw ApiException.conflict(
          "A page changed while chapters were moving",
        );
      case skir.UpdatePagesResponse_invalidWrapper(:final value):
        throw ApiException.badRequest(value.join("; "));
      case skir.UpdatePagesResponse_successWrapper():
    }
  }
}
