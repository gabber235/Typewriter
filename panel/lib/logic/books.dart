import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:mocktail/mocktail.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
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
