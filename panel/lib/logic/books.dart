import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/pages/pages.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/logic/tag.dart";
import "package:typewriter_panel/utils/color_converter.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/book.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";

part "books.freezed.dart";
part "books.g.dart";

@riverpod
class Books extends _$Books {
  @override
  FutureOr<List<Book>> build() async {
    // TODO: implement build
    throw UnimplementedError();
  }

  Future<void> updateBook(Book book) async {
    throw UnimplementedError();
  }

  Future<String> createPage(
    String bookId,
    String name,
    PageType type,
    String chapter,
    int priority,
  ) async {
    // TODO: Create page in API or database
    throw UnimplementedError();
  }

  Future<void> deletePage(String pageId) async {
    // TODO: Delete page from API or database
    throw UnimplementedError();
  }

  /// Move all the pages from one chapter to another
  Future<void> changePagesChapters(
    String bookId,
    String oldChapter,
    String newChapter,
  ) async {
    /// TODO: Move pages from old chapter to new chapter
    throw UnimplementedError();
  }
}

@riverpod
Future<List<Book>> filteredBooks(Ref ref, String query) async {
  final books = await ref.watch(booksProvider.future);
  if (query.isEmpty) return books;

  final lowercaseQuery = query.toLowerCase();
  return books.where((book) {
    if (book.title.toLowerCase().contains(lowercaseQuery)) return true;
    return book.tags
        .any((tag) => tag.name.toLowerCase().contains(lowercaseQuery));
  }).toList();
}

@riverpod
String? bookId(Ref ref) {
  final routeData = ref.watch(currentRouteDataProvider(BookRoute.name));
  return routeData?.params.getString("bookId");
}

@riverpod
Future<Book?> book(Ref ref, String id) async {
  final books = await ref.watch(booksProvider.future);
  return books.firstWhereOrNull((book) => book.id == id);
}

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    required String icon,
    @ColorConverter() @Default(Colors.redAccent) Color color,
    @Default([]) List<Tag> tags,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
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
      return BookSelection(
        ref: ref,
        id: this,
        book: value,
      );
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
  BookSelection({
    required this.ref,
    required this.id,
    required this.book,
  }) : _data = DynamicData(book.toJson());

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
        id: book.id,
        name: book.title.formatted,
        color: book.color,
      );

  @override
  dynamic fieldValue(String path) => _data.get(path);

  @override
  void setFieldValue(String path, dynamic value) {
    final newData = _data.copyWith(path, value);
    final newBook = Book.fromJson(newData.toJson());
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
