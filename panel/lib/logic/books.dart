import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/api/book.pb.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/logic/proto/api_exception.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/logic/realm.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/book.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";

part "books.g.dart";

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

    final request = ListBooksRequest();
    final stream = ref.requestProtoThenListen(
      subject: "realm.to.$realmId.organization.$organizationId.book.list",
      listenSubject:
          "realm.from.$realmId.organization.$organizationId.book.list",
      request: request,
      responseBuilder: ListBooksResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.books.books.toList();
    }
  }

  Future<Book> createBook({
    required String title,
    String? icon,
    Color? color,
    List<String> tagIds = const [],
  }) async {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when creating a book");
    assert(
      organizationId != null,
      "organizationId must not be null when creating a book",
    );

    final request = CreateBookRequest()
      ..title = title
      ..icon = icon ?? "book";

    if (color != null) {
      request.color = color.toProtoColor();
    }
    request.tagIds.addAll(tagIds);

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.to.$realmId.organization.$organizationId.book.create",
          request,
          CreateBookResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    ref.invalidateSelf();
    return response.book;
  }

  Future<void> updateBook(Book book) async {
    state.ensureReady();

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when updating a book");
    assert(
      organizationId != null,
      "organizationId must not be null when updating a book",
    );

    final currentState = state.value ?? [];
    final optimisticState = currentState
        .map((b) => b.bookId == book.bookId ? book : b)
        .toList();
    state = AsyncData(optimisticState);

    try {
      final request = UpdateBookRequest()..book = book;
      final response = await ref
          .read(natsProvider)
          .requestProto(
            "realm.to.$realmId.organization.$organizationId.book.update",
            request,
            UpdateBookResponse.new,
          );

      if (response.hasError()) {
        state = AsyncData(currentState);
        throw ApiException.fromProto(response.error);
      }

      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(currentState);
      rethrow;
    }
  }

  Future<String> createPage(
    String bookId,
    String name,
    PageType type,
    String chapter,
    int priority,
  ) async {
    state.ensureReady();

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when creating a page");
    assert(
      organizationId != null,
      "organizationId must not be null when creating a page",
    );

    final request = CreatePageRequest()
      ..bookId = bookId
      ..name = name
      ..type = type
      ..chapter = chapter
      ..priority = priority;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.to.$realmId.organization.$organizationId.page.create",
          request,
          CreatePageResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }
    if (!response.hasPageId()) {
      throw const ApiException(code: 500, message: "No page ID returned");
    }

    return response.pageId;
  }

  Future<void> deletePage(String pageId) async {
    state.ensureReady();

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(realmId != null, "realmId must not be null when deleting a page");
    assert(
      organizationId != null,
      "organizationId must not be null when deleting a page",
    );

    final request = DeletePageRequest()..pageId = pageId;
    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.to.$realmId.organization.$organizationId.page.delete",
          request,
          DeletePageResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }
  }

  /// Move all the pages from one chapter to another
  Future<void> changePagesChapters(
    String bookId,
    String oldChapter,
    String newChapter,
  ) async {
    state.ensureReady();

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    assert(
      realmId != null,
      "realmId must not be null when changing page chapters",
    );
    assert(
      organizationId != null,
      "organizationId must not be null when changing page chapters",
    );

    final request = ChangePagesChaptersRequest()
      ..bookId = bookId
      ..oldChapter = oldChapter
      ..newChapter = newChapter;

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "realm.to.$realmId.organization.$organizationId.pages.chapters",
          request,
          ChangePagesChaptersResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
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
String? bookId(Ref ref) {
  return ref.watch(routeParamProvider("bookId"));
}

@riverpod
Future<Book?> book(Ref ref, String id) async {
  final books = await ref.watch(booksProvider.future);
  return books.firstWhereOrNull((book) => book.bookId == id);
}

/// Extension on Book proto to add utility methods
extension BookExtension on Book {
  /// Get the Flutter color from the proto color
  Color get flutterColor => color.toFlutterColor();

  /// Create a new Book with updated color
  Book withColor(Color newColor) {
    return deepCopy()..color = newColor.toProtoColor();
  }
}

class BookIdentifier extends SelectableIdentifier {
  BookIdentifier(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final asyncBook = ref.watch(bookProvider(id));
    return asyncBook.whenData((value) {
      if (value == null) {
        throw SelectableNotFoundException(this);
      }
      return BookSelection(ref: ref, id: this, book: value);
    });
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookIdentifier && other.id == id;
  }

  @override
  String toString() => "BookSelector(id: $id)";
}

class BookSelection extends Selectable<BookIdentifier> {
  BookSelection({required this.ref, required this.id, required this.book})
    : _data = DynamicData(book.toJsonMap());

  @override
  final BookIdentifier id;

  final Book book;

  @override
  String get name => book.title;

  final Ref ref;

  final DynamicData _data;

  @override
  ObjectBlueprint get objectBlueprint {
    return ObjectBlueprint(
      fields: {
        "title": DataBlueprint.string(modifiers: [Modifier.snakeCase()]),
        // "icon": DataBlueprint.primitive(type: PrimitiveType.string),
        // "color": DataBlueprint.custom("color"),
        // "tags": DataBlueprint.list(
        // type: DataBlueprint.custom(editor: "tag", shape: shape)
        // ),
      },
    );
  }

  @override
  List<SelectableOperation> get operations => [];

  @override
  Widget? header() => BookHeader(
    id: book.bookId,
    name: book.title.formatted,
    color: book.flutterColor,
  );

  @override
  dynamic fieldValue(String path) => _data.get(path);

  @override
  void setFieldValue(String path, dynamic value) {
    final newData = _data.copyWith(path, value);
    final newBook = Book()..mergeFromProto3Json(newData.toJson());
    ref.read(booksProvider.notifier).updateBook(newBook);
  }

  @override
  int get hashCode => Object.hash(id, book);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BookSelection) return false;
    return other.id == id && other.book == book;
  }

  @override
  String toString() => "BookSelection(id: $id, book: $book)";
}
