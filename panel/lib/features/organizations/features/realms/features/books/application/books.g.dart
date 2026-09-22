// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'books.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the confirmed book collection for the selected organization and realm.
///
/// The realm authoring session remains the source of truth. This provider waits
/// for the registered book selection to become ready, then projects records into
/// immutable [Book] values and listens for later session sequences. Consumers
/// that render or edit immediately should choose [projectedBooksProvider] or
/// [projectedBookProvider] when local editor values must be visible.

@ProviderFor(CanonicalBooks)
final canonicalBooksProvider = CanonicalBooksProvider._();

/// Owns the confirmed book collection for the selected organization and realm.
///
/// The realm authoring session remains the source of truth. This provider waits
/// for the registered book selection to become ready, then projects records into
/// immutable [Book] values and listens for later session sequences. Consumers
/// that render or edit immediately should choose [projectedBooksProvider] or
/// [projectedBookProvider] when local editor values must be visible.
final class CanonicalBooksProvider
    extends $AsyncNotifierProvider<CanonicalBooks, List<Book>> {
  /// Owns the confirmed book collection for the selected organization and realm.
  ///
  /// The realm authoring session remains the source of truth. This provider waits
  /// for the registered book selection to become ready, then projects records into
  /// immutable [Book] values and listens for later session sequences. Consumers
  /// that render or edit immediately should choose [projectedBooksProvider] or
  /// [projectedBookProvider] when local editor values must be visible.
  CanonicalBooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canonicalBooksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canonicalBooksHash();

  @$internal
  @override
  CanonicalBooks create() => CanonicalBooks();
}

String _$canonicalBooksHash() => r'423848561bc7d427d3fc28e70293f987840e83b6';

/// Owns the confirmed book collection for the selected organization and realm.
///
/// The realm authoring session remains the source of truth. This provider waits
/// for the registered book selection to become ready, then projects records into
/// immutable [Book] values and listens for later session sequences. Consumers
/// that render or edit immediately should choose [projectedBooksProvider] or
/// [projectedBookProvider] when local editor values must be visible.

abstract class _$CanonicalBooks extends $AsyncNotifier<List<Book>> {
  FutureOr<List<Book>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Book>>, List<Book>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Book>>, List<Book>>,
              AsyncValue<List<Book>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
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

String _$filteredBooksHash() => r'0e92e57f11f3e60af7c06e43862d13346de4854b';

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

/// Finds one confirmed book in the authoritative realm session.

@ProviderFor(canonicalBook)
final canonicalBookProvider = CanonicalBookFamily._();

/// Finds one confirmed book in the authoritative realm session.

final class CanonicalBookProvider
    extends $FunctionalProvider<AsyncValue<Book?>, Book?, FutureOr<Book?>>
    with $FutureModifier<Book?>, $FutureProvider<Book?> {
  /// Finds one confirmed book in the authoritative realm session.
  CanonicalBookProvider._({
    required CanonicalBookFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'canonicalBookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canonicalBookHash();

  @override
  String toString() {
    return r'canonicalBookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Book?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Book?> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return canonicalBook(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CanonicalBookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canonicalBookHash() => r'43552f0ec9a18c8da40af8e810152f78bc9b3d36';

/// Finds one confirmed book in the authoritative realm session.

final class CanonicalBookFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Book?>, skir.ResourceId> {
  CanonicalBookFamily._()
    : super(
        retry: null,
        name: r'canonicalBookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Finds one confirmed book in the authoritative realm session.

  CanonicalBookProvider call(skir.ResourceId bookId) =>
      CanonicalBookProvider._(argument: bookId, from: this);

  @override
  String toString() => r'canonicalBookProvider';
}

/// Overlays local editor values on the confirmed book collection.
///
/// The authoring session remains canonical. Local values belong to the
/// resource key for the current organization and realm. An invalid projection
/// is ignored, leaving the confirmed value visible to this view.

@ProviderFor(projectedBooks)
final projectedBooksProvider = ProjectedBooksProvider._();

/// Overlays local editor values on the confirmed book collection.
///
/// The authoring session remains canonical. Local values belong to the
/// resource key for the current organization and realm. An invalid projection
/// is ignored, leaving the confirmed value visible to this view.

final class ProjectedBooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Book>>,
          AsyncValue<List<Book>>,
          AsyncValue<List<Book>>
        >
    with $Provider<AsyncValue<List<Book>>> {
  /// Overlays local editor values on the confirmed book collection.
  ///
  /// The authoring session remains canonical. Local values belong to the
  /// resource key for the current organization and realm. An invalid projection
  /// is ignored, leaving the confirmed value visible to this view.
  ProjectedBooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectedBooksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectedBooksHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Book>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Book>> create(Ref ref) {
    return projectedBooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Book>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Book>>>(value),
    );
  }
}

String _$projectedBooksHash() => r'e54b3aacde4ddc90b0a34b08879e9bf735e80152';

/// Returns one book with its local editor projection, if present.
///
/// This is the read model for consumers that need edits before confirmation.
/// It retains the canonical loading or missing value state until the local
/// overlay can be applied.

@ProviderFor(projectedBook)
final projectedBookProvider = ProjectedBookFamily._();

/// Returns one book with its local editor projection, if present.
///
/// This is the read model for consumers that need edits before confirmation.
/// It retains the canonical loading or missing value state until the local
/// overlay can be applied.

final class ProjectedBookProvider
    extends
        $FunctionalProvider<
          AsyncValue<Book?>,
          AsyncValue<Book?>,
          AsyncValue<Book?>
        >
    with $Provider<AsyncValue<Book?>> {
  /// Returns one book with its local editor projection, if present.
  ///
  /// This is the read model for consumers that need edits before confirmation.
  /// It retains the canonical loading or missing value state until the local
  /// overlay can be applied.
  ProjectedBookProvider._({
    required ProjectedBookFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'projectedBookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedBookHash();

  @override
  String toString() {
    return r'projectedBookProvider'
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
    return projectedBook(ref, argument);
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
    return other is ProjectedBookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedBookHash() => r'47d27d7b9d7b00447dd69a75667bcf56e82df964';

/// Returns one book with its local editor projection, if present.
///
/// This is the read model for consumers that need edits before confirmation.
/// It retains the canonical loading or missing value state until the local
/// overlay can be applied.

final class ProjectedBookFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<Book?>, skir.ResourceId> {
  ProjectedBookFamily._()
    : super(
        retry: null,
        name: r'projectedBookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns one book with its local editor projection, if present.
  ///
  /// This is the read model for consumers that need edits before confirmation.
  /// It retains the canonical loading or missing value state until the local
  /// overlay can be applied.

  ProjectedBookProvider call(skir.ResourceId bookId) =>
      ProjectedBookProvider._(argument: bookId, from: this);

  @override
  String toString() => r'projectedBookProvider';
}
