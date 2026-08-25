// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_elements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ElementLink _$ElementLinkFromJson(Map<String, dynamic> json) => _ElementLink(
  linkId: json['linkId'] as String,
  otherId: json['otherId'] as String,
  path: json['path'] as String,
);

Map<String, dynamic> _$ElementLinkToJson(_ElementLink instance) =>
    <String, dynamic>{
      'linkId': instance.linkId,
      'otherId': instance.otherId,
      'path': instance.path,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PageDocumentHealthCache)
final pageDocumentHealthCacheProvider = PageDocumentHealthCacheProvider._();

final class PageDocumentHealthCacheProvider
    extends
        $NotifierProvider<
          PageDocumentHealthCache,
          Map<String, PageDocumentHealth>
        > {
  PageDocumentHealthCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageDocumentHealthCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageDocumentHealthCacheHash();

  @$internal
  @override
  PageDocumentHealthCache create() => PageDocumentHealthCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, PageDocumentHealth> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, PageDocumentHealth>>(
        value,
      ),
    );
  }
}

String _$pageDocumentHealthCacheHash() =>
    r'3888b0359d43ba4dcdbf6bc98f848a2619bf0e99';

abstract class _$PageDocumentHealthCache
    extends $Notifier<Map<String, PageDocumentHealth>> {
  Map<String, PageDocumentHealth> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, PageDocumentHealth>,
              Map<String, PageDocumentHealth>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, PageDocumentHealth>,
                Map<String, PageDocumentHealth>
              >,
              Map<String, PageDocumentHealth>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(PageEntryCache)
final pageEntryCacheProvider = PageEntryCacheProvider._();

final class PageEntryCacheProvider
    extends $NotifierProvider<PageEntryCache, Map<String, CachedPageEntry>> {
  PageEntryCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageEntryCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageEntryCacheHash();

  @$internal
  @override
  PageEntryCache create() => PageEntryCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, CachedPageEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, CachedPageEntry>>(value),
    );
  }
}

String _$pageEntryCacheHash() => r'ea70b1f8716265ac506dd34ec34e7d555a8c52d1';

abstract class _$PageEntryCache
    extends $Notifier<Map<String, CachedPageEntry>> {
  Map<String, CachedPageEntry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, CachedPageEntry>, Map<String, CachedPageEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, CachedPageEntry>,
                Map<String, CachedPageEntry>
              >,
              Map<String, CachedPageEntry>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(pageDocumentInvalidations)
final pageDocumentInvalidationsProvider = PageDocumentInvalidationsFamily._();

final class PageDocumentInvalidationsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  PageDocumentInvalidationsProvider._({
    required PageDocumentInvalidationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pageDocumentInvalidationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageDocumentInvalidationsHash();

  @override
  String toString() {
    return r'pageDocumentInvalidationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return pageDocumentInvalidations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PageDocumentInvalidationsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageDocumentInvalidationsHash() =>
    r'670df1af1ea58278afcb38b67eeafe615d5e52e1';

final class PageDocumentInvalidationsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  PageDocumentInvalidationsFamily._()
    : super(
        retry: null,
        name: r'pageDocumentInvalidationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PageDocumentInvalidationsProvider call(String pageId) =>
      PageDocumentInvalidationsProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageDocumentInvalidationsProvider';
}

@ProviderFor(PageElements)
final pageElementsProvider = PageElementsFamily._();

final class PageElementsProvider
    extends $AsyncNotifierProvider<PageElements, List<PageElement>> {
  PageElementsProvider._({
    required PageElementsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pageElementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageElementsHash();

  @override
  String toString() {
    return r'pageElementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PageElements create() => PageElements();

  @override
  bool operator ==(Object other) {
    return other is PageElementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageElementsHash() => r'3e7f08b359bc9f96a12e2d1aff9b47388baf4d6e';

final class PageElementsFamily extends $Family
    with
        $ClassFamilyOverride<
          PageElements,
          AsyncValue<List<PageElement>>,
          List<PageElement>,
          FutureOr<List<PageElement>>,
          String
        > {
  PageElementsFamily._()
    : super(
        retry: null,
        name: r'pageElementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PageElementsProvider call(String pageId) =>
      PageElementsProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageElementsProvider';
}

abstract class _$PageElements extends $AsyncNotifier<List<PageElement>> {
  late final _$args = ref.$arg as String;
  String get pageId => _$args;

  FutureOr<List<PageElement>> build(String pageId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PageElement>>, List<PageElement>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PageElement>>, List<PageElement>>,
              AsyncValue<List<PageElement>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
