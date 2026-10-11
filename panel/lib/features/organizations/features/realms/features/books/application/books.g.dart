// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Typed book views of the shared working document.

@ProviderFor(workingBooks)
final workingBooksProvider = WorkingBooksProvider._();

/// Typed book views of the shared working document.

final class WorkingBooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Book>>,
          AsyncValue<List<Book>>,
          AsyncValue<List<Book>>
        >
    with $Provider<AsyncValue<List<Book>>> {
  /// Typed book views of the shared working document.
  WorkingBooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workingBooksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workingBooksHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Book>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Book>> create(Ref ref) {
    return workingBooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Book>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Book>>>(value),
    );
  }
}

String _$workingBooksHash() => r'f4bf928031fcce20a2a79012e8e9e0f48fba8ce9';

@ProviderFor(workingBook)
final workingBookProvider = WorkingBookFamily._();

final class WorkingBookProvider
    extends
        $FunctionalProvider<
          AsyncValue<Book?>,
          AsyncValue<Book?>,
          AsyncValue<Book?>
        >
    with $Provider<AsyncValue<Book?>> {
  WorkingBookProvider._({
    required WorkingBookFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'workingBookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workingBookHash();

  @override
  String toString() {
    return r'workingBookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Book?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<Book?> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return workingBook(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Book?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Book?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkingBookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workingBookHash() => r'b105a2d6a53aea2d96953ab177d5b581c9f7d13b';

final class WorkingBookFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Book?>, skir.ResourceId> {
  WorkingBookFamily._()
    : super(
        retry: null,
        name: r'workingBookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkingBookProvider call(skir.ResourceId bookId) =>
      WorkingBookProvider._(argument: bookId, from: this);

  @override
  String toString() => r'workingBookProvider';
}

/// Filters confirmed or locally projected books for the library search.
///
/// Title and resolved tag names are matched case insensitively. An empty query
/// avoids loading tags because every book is already a match. Loading and
/// failure states from either dependency are returned unchanged to the UI.

@ProviderFor(filteredBooks)
final filteredBooksProvider = FilteredBooksFamily._();

/// Filters confirmed or locally projected books for the library search.
///
/// Title and resolved tag names are matched case insensitively. An empty query
/// avoids loading tags because every book is already a match. Loading and
/// failure states from either dependency are returned unchanged to the UI.

final class FilteredBooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Book>>,
          AsyncValue<List<Book>>,
          AsyncValue<List<Book>>
        >
    with $Provider<AsyncValue<List<Book>>> {
  /// Filters confirmed or locally projected books for the library search.
  ///
  /// Title and resolved tag names are matched case insensitively. An empty query
  /// avoids loading tags because every book is already a match. Loading and
  /// failure states from either dependency are returned unchanged to the UI.
  FilteredBooksProvider._({
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
  $ProviderElement<AsyncValue<List<Book>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Book>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredBooks(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Book>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Book>>>(value),
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

String _$filteredBooksHash() => r'e92a3c4dc7faf64afc05700c6142259011daf013';

/// Filters confirmed or locally projected books for the library search.
///
/// Title and resolved tag names are matched case insensitively. An empty query
/// avoids loading tags because every book is already a match. Loading and
/// failure states from either dependency are returned unchanged to the UI.

final class FilteredBooksFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<List<Book>>, String> {
  FilteredBooksFamily._()
    : super(
        retry: null,
        name: r'filteredBooksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Filters confirmed or locally projected books for the library search.
  ///
  /// Title and resolved tag names are matched case insensitively. An empty query
  /// avoids loading tags because every book is already a match. Loading and
  /// failure states from either dependency are returned unchanged to the UI.

  FilteredBooksProvider call(String query) =>
      FilteredBooksProvider._(argument: query, from: this);

  @override
  String toString() => r'filteredBooksProvider';
}

/// Resolves the current route parameter into the typed book record identity.

@ProviderFor(bookId)
final bookIdProvider = BookIdProvider._();

/// Resolves the current route parameter into the typed book record identity.

final class BookIdProvider
    extends
        $FunctionalProvider<
          skir.ResourceId?,
          skir.ResourceId?,
          skir.ResourceId?
        >
    with $Provider<skir.ResourceId?> {
  /// Resolves the current route parameter into the typed book record identity.
  BookIdProvider._()
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
  $ProviderElement<skir.ResourceId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.ResourceId? create(Ref ref) {
    return bookId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.ResourceId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.ResourceId?>(value),
    );
  }
}

String _$bookIdHash() => r'902a2e5fe4f162247509d29a7f1d9e6dbdfbbf79';
