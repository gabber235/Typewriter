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
/// Projects compile diagnostics for the selected page without hiding the last
/// active manifest when a new document is blocked.

@ProviderFor(pageDocumentHealth)
final pageDocumentHealthProvider = PageDocumentHealthFamily._();

/// Projects compile diagnostics for the selected page without hiding the last
/// active manifest when a new document is blocked.

final class PageDocumentHealthProvider
    extends
        $FunctionalProvider<
          PageDocumentHealth?,
          PageDocumentHealth?,
          PageDocumentHealth?
        >
    with $Provider<PageDocumentHealth?> {
  /// Projects compile diagnostics for the selected page without hiding the last
  /// active manifest when a new document is blocked.
  PageDocumentHealthProvider._({
    required PageDocumentHealthFamily super.from,
    required (skir.RecordId, skir.RecordId, skir.ResourceId) super.argument,
  }) : super(
         retry: null,
         name: r'pageDocumentHealthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageDocumentHealthHash();

  @override
  String toString() {
    return r'pageDocumentHealthProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<PageDocumentHealth?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PageDocumentHealth? create(Ref ref) {
    final argument =
        this.argument as (skir.RecordId, skir.RecordId, skir.ResourceId);
    return pageDocumentHealth(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PageDocumentHealth? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PageDocumentHealth?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageDocumentHealthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageDocumentHealthHash() =>
    r'c8328d82a85d0a404b9e7a67d7610a403b1e79f5';

/// Projects compile diagnostics for the selected page without hiding the last
/// active manifest when a new document is blocked.

final class PageDocumentHealthFamily extends $Family
    with
        $FunctionalFamilyOverride<
          PageDocumentHealth?,
          (skir.RecordId, skir.RecordId, skir.ResourceId)
        > {
  PageDocumentHealthFamily._()
    : super(
        retry: null,
        name: r'pageDocumentHealthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Projects compile diagnostics for the selected page without hiding the last
  /// active manifest when a new document is blocked.

  PageDocumentHealthProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    skir.ResourceId pageId,
  ) => PageDocumentHealthProvider._(
    argument: (organizationId, realmId, pageId),
    from: this,
  );

  @override
  String toString() => r'pageDocumentHealthProvider';
}

/// Adapts the shared authoring session to the page element editor.
///
/// The provider acquires a typed resource selection, waits for the authoring session and
/// catalog projection, then exposes mutations that submit through the shared
/// editor owners. Callers should use [withReadyPageElements] when invoking it
/// outside a widget that already holds the page lifecycle.

@ProviderFor(PageElements)
final pageElementsProvider = PageElementsFamily._();

/// Adapts the shared authoring session to the page element editor.
///
/// The provider acquires a typed resource selection, waits for the authoring session and
/// catalog projection, then exposes mutations that submit through the shared
/// editor owners. Callers should use [withReadyPageElements] when invoking it
/// outside a widget that already holds the page lifecycle.
final class PageElementsProvider
    extends $AsyncNotifierProvider<PageElements, List<PageElement>> {
  /// Adapts the shared authoring session to the page element editor.
  ///
  /// The provider acquires a typed resource selection, waits for the authoring session and
  /// catalog projection, then exposes mutations that submit through the shared
  /// editor owners. Callers should use [withReadyPageElements] when invoking it
  /// outside a widget that already holds the page lifecycle.
  PageElementsProvider._({
    required PageElementsFamily super.from,
    required (skir.RecordId, skir.RecordId, String) super.argument,
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
        '$argument';
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

String _$pageElementsHash() => r'd06e3534c1397c8f9471c5f9eb197ffed6b19957';

/// Adapts the shared authoring session to the page element editor.
///
/// The provider acquires a typed resource selection, waits for the authoring session and
/// catalog projection, then exposes mutations that submit through the shared
/// editor owners. Callers should use [withReadyPageElements] when invoking it
/// outside a widget that already holds the page lifecycle.

final class PageElementsFamily extends $Family
    with
        $ClassFamilyOverride<
          PageElements,
          AsyncValue<List<PageElement>>,
          List<PageElement>,
          FutureOr<List<PageElement>>,
          (skir.RecordId, skir.RecordId, String)
        > {
  PageElementsFamily._()
    : super(
        retry: null,
        name: r'pageElementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Adapts the shared authoring session to the page element editor.
  ///
  /// The provider acquires a typed resource selection, waits for the authoring session and
  /// catalog projection, then exposes mutations that submit through the shared
  /// editor owners. Callers should use [withReadyPageElements] when invoking it
  /// outside a widget that already holds the page lifecycle.

  PageElementsProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  ) => PageElementsProvider._(
    argument: (organizationId, realmId, pageId),
    from: this,
  );

  @override
  String toString() => r'pageElementsProvider';
}

/// Adapts the shared authoring session to the page element editor.
///
/// The provider acquires a typed resource selection, waits for the authoring session and
/// catalog projection, then exposes mutations that submit through the shared
/// editor owners. Callers should use [withReadyPageElements] when invoking it
/// outside a widget that already holds the page lifecycle.

abstract class _$PageElements extends $AsyncNotifier<List<PageElement>> {
  late final _$args = ref.$arg as (skir.RecordId, skir.RecordId, String);
  skir.RecordId get organizationId => _$args.$1;
  skir.RecordId get realmId => _$args.$2;
  String get pageId => _$args.$3;

  FutureOr<List<PageElement>> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}

@ProviderFor(decodedRealmDocumentValues)
final decodedRealmDocumentValuesProvider = DecodedRealmDocumentValuesFamily._();

final class DecodedRealmDocumentValuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>,
          AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>,
          AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>
        >
    with $Provider<AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>> {
  DecodedRealmDocumentValuesProvider._({
    required DecodedRealmDocumentValuesFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'decodedRealmDocumentValuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$decodedRealmDocumentValuesHash();

  @override
  String toString() {
    return r'decodedRealmDocumentValuesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<AuthoringValue<Map<String, List<PageElement>>>> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return decodedRealmDocumentValues(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<AuthoringValue<Map<String, List<PageElement>>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>
          >(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DecodedRealmDocumentValuesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$decodedRealmDocumentValuesHash() =>
    r'5be0897f619f49e1a956d86129be90cc7bf6bef8';

final class DecodedRealmDocumentValuesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<AuthoringValue<Map<String, List<PageElement>>>>,
          (skir.RecordId, skir.RecordId)
        > {
  DecodedRealmDocumentValuesFamily._()
    : super(
        retry: null,
        name: r'decodedRealmDocumentValuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DecodedRealmDocumentValuesProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => DecodedRealmDocumentValuesProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'decodedRealmDocumentValuesProvider';
}

@ProviderFor(decodedRealmDocuments)
final decodedRealmDocumentsProvider = DecodedRealmDocumentsFamily._();

final class DecodedRealmDocumentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<PageElement>>>,
          AsyncValue<Map<String, List<PageElement>>>,
          AsyncValue<Map<String, List<PageElement>>>
        >
    with $Provider<AsyncValue<Map<String, List<PageElement>>>> {
  DecodedRealmDocumentsProvider._({
    required DecodedRealmDocumentsFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'decodedRealmDocumentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$decodedRealmDocumentsHash();

  @override
  String toString() {
    return r'decodedRealmDocumentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<String, List<PageElement>>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<String, List<PageElement>>> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return decodedRealmDocuments(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Map<String, List<PageElement>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<Map<String, List<PageElement>>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DecodedRealmDocumentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$decodedRealmDocumentsHash() =>
    r'0651dda3ca3683062eed53dae7f4b74676d0e3d9';

final class DecodedRealmDocumentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<Map<String, List<PageElement>>>,
          (skir.RecordId, skir.RecordId)
        > {
  DecodedRealmDocumentsFamily._()
    : super(
        retry: null,
        name: r'decodedRealmDocumentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DecodedRealmDocumentsProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => DecodedRealmDocumentsProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'decodedRealmDocumentsProvider';
}

@ProviderFor(authoringPageElements)
final authoringPageElementsProvider = AuthoringPageElementsFamily._();

final class AuthoringPageElementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringValue<List<PageElement>>>,
          AsyncValue<AuthoringValue<List<PageElement>>>,
          AsyncValue<AuthoringValue<List<PageElement>>>
        >
    with $Provider<AsyncValue<AuthoringValue<List<PageElement>>>> {
  AuthoringPageElementsProvider._({
    required AuthoringPageElementsFamily super.from,
    required (skir.RecordId, skir.RecordId, String) super.argument,
  }) : super(
         retry: null,
         name: r'authoringPageElementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringPageElementsHash();

  @override
  String toString() {
    return r'authoringPageElementsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AuthoringValue<List<PageElement>>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<AuthoringValue<List<PageElement>>> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId, String);
    return authoringPageElements(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<AuthoringValue<List<PageElement>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<AuthoringValue<List<PageElement>>>>(
            value,
          ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringPageElementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringPageElementsHash() =>
    r'3f757d0f595b124dcb85739c860a1e041aee04f6';

final class AuthoringPageElementsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<AuthoringValue<List<PageElement>>>,
          (skir.RecordId, skir.RecordId, String)
        > {
  AuthoringPageElementsFamily._()
    : super(
        retry: null,
        name: r'authoringPageElementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthoringPageElementsProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  ) => AuthoringPageElementsProvider._(
    argument: (organizationId, realmId, pageId),
    from: this,
  );

  @override
  String toString() => r'authoringPageElementsProvider';
}

@ProviderFor(authoringEntryIndex)
final authoringEntryIndexProvider = AuthoringEntryIndexFamily._();

final class AuthoringEntryIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>>,
          AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>>,
          AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>>
        >
    with $Provider<AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>>> {
  AuthoringEntryIndexProvider._({
    required AuthoringEntryIndexFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'authoringEntryIndexProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authoringEntryIndexHash();

  @override
  String toString() {
    return r'authoringEntryIndexProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return authoringEntryIndex(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>>
          >(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthoringEntryIndexProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authoringEntryIndexHash() =>
    r'110f89277833d20c03324c2b3da0ce5ba8b72bfb';

final class AuthoringEntryIndexFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<AuthoringValue<Map<String, CachedPageEntry>>>,
          (skir.RecordId, skir.RecordId)
        > {
  AuthoringEntryIndexFamily._()
    : super(
        retry: null,
        name: r'authoringEntryIndexProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthoringEntryIndexProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => AuthoringEntryIndexProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'authoringEntryIndexProvider';
}

@ProviderFor(realmEntryIndex)
final realmEntryIndexProvider = RealmEntryIndexFamily._();

final class RealmEntryIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, CachedPageEntry>>,
          AsyncValue<Map<String, CachedPageEntry>>,
          AsyncValue<Map<String, CachedPageEntry>>
        >
    with $Provider<AsyncValue<Map<String, CachedPageEntry>>> {
  RealmEntryIndexProvider._({
    required RealmEntryIndexFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'realmEntryIndexProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmEntryIndexHash();

  @override
  String toString() {
    return r'realmEntryIndexProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<String, CachedPageEntry>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<String, CachedPageEntry>> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return realmEntryIndex(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Map<String, CachedPageEntry>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<Map<String, CachedPageEntry>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmEntryIndexProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmEntryIndexHash() => r'0f6aeed83acfc9f414c0e86a43b9181ef00de474';

final class RealmEntryIndexFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<Map<String, CachedPageEntry>>,
          (skir.RecordId, skir.RecordId)
        > {
  RealmEntryIndexFamily._()
    : super(
        retry: null,
        name: r'realmEntryIndexProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmEntryIndexProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => RealmEntryIndexProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'realmEntryIndexProvider';
}

@ProviderFor(projectedPageElements)
final projectedPageElementsProvider = ProjectedPageElementsFamily._();

final class ProjectedPageElementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PageElement>>,
          AsyncValue<List<PageElement>>,
          AsyncValue<List<PageElement>>
        >
    with $Provider<AsyncValue<List<PageElement>>> {
  ProjectedPageElementsProvider._({
    required ProjectedPageElementsFamily super.from,
    required (skir.RecordId, skir.RecordId, String) super.argument,
  }) : super(
         retry: null,
         name: r'projectedPageElementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedPageElementsHash();

  @override
  String toString() {
    return r'projectedPageElementsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<PageElement>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<PageElement>> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId, String);
    return projectedPageElements(ref, argument.$1, argument.$2, argument.$3);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<PageElement>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<PageElement>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectedPageElementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedPageElementsHash() =>
    r'e6a70d3c4cea9156c89a439623d367b21f490b58';

final class ProjectedPageElementsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<PageElement>>,
          (skir.RecordId, skir.RecordId, String)
        > {
  ProjectedPageElementsFamily._()
    : super(
        retry: null,
        name: r'projectedPageElementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectedPageElementsProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  ) => ProjectedPageElementsProvider._(
    argument: (organizationId, realmId, pageId),
    from: this,
  );

  @override
  String toString() => r'projectedPageElementsProvider';
}

@ProviderFor(projectedPageElementValues)
final projectedPageElementValuesProvider = ProjectedPageElementValuesFamily._();

final class ProjectedPageElementValuesProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthoringValue<List<PageElement>>>,
          AsyncValue<AuthoringValue<List<PageElement>>>,
          AsyncValue<AuthoringValue<List<PageElement>>>
        >
    with $Provider<AsyncValue<AuthoringValue<List<PageElement>>>> {
  ProjectedPageElementValuesProvider._({
    required ProjectedPageElementValuesFamily super.from,
    required (skir.RecordId, skir.RecordId, String) super.argument,
  }) : super(
         retry: null,
         name: r'projectedPageElementValuesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedPageElementValuesHash();

  @override
  String toString() {
    return r'projectedPageElementValuesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AuthoringValue<List<PageElement>>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<AuthoringValue<List<PageElement>>> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId, String);
    return projectedPageElementValues(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<AuthoringValue<List<PageElement>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<AuthoringValue<List<PageElement>>>>(
            value,
          ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectedPageElementValuesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedPageElementValuesHash() =>
    r'096ff9513eedca9b1fbf8b89b0c753ca9a9148d4';

final class ProjectedPageElementValuesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<AuthoringValue<List<PageElement>>>,
          (skir.RecordId, skir.RecordId, String)
        > {
  ProjectedPageElementValuesFamily._()
    : super(
        retry: null,
        name: r'projectedPageElementValuesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectedPageElementValuesProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  ) => ProjectedPageElementValuesProvider._(
    argument: (organizationId, realmId, pageId),
    from: this,
  );

  @override
  String toString() => r'projectedPageElementValuesProvider';
}

@ProviderFor(projectedPageElement)
final projectedPageElementProvider = ProjectedPageElementFamily._();

final class ProjectedPageElementProvider
    extends
        $FunctionalProvider<
          AsyncValue<PageElement?>,
          AsyncValue<PageElement?>,
          AsyncValue<PageElement?>
        >
    with $Provider<AsyncValue<PageElement?>> {
  ProjectedPageElementProvider._({
    required ProjectedPageElementFamily super.from,
    required (skir.RecordId, skir.RecordId, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'projectedPageElementProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectedPageElementHash();

  @override
  String toString() {
    return r'projectedPageElementProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<PageElement?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<PageElement?> create(Ref ref) {
    final argument =
        this.argument as (skir.RecordId, skir.RecordId, String, String);
    return projectedPageElement(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<PageElement?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<PageElement?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectedPageElementProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectedPageElementHash() =>
    r'2a62b18e92fa63a9b4fb08a05fc5cb89797ee8e6';

final class ProjectedPageElementFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<PageElement?>,
          (skir.RecordId, skir.RecordId, String, String)
        > {
  ProjectedPageElementFamily._()
    : super(
        retry: null,
        name: r'projectedPageElementProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectedPageElementProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
    String elementId,
  ) => ProjectedPageElementProvider._(
    argument: (organizationId, realmId, pageId, elementId),
    from: this,
  );

  @override
  String toString() => r'projectedPageElementProvider';
}
