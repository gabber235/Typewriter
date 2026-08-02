import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "books.freezed.dart";
part "books.g.dart";

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
          "realm.to.${realmId.id}.organization.${organizationId.id}.book.watch",
      listenSubject:
          "realm.from.${realmId.id}.organization.${organizationId.id}.book.watch",
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
        "realm.to.${realmId.id}.organization.${organizationId.id}.book.create",
        skir.CreateBookRequest.serializer.toBytes(request),
        skir.CreateBookResponse.serializer,
      );
      switch (response) {
        case skir.CreateBookResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.CreateBookResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.CreateBookResponse_validationErrorWrapper(:final value):
          throw _bookValidationException(value);
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
        "realm.to.${realmId.id}.organization.${organizationId.id}.book.update",
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
          throw _bookValidationException(value);
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
      "realm.to.${realmId.id}.organization.${organizationId.id}.page.create",
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
        throw _pageValidationException(value),
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
      "realm.to.${realmId.id}.organization.${organizationId.id}.page.delete",
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
      "realm.to.${realmId.id}.organization.${organizationId.id}.pages.chapters",
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

@riverpod
Future<List<Book>> filteredBooks(Ref ref, String query) async {
  final books = await ref.watch(booksProvider.future);
  if (query.isEmpty) return books;
  final tags = await ref.watch(tagsProvider.future);
  final lowercaseQuery = query.toLowerCase();
  return books.where((book) {
    if (book.title.toLowerCase().contains(lowercaseQuery)) return true;
    return book.tagIds
        .map((tagId) => tags.firstWhereOrNull((tag) => tag.tagId == tagId))
        .nonNulls
        .any((tag) => tag.name.toLowerCase().contains(lowercaseQuery));
  }).toList();
}

@riverpod
skir.RecordId? bookId(Ref ref) {
  final id = ref.watch(routeParamProvider("bookId"));
  if (id == null) return null;
  return recordId("book:$id");
}

@riverpod
Future<Book?> book(Ref ref, skir.RecordId bookId) async {
  final books = await ref.watch(booksProvider.future);
  return books.firstWhereOrNull((book) => book.bookId == bookId);
}

class BookIdentifier extends SelectableIdentifier {
  const BookIdentifier(this.bookId);

  final skir.RecordId bookId;

  @override
  String get id => bookId.id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final asyncBook = ref.watch(bookProvider(bookId));
    return asyncBook.whenData((value) {
      if (value == null) throw SelectableNotFoundException(this);
      return BookSelection(ref: ref, id: this, book: value);
    });
  }

  @override
  int get hashCode => bookId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookIdentifier && other.bookId == bookId;

  @override
  String toString() => "BookIdentifier(bookId: $bookId)";
}

class BookSelection extends Selectable<BookIdentifier> {
  BookSelection({required this.ref, required this.id, required this.book})
    : _data = DynamicData({"title": book.title});

  @override
  final BookIdentifier id;
  final Book book;
  final Ref ref;
  final DynamicData _data;

  @override
  String get name => book.title;

  @override
  ObjectBlueprint get objectBlueprint => ObjectBlueprint(
    fields: {
      "title": DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
    },
  );

  @override
  List<SelectableOperation> get operations => [];

  @override
  Widget? header() => BookHeader(
    id: book.bookId.id,
    name: book.title.formatted,
    color: book.color,
  );

  @override
  dynamic fieldValue(String path) => _data.get(path);

  @override
  void setFieldValue(String path, dynamic value) {
    final newData = _data.copyWith(path, value);
    ref
        .read(booksProvider.notifier)
        .updateBook(book.copyWith(title: newData.get("title") as String));
  }

  @override
  int get hashCode => Object.hash(id, book);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookSelection && other.id == id && other.book == book;

  @override
  String toString() => "BookSelection(id: $id, book: $book)";
}

ApiException _bookValidationException(skir.BookValidationError error) {
  return switch (error.kind) {
    skir.BookValidationError_kind.unknown =>
      ApiException.unknownResponseMessage(),
    skir.BookValidationError_kind.titleRequiredConst => ApiException.badRequest(
      "Book title is required",
    ),
    skir.BookValidationError_kind.iconRequiredConst => ApiException.badRequest(
      "Book icon is required",
    ),
  };
}

ApiException _pageValidationException(skir.PageValidationError error) {
  return switch (error.kind) {
    skir.PageValidationError_kind.unknown =>
      ApiException.unknownResponseMessage(),
    skir.PageValidationError_kind.nameRequiredConst => ApiException.badRequest(
      "Page name is required",
    ),
    skir.PageValidationError_kind.pageTypeUnknownConst =>
      ApiException.badRequest("Page type is unknown"),
  };
}
