import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "books.freezed.dart";
part "books.g.dart";
part "book_queries.dart";
part "book_selection.dart";
part "book_validation.dart";

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

  factory Book.fromSkir(skir.Book book) => Book(
    bookId: book.bookId,
    title: book.title,
    icon: book.icon,
    color: book.color.toFlutterColor(),
    tagIds: book.tagIds.toList(),
  );

  skir.Book toSkir() => skir.Book(
    bookId: this.bookId,
    title: title,
    icon: icon,
    color: color.toSkirColor(),
    tagIds: tagIds,
  );
}

@riverpod
class Books extends _$Books {
  @override
  Stream<List<Book>> build() async* {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (realmId == null || organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchBooksRequest();
    yield* ref.watchRequest(
      subject:
          "service.to.${realmId.id}.organization.${organizationId.id}.realm.book.watch",
      listenSubject:
          "service.from.${realmId.id}.organization.${organizationId.id}.realm.book.watch",
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
            return previous.upsertByKey(
              (book) => book.bookId,
              Book.fromSkir(value),
            );
          case skir.WatchBooksResponse_updateWrapper(:final value):
            return previous.upsertByKey(
              (book) => book.bookId,
              Book.fromSkir(value),
            );
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

    final request = skir.CreateBookRequest(
      title: title,
      icon: icon,
      color: color?.toSkirColor(),
      tagIds: tagIds,
    );

    try {
      final response = await ref.requestSkir(
        "service.to.${realmId.id}.organization.${organizationId.id}.realm.book.create",
        skir.CreateBookRequest.serializer.toBytes(request),
        skir.CreateBookResponse.serializer,
      );
      switch (response) {
        case skir.CreateBookResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.CreateBookResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.CreateBookResponse_validationErrorWrapper(:final value):
          throw value.toApiException();
        case skir.CreateBookResponse_tagsNotFoundErrorWrapper():
          throw ApiException.notFound("Tags");
        case skir.CreateBookResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
        case skir.CreateBookResponse_successWrapper(:final value):
          final book = Book.fromSkir(value);
          state = AsyncData(
            state.requireValue.upsertByKey((book) => book.bookId, book),
          );
          return book;
      }
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateBook(Book book) async {
    state.ensureReady();
    final previousState = state;
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    state = AsyncData(
      state.requireValue.upsertByKey((value) => value.bookId, book),
    );
    final request = skir.UpdateBookRequest(
      bookId: book.bookId,
      title: book.title,
      icon: book.icon,
      color: book.color.toSkirColor(),
      tagIds: book.tagIds,
    );

    try {
      final response = await ref.requestSkir(
        "service.to.${realmId.id}.organization.${organizationId.id}.realm.book.update",
        skir.UpdateBookRequest.serializer.toBytes(request),
        skir.UpdateBookResponse.serializer,
      );
      switch (response) {
        case skir.UpdateBookResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.UpdateBookResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.UpdateBookResponse_bookNotFoundErrorWrapper():
          throw ApiException.notFound("Book");
        case skir.UpdateBookResponse_tagsNotFoundErrorWrapper():
          throw ApiException.notFound("Tags");
        case skir.UpdateBookResponse_validationErrorWrapper(:final value):
          throw value.toApiException();
        case skir.UpdateBookResponse_invalidRecordIdErrorWrapper(:final value):
          throw ApiException.invalidRecordId(value);
        case skir.UpdateBookResponse_successWrapper(:final value):
          final updatedBook = Book.fromSkir(value);
          state = AsyncData(
            state.requireValue.upsertByKey((book) => book.bookId, updatedBook),
          );
      }
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<skir.RecordId> createPage(
    skir.RecordId bookId,
    String name,
    skir.PageType type,
    String chapter,
    int priority,
  ) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.CreatePageRequest(
      bookId: bookId,
      name: name,
      type: type,
      chapter: chapter,
      priority: priority,
    );
    final response = await ref.requestSkir(
      "service.to.${realmId.id}.organization.${organizationId.id}.realm.page.create",
      skir.CreatePageRequest.serializer.toBytes(request),
      skir.CreatePageResponse.serializer,
    );

    return switch (response) {
      skir.CreatePageResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.CreatePageResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.CreatePageResponse_bookNotFoundErrorWrapper() =>
        throw ApiException.notFound("Book"),
      skir.CreatePageResponse_validationErrorWrapper(:final value) =>
        throw value.toApiException(),
      skir.CreatePageResponse_invalidRecordIdErrorWrapper(:final value) =>
        throw ApiException.invalidRecordId(value),
      skir.CreatePageResponse_successWrapper(:final value) => value.pageId,
    };
  }

  Future<void> deletePage(skir.RecordId pageId) async {
    state.ensureReady();
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    if (organizationId == null) throw ApiException.noOrganization();

    final request = skir.DeletePageRequest(pageId: pageId);
    final response = await ref.requestSkir(
      "service.to.${realmId.id}.organization.${organizationId.id}.realm.page.delete",
      skir.DeletePageRequest.serializer.toBytes(request),
      skir.DeletePageResponse.serializer,
    );
    switch (response) {
      case skir.DeletePageResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.DeletePageResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.DeletePageResponse_pageNotFoundErrorWrapper():
        throw ApiException.notFound("Page");
      case skir.DeletePageResponse_invalidRecordIdErrorWrapper(:final value):
        throw ApiException.invalidRecordId(value);
      case skir.DeletePageResponse_successWrapper():
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

    final request = skir.ChangePagesChaptersRequest(
      bookId: bookId,
      oldChapter: oldChapter,
      newChapter: newChapter,
    );
    final response = await ref.requestSkir(
      "service.to.${realmId.id}.organization.${organizationId.id}.realm.pages.chapters",
      skir.ChangePagesChaptersRequest.serializer.toBytes(request),
      skir.ChangePagesChaptersResponse.serializer,
    );
    switch (response) {
      case skir.ChangePagesChaptersResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.ChangePagesChaptersResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.ChangePagesChaptersResponse_bookNotFoundErrorWrapper():
        throw ApiException.notFound("Book");
      case skir.ChangePagesChaptersResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.ChangePagesChaptersResponse_successWrapper():
    }
  }
}
