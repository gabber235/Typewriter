// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search text local to the current book sidebar.
///
/// It is intentionally separate from canonical page state. The derived page
/// provider combines this query with canonical pages and local editor work.

@ProviderFor(_PageSearch)
final _pageSearchProvider = _PageSearchProvider._();

/// Search text local to the current book sidebar.
///
/// It is intentionally separate from canonical page state. The derived page
/// provider combines this query with canonical pages and local editor work.
final class _PageSearchProvider extends $NotifierProvider<_PageSearch, String> {
  /// Search text local to the current book sidebar.
  ///
  /// It is intentionally separate from canonical page state. The derived page
  /// provider combines this query with canonical pages and local editor work.
  _PageSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_pageSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_pageSearchHash();

  @$internal
  @override
  _PageSearch create() => _PageSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$_pageSearchHash() => r'd35888cd68dcb69748549e6cf1cdc6d5eb6326f2';

/// Search text local to the current book sidebar.
///
/// It is intentionally separate from canonical page state. The derived page
/// provider combines this query with canonical pages and local editor work.

abstract class _$PageSearch extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Filters shared working pages immediately as values or search text change.

@ProviderFor(_viewingPages)
final _viewingPagesProvider = _ViewingPagesProvider._();

/// Filters shared working pages immediately as values or search text change.

final class _ViewingPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>,
          AsyncValue<List<Page>>
        >
    with $Provider<AsyncValue<List<Page>>> {
  /// Filters shared working pages immediately as values or search text change.
  _ViewingPagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_viewingPagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_viewingPagesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Page>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Page>> create(Ref ref) {
    return _viewingPages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Page>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Page>>>(value),
    );
  }
}

String _$_viewingPagesHash() => r'743feac838e37f37ecc5f92b69fbe17a77ab9399';
