// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books.dart';

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

  @$internal
  @override
  $AsyncNotifierProviderElement<Books, List<Book>> $createElement(
          $ProviderPointer pointer) =>
      $AsyncNotifierProviderElement(pointer);
}

String _$booksHash() => r'82c44e2cdd55c7f5a47a8736bacfca5560a114f4';

abstract class _$Books extends $AsyncNotifier<List<Book>> {
  FutureOr<List<Book>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Book>>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Book>>>,
        AsyncValue<List<Book>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredBooks)
const filteredBooksProvider = FilteredBooksFamily._();

final class FilteredBooksProvider
    extends $FunctionalProvider<AsyncValue<List<Book>>, FutureOr<List<Book>>>
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
