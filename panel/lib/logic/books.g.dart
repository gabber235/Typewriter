// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Book _$BookFromJson(Map<String, dynamic> json) => _Book(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String,
      color: json['color'] == null
          ? Colors.redAccent
          : const ColorConverter().fromJson(json['color'] as String),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BookToJson(_Book instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'icon': instance.icon,
      'color': const ColorConverter().toJson(instance.color),
      'tags': instance.tags.map((e) => e.toJson()).toList(),
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(Books)
const booksProvider = BooksProvider._();

final class BooksProvider extends $AsyncNotifierProvider<Books, List<Book>> {
  const BooksProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'booksProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$booksHash();

  @$internal
  @override
  Books create() => Books();
}

String _$booksHash() => r'b3bd7e416d8bfcc60ea8071cb8d329e6afa1f356';

abstract class _$Books extends $AsyncNotifier<List<Book>> {
  FutureOr<List<Book>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Book>>, List<Book>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Book>>, List<Book>>,
        AsyncValue<List<Book>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredBooks)
const filteredBooksProvider = FilteredBooksFamily._();

final class FilteredBooksProvider extends $FunctionalProvider<
        AsyncValue<List<Book>>, List<Book>, FutureOr<List<Book>>>
    with $FutureModifier<List<Book>>, $FutureProvider<List<Book>> {
  const FilteredBooksProvider._(
      {required FilteredBooksFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'filteredBooksProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$filteredBooksHash();

  @override
  String toString() {
    return r'filteredBooksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Book>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Book>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredBooks(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredBooksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredBooksHash() => r'1a99f1e7485cf15f30abf8398df62a297b4a0c94';

final class FilteredBooksFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Book>>, String> {
  const FilteredBooksFamily._()
      : super(
          retry: null,
          name: r'filteredBooksProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  FilteredBooksProvider call(
    String query,
  ) =>
      FilteredBooksProvider._(argument: query, from: this);

  @override
  String toString() => r'filteredBooksProvider';
}

@ProviderFor(book)
const bookProvider = BookFamily._();

final class BookProvider
    extends $FunctionalProvider<AsyncValue<Book?>, Book?, FutureOr<Book?>>
    with $FutureModifier<Book?>, $FutureProvider<Book?> {
  const BookProvider._(
      {required BookFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'bookProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bookHash();

  @override
  String toString() {
    return r'bookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Book?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Book?> create(Ref ref) {
    final argument = this.argument as String;
    return book(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookHash() => r'6224bd11964a019166ea5dfd33c52e810deb0a56';

final class BookFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Book?>, String> {
  const BookFamily._()
      : super(
          retry: null,
          name: r'bookProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  BookProvider call(
    String id,
  ) =>
      BookProvider._(argument: id, from: this);

  @override
  String toString() => r'bookProvider';
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
