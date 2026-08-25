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
    r'4c919983889dddf4d34eb24e95e09953663d68a1';

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
    r'dfbda60452b4295e94fb556a46e76b065802ced9';

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

@ProviderFor(realmEditorCatalogLease)
final realmEditorCatalogLeaseProvider = RealmEditorCatalogLeaseFamily._();

final class RealmEditorCatalogLeaseProvider
    extends
        $FunctionalProvider<
          RealmEditorCatalogLease?,
          RealmEditorCatalogLease?,
          RealmEditorCatalogLease?
        >
    with $Provider<RealmEditorCatalogLease?> {
  RealmEditorCatalogLeaseProvider._({
    required RealmEditorCatalogLeaseFamily super.from,
    required RealmEditorCatalogRequest super.argument,
  }) : super(
         retry: null,
         name: r'realmEditorCatalogLeaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmEditorCatalogLeaseHash();

  @override
  String toString() {
    return r'realmEditorCatalogLeaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RealmEditorCatalogLease?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmEditorCatalogLease? create(Ref ref) {
    final argument = this.argument as RealmEditorCatalogRequest;
    return realmEditorCatalogLease(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmEditorCatalogLease? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmEditorCatalogLease?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmEditorCatalogLeaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmEditorCatalogLeaseHash() =>
    r'0ebc66158a07b11aa18b2893e85a14ae2a2bed70';

final class RealmEditorCatalogLeaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          RealmEditorCatalogLease?,
          RealmEditorCatalogRequest
        > {
  RealmEditorCatalogLeaseFamily._()
    : super(
        retry: null,
        name: r'realmEditorCatalogLeaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmEditorCatalogLeaseProvider call(RealmEditorCatalogRequest request) =>
      RealmEditorCatalogLeaseProvider._(argument: request, from: this);

  @override
  String toString() => r'realmEditorCatalogLeaseProvider';
}

@ProviderFor(availableElementDefinitions)
final availableElementDefinitionsProvider =
    AvailableElementDefinitionsProvider._();

final class AvailableElementDefinitionsProvider
    extends
        $FunctionalProvider<
          List<ElementDefinition>,
          List<ElementDefinition>,
          List<ElementDefinition>
        >
    with $Provider<List<ElementDefinition>> {
  AvailableElementDefinitionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableElementDefinitionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableElementDefinitionsHash();

  @$internal
  @override
  $ProviderElement<List<ElementDefinition>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ElementDefinition> create(Ref ref) {
    return availableElementDefinitions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ElementDefinition> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ElementDefinition>>(value),
    );
  }
}

String _$availableElementDefinitionsHash() =>
    r'6b65727c2c4228ceeb9b2f73db1eb1ffd12cdc1c';
