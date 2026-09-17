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

/// Supplies the sidebar projection, preserving local edits while searching.
///
/// A projected result is used immediately when available. Otherwise the
/// canonical provider is awaited once, then the projection is read again so
/// the sidebar does not display stale canonical values over an active draft.

@ProviderFor(_viewingPages)
final _viewingPagesProvider = _ViewingPagesProvider._();

/// Supplies the sidebar projection, preserving local edits while searching.
///
/// A projected result is used immediately when available. Otherwise the
/// canonical provider is awaited once, then the projection is read again so
/// the sidebar does not display stale canonical values over an active draft.

final class _ViewingPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Page>>,
          List<Page>,
          FutureOr<List<Page>>
        >
    with $FutureModifier<List<Page>>, $FutureProvider<List<Page>> {
  /// Supplies the sidebar projection, preserving local edits while searching.
  ///
  /// A projected result is used immediately when available. Otherwise the
  /// canonical provider is awaited once, then the projection is read again so
  /// the sidebar does not display stale canonical values over an active draft.
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
  $FutureProviderElement<List<Page>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Page>> create(Ref ref) {
    return _viewingPages(ref);
  }
}

String _$_viewingPagesHash() => r'a467bc68d6477bec5bead598f4d2592c9e3047bf';
