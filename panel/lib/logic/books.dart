import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:mocktail/mocktail.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/logic/tag.dart";
import "package:typewriter_panel/utils/color_converter.dart";

part "books.g.dart";
part "books.freezed.dart";

@riverpod
class Books extends _$Books {
  @override
  FutureOr<List<Book>> build() async {
    // TODO: implement build
    return [];
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
Future<Book?> book(Ref ref, String id) async {
  final books = await ref.watch(booksProvider.future);
  return books.firstWhereOrNull((book) => book.id == id);
}

// ignore: prefer_mixin
class BooksMock extends _$Books with Mock implements Books {}

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    required String icon,
    @ColorConverter() @Default(Colors.redAccent) Color color,
    @Default([]) List<Tag> tags,
  }) = _Book;
}

class BookSelector extends SelectableIdentifier {
  BookSelector(this.id);

  @override
  final String id;

  @override
  Future<Selectable> create(Ref ref) async {
    final book = await ref.watch(bookProvider(id).future);
    if (book == null) throw SelectableNotFoundException(this);

    return BookSelection(
      id: this,
      name: book.title,
    );
  }
}

class BookSelection extends Selectable<BookSelector> {
  BookSelection({required this.id, required this.name});

  @override
  final BookSelector id;
  @override
  final String name;

  @override
  ObjectBlueprint get objectBlueprint {
    return ObjectBlueprint(
      fields: {
        "name": DataBlueprint.string(),
        // "icon": DataBlueprint.primitive(type: PrimitiveType.string),
        // "color": DataBlueprint.custom("color"),
        // "tags": DataBlueprint.list(
        // type: DataBlueprint.custom(editor: "tag", shape: shape)
        // ),
      },
    );
  }

  @override
  Widget? header() {
    // TODO: implement header
    throw UnimplementedError();
  }

  @override
  fieldValue(String path) {
    // TODO: implement fieldValue
    throw UnimplementedError();
  }

  @override
  void setFieldValue(String path, value) {
    // TODO: implement setFieldValue
  }

}
