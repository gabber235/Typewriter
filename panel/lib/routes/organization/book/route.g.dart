// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_PageSearch)
final _pageSearchProvider = _PageSearchProvider._();

final class _PageSearchProvider extends $NotifierProvider<_PageSearch, String> {
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

abstract class _$PageSearch extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(_viewingPages)
final _viewingPagesProvider = _ViewingPagesProvider._();

final class _ViewingPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Page>>,
          List<Page>,
          FutureOr<List<Page>>
        >
    with $FutureModifier<List<Page>>, $FutureProvider<List<Page>> {
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

String _$_viewingPagesHash() => r'09a0e3f044a93cc9779b15a2af7237b786d64186';
