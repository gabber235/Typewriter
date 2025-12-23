// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Books)
const booksProvider = BooksProvider._();

final class BooksProvider extends $StreamNotifierProvider<Books, List<Book>> {
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

String _$booksHash() => r'744083c673ebc702985637728c90a5ce96da2818';

abstract class _$Books extends $StreamNotifier<List<Book>> {
  Stream<List<Book>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Book>>, List<Book>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Book>>, List<Book>>,
              AsyncValue<List<Book>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredBooks)
const filteredBooksProvider = FilteredBooksFamily._();

final class FilteredBooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Book>>,
          List<Book>,
          FutureOr<List<Book>>
        >
    with $FutureModifier<List<Book>>, $FutureProvider<List<Book>> {
  const FilteredBooksProvider._({
    required FilteredBooksFamily super.from,
    required String super.argument,
  }) : super(
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
    return filteredBooks(ref, argument);
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

  FilteredBooksProvider call(String query) =>
      FilteredBooksProvider._(argument: query, from: this);

  @override
  String toString() => r'filteredBooksProvider';
}

@ProviderFor(bookId)
const bookIdProvider = BookIdProvider._();

final class BookIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  const BookIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return bookId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$bookIdHash() => r'd84a340bc2c2d1d02b27b5a7d4b8ea2abdb05918';

@ProviderFor(book)
const bookProvider = BookFamily._();

final class BookProvider
    extends $FunctionalProvider<AsyncValue<Book?>, Book?, FutureOr<Book?>>
    with $FutureModifier<Book?>, $FutureProvider<Book?> {
  const BookProvider._({
    required BookFamily super.from,
    required String super.argument,
  }) : super(
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
    return book(ref, argument);
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

  BookProvider call(String id) => BookProvider._(argument: id, from: this);

  @override
  String toString() => r'bookProvider';
}
