// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_editor_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(realmEditorCatalogSource)
final realmEditorCatalogSourceProvider = RealmEditorCatalogSourceProvider._();

final class RealmEditorCatalogSourceProvider
    extends
        $FunctionalProvider<
          RealmEditorCatalogSource,
          RealmEditorCatalogSource,
          RealmEditorCatalogSource
        >
    with $Provider<RealmEditorCatalogSource> {
  RealmEditorCatalogSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmEditorCatalogSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmEditorCatalogSourceHash();

  @$internal
  @override
  $ProviderElement<RealmEditorCatalogSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmEditorCatalogSource create(Ref ref) {
    return realmEditorCatalogSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmEditorCatalogSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmEditorCatalogSource>(value),
    );
  }
}

String _$realmEditorCatalogSourceHash() =>
    r'0e74125192df1c16e74a0cd988bc2e68d72b81b8';

@ProviderFor(realmEditorCatalogCache)
final realmEditorCatalogCacheProvider = RealmEditorCatalogCacheProvider._();

final class RealmEditorCatalogCacheProvider
    extends
        $FunctionalProvider<
          RealmEditorCatalogCache?,
          RealmEditorCatalogCache?,
          RealmEditorCatalogCache?
        >
    with $Provider<RealmEditorCatalogCache?> {
  RealmEditorCatalogCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmEditorCatalogCacheProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmEditorCatalogCacheHash();

  @$internal
  @override
  $ProviderElement<RealmEditorCatalogCache?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmEditorCatalogCache? create(Ref ref) {
    return realmEditorCatalogCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmEditorCatalogCache? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmEditorCatalogCache?>(value),
    );
  }
}

String _$realmEditorCatalogCacheHash() =>
    r'42a6334c39bcca0c0e3887213bb567d15a3021c6';

@ProviderFor(realmEditorCatalog)
final realmEditorCatalogProvider = RealmEditorCatalogProvider._();

final class RealmEditorCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmEditorCatalogState>,
          RealmEditorCatalogState,
          Stream<RealmEditorCatalogState>
        >
    with
        $FutureModifier<RealmEditorCatalogState>,
        $StreamProvider<RealmEditorCatalogState> {
  RealmEditorCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmEditorCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmEditorCatalogHash();

  @$internal
  @override
  $StreamProviderElement<RealmEditorCatalogState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RealmEditorCatalogState> create(Ref ref) {
    return realmEditorCatalog(ref);
  }
}

String _$realmEditorCatalogHash() =>
    r'6ce9c4d1a238c8f20f50a3520d0a94f6ef4b8e99';

@ProviderFor(realmEditorCatalogForType)
final realmEditorCatalogForTypeProvider = RealmEditorCatalogForTypeFamily._();

final class RealmEditorCatalogForTypeProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmEditorCatalogState>,
          RealmEditorCatalogState,
          Stream<RealmEditorCatalogState>
        >
    with
        $FutureModifier<RealmEditorCatalogState>,
        $StreamProvider<RealmEditorCatalogState> {
  RealmEditorCatalogForTypeProvider._({
    required RealmEditorCatalogForTypeFamily super.from,
    required ResolvedTypeRef super.argument,
  }) : super(
         retry: null,
         name: r'realmEditorCatalogForTypeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmEditorCatalogForTypeHash();

  @override
  String toString() {
    return r'realmEditorCatalogForTypeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<RealmEditorCatalogState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RealmEditorCatalogState> create(Ref ref) {
    final argument = this.argument as ResolvedTypeRef;
    return realmEditorCatalogForType(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RealmEditorCatalogForTypeProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmEditorCatalogForTypeHash() =>
    r'39980356c3859f9a615c02cee80cb0b85c7ef543';

final class RealmEditorCatalogForTypeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<RealmEditorCatalogState>,
          ResolvedTypeRef
        > {
  RealmEditorCatalogForTypeFamily._()
    : super(
        retry: null,
        name: r'realmEditorCatalogForTypeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmEditorCatalogForTypeProvider call(ResolvedTypeRef rootType) =>
      RealmEditorCatalogForTypeProvider._(argument: rootType, from: this);

  @override
  String toString() => r'realmEditorCatalogForTypeProvider';
}
