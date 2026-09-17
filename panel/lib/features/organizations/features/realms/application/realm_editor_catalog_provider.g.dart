// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_editor_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the replaceable catalog transport boundary.

@ProviderFor(realmEditorCatalogSource)
final realmEditorCatalogSourceProvider = RealmEditorCatalogSourceProvider._();

/// Provides the replaceable catalog transport boundary.

final class RealmEditorCatalogSourceProvider
    extends
        $FunctionalProvider<
          RealmEditorCatalogSource,
          RealmEditorCatalogSource,
          RealmEditorCatalogSource
        >
    with $Provider<RealmEditorCatalogSource> {
  /// Provides the replaceable catalog transport boundary.
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

/// Owns the catalog cache while the selected realm is online.
///
/// A null value is deliberate when selection or connectivity is absent. This
/// prevents stale realm subscriptions from surviving a route or connection
/// change.

@ProviderFor(realmEditorCatalogCache)
final realmEditorCatalogCacheProvider = RealmEditorCatalogCacheProvider._();

/// Owns the catalog cache while the selected realm is online.
///
/// A null value is deliberate when selection or connectivity is absent. This
/// prevents stale realm subscriptions from surviving a route or connection
/// change.

final class RealmEditorCatalogCacheProvider
    extends
        $FunctionalProvider<
          RealmEditorCatalogCache?,
          RealmEditorCatalogCache?,
          RealmEditorCatalogCache?
        >
    with $Provider<RealmEditorCatalogCache?> {
  /// Owns the catalog cache while the selected realm is online.
  ///
  /// A null value is deliberate when selection or connectivity is absent. This
  /// prevents stale realm subscriptions from surviving a route or connection
  /// change.
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

/// Exposes catalog state, including explicit reasons for missing selection or
/// connection. Consumers should watch this stream instead of creating a cache.

@ProviderFor(realmEditorCatalog)
final realmEditorCatalogProvider = RealmEditorCatalogProvider._();

/// Exposes catalog state, including explicit reasons for missing selection or
/// connection. Consumers should watch this stream instead of creating a cache.

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
  /// Exposes catalog state, including explicit reasons for missing selection or
  /// connection. Consumers should watch this stream instead of creating a cache.
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

/// Retains one root type as demand on the shared catalog cache.

@ProviderFor(realmEditorCatalogForType)
final realmEditorCatalogForTypeProvider = RealmEditorCatalogForTypeFamily._();

/// Retains one root type as demand on the shared catalog cache.

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
  /// Retains one root type as demand on the shared catalog cache.
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

/// Retains one root type as demand on the shared catalog cache.

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

  /// Retains one root type as demand on the shared catalog cache.

  RealmEditorCatalogForTypeProvider call(ResolvedTypeRef rootType) =>
      RealmEditorCatalogForTypeProvider._(argument: rootType, from: this);

  @override
  String toString() => r'realmEditorCatalogForTypeProvider';
}

/// Acquires a provider owned lease for merged catalog demand.

@ProviderFor(realmEditorCatalogLease)
final realmEditorCatalogLeaseProvider = RealmEditorCatalogLeaseFamily._();

/// Acquires a provider owned lease for merged catalog demand.

final class RealmEditorCatalogLeaseProvider
    extends
        $FunctionalProvider<
          RealmEditorCatalogLease?,
          RealmEditorCatalogLease?,
          RealmEditorCatalogLease?
        >
    with $Provider<RealmEditorCatalogLease?> {
  /// Acquires a provider owned lease for merged catalog demand.
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

/// Acquires a provider owned lease for merged catalog demand.

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

  /// Acquires a provider owned lease for merged catalog demand.

  RealmEditorCatalogLeaseProvider call(RealmEditorCatalogRequest request) =>
      RealmEditorCatalogLeaseProvider._(argument: request, from: this);

  @override
  String toString() => r'realmEditorCatalogLeaseProvider';
}

/// Returns page definitions from the latest complete realm catalog.

@ProviderFor(realmPageDefinitions)
final realmPageDefinitionsProvider = RealmPageDefinitionsProvider._();

/// Returns page definitions from the latest complete realm catalog.

final class RealmPageDefinitionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RealmPageDefinition>>,
          AsyncValue<List<RealmPageDefinition>>,
          AsyncValue<List<RealmPageDefinition>>
        >
    with $Provider<AsyncValue<List<RealmPageDefinition>>> {
  /// Returns page definitions from the latest complete realm catalog.
  RealmPageDefinitionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmPageDefinitionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmPageDefinitionsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<RealmPageDefinition>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<RealmPageDefinition>> create(Ref ref) {
    return realmPageDefinitions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<RealmPageDefinition>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<RealmPageDefinition>>>(value),
    );
  }
}

String _$realmPageDefinitionsHash() =>
    r'397c78750833dd566ec9bc7d3c09c1feb7c5d9c0';

/// Returns discovered definitions that the realm permits and exposes while
/// preserving catalog loading and failure states for asynchronous consumers.

@ProviderFor(availableElementDefinitionsFuture)
final availableElementDefinitionsFutureProvider =
    AvailableElementDefinitionsFutureProvider._();

/// Returns discovered definitions that the realm permits and exposes while
/// preserving catalog loading and failure states for asynchronous consumers.

final class AvailableElementDefinitionsFutureProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ElementDefinition>>,
          List<ElementDefinition>,
          FutureOr<List<ElementDefinition>>
        >
    with
        $FutureModifier<List<ElementDefinition>>,
        $FutureProvider<List<ElementDefinition>> {
  /// Returns discovered definitions that the realm permits and exposes while
  /// preserving catalog loading and failure states for asynchronous consumers.
  AvailableElementDefinitionsFutureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableElementDefinitionsFutureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$availableElementDefinitionsFutureHash();

  @$internal
  @override
  $FutureProviderElement<List<ElementDefinition>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ElementDefinition>> create(Ref ref) {
    return availableElementDefinitionsFuture(ref);
  }
}

String _$availableElementDefinitionsFutureHash() =>
    r'40fce74ea30e60920eb7cb205e1dde2e667d5c00';

/// Returns the latest available element definitions for synchronous consumers.

@ProviderFor(availableElementDefinitions)
final availableElementDefinitionsProvider =
    AvailableElementDefinitionsProvider._();

/// Returns the latest available element definitions for synchronous consumers.

final class AvailableElementDefinitionsProvider
    extends
        $FunctionalProvider<
          List<ElementDefinition>,
          List<ElementDefinition>,
          List<ElementDefinition>
        >
    with $Provider<List<ElementDefinition>> {
  /// Returns the latest available element definitions for synchronous consumers.
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
    r'f1fe88e5b82cf47993d012344876f8bc4b93efb9';
