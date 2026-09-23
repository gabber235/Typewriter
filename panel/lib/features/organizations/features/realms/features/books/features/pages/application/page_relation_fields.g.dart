// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_relation_fields.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pageElementsField)
final pageElementsFieldProvider = PageElementsFieldFamily._();

final class PageElementsFieldProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmRelationField>,
          AsyncValue<RealmRelationField>,
          AsyncValue<RealmRelationField>
        >
    with $Provider<AsyncValue<RealmRelationField>> {
  PageElementsFieldProvider._({
    required PageElementsFieldFamily super.from,
    required ResolvedTypeRef super.argument,
  }) : super(
         retry: null,
         name: r'pageElementsFieldProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageElementsFieldHash();

  @override
  String toString() {
    return r'pageElementsFieldProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<RealmRelationField>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<RealmRelationField> create(Ref ref) {
    final argument = this.argument as ResolvedTypeRef;
    return pageElementsField(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RealmRelationField> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RealmRelationField>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageElementsFieldProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageElementsFieldHash() => r'2de093ff947cacbb5799f3384975d798833835a3';

final class PageElementsFieldFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<RealmRelationField>,
          ResolvedTypeRef
        > {
  PageElementsFieldFamily._()
    : super(
        retry: null,
        name: r'pageElementsFieldProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PageElementsFieldProvider call(ResolvedTypeRef pageType) =>
      PageElementsFieldProvider._(argument: pageType, from: this);

  @override
  String toString() => r'pageElementsFieldProvider';
}

@ProviderFor(pageElementsFieldForPage)
final pageElementsFieldForPageProvider = PageElementsFieldForPageFamily._();

final class PageElementsFieldForPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmRelationField>,
          AsyncValue<RealmRelationField>,
          AsyncValue<RealmRelationField>
        >
    with $Provider<AsyncValue<RealmRelationField>> {
  PageElementsFieldForPageProvider._({
    required PageElementsFieldForPageFamily super.from,
    required skir.ResourceId super.argument,
  }) : super(
         retry: null,
         name: r'pageElementsFieldForPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageElementsFieldForPageHash();

  @override
  String toString() {
    return r'pageElementsFieldForPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<RealmRelationField>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<RealmRelationField> create(Ref ref) {
    final argument = this.argument as skir.ResourceId;
    return pageElementsFieldForPage(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<RealmRelationField> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<RealmRelationField>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageElementsFieldForPageProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageElementsFieldForPageHash() =>
    r'9c4fae95c6f9b136e6b918d2820c6f378f4ae75f';

final class PageElementsFieldForPageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<RealmRelationField>,
          skir.ResourceId
        > {
  PageElementsFieldForPageFamily._()
    : super(
        retry: null,
        name: r'pageElementsFieldForPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PageElementsFieldForPageProvider call(skir.ResourceId pageId) =>
      PageElementsFieldForPageProvider._(argument: pageId, from: this);

  @override
  String toString() => r'pageElementsFieldForPageProvider';
}

@ProviderFor(compatiblePageElementsFields)
final compatiblePageElementsFieldsProvider =
    CompatiblePageElementsFieldsFamily._();

final class CompatiblePageElementsFieldsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>,
          AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>,
          AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>
        >
    with $Provider<AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>> {
  CompatiblePageElementsFieldsProvider._({
    required CompatiblePageElementsFieldsFamily super.from,
    required ResolvedTypeRef super.argument,
  }) : super(
         retry: null,
         name: r'compatiblePageElementsFieldsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$compatiblePageElementsFieldsHash();

  @override
  String toString() {
    return r'compatiblePageElementsFieldsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<ResolvedTypeRef, RealmRelationField>> create(Ref ref) {
    final argument = this.argument as ResolvedTypeRef;
    return compatiblePageElementsFields(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<ResolvedTypeRef, RealmRelationField>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>
          >(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CompatiblePageElementsFieldsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$compatiblePageElementsFieldsHash() =>
    r'426fa9201448086ee39cc76803149d42f5fd4724';

final class CompatiblePageElementsFieldsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>,
          ResolvedTypeRef
        > {
  CompatiblePageElementsFieldsFamily._()
    : super(
        retry: null,
        name: r'compatiblePageElementsFieldsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompatiblePageElementsFieldsProvider call(ResolvedTypeRef elementType) =>
      CompatiblePageElementsFieldsProvider._(argument: elementType, from: this);

  @override
  String toString() => r'compatiblePageElementsFieldsProvider';
}

@ProviderFor(pageElementsFields)
final pageElementsFieldsProvider = PageElementsFieldsProvider._();

final class PageElementsFieldsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>,
          AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>,
          AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>
        >
    with $Provider<AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>> {
  PageElementsFieldsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pageElementsFieldsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pageElementsFieldsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<ResolvedTypeRef, RealmRelationField>> create(Ref ref) {
    return pageElementsFields(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<Map<ResolvedTypeRef, RealmRelationField>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>
          >(value),
    );
  }
}

String _$pageElementsFieldsHash() =>
    r'947930d15731c00d8bb926b9ccf84269c723d93a';
