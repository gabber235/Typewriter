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

/// Owns the catalog cache while the selected realm is online. Connection
/// resolution remains pending instead of publishing a disconnected cache.

@ProviderFor(realmEditorCatalogCache)
final realmEditorCatalogCacheProvider = RealmEditorCatalogCacheProvider._();

/// Owns the catalog cache while the selected realm is online. Connection
/// resolution remains pending instead of publishing a disconnected cache.

final class RealmEditorCatalogCacheProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmEditorCatalogCache?>,
          RealmEditorCatalogCache?,
          FutureOr<RealmEditorCatalogCache?>
        >
    with
        $FutureModifier<RealmEditorCatalogCache?>,
        $FutureProvider<RealmEditorCatalogCache?> {
  /// Owns the catalog cache while the selected realm is online. Connection
  /// resolution remains pending instead of publishing a disconnected cache.
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
  $FutureProviderElement<RealmEditorCatalogCache?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RealmEditorCatalogCache?> create(Ref ref) {
    return realmEditorCatalogCache(ref);
  }
}

String _$realmEditorCatalogCacheHash() =>
    r'c0963ff43517e42763465a8e5a4b2e56b1ac5321';

/// A request owns its cache lease and publishes only snapshots fetched with
/// enough coverage. Cache loading remains Riverpod loading; cache failure is a
/// typed Riverpod error and can recover on a later cache update.

@ProviderFor(RealmCatalog)
final realmCatalogProvider = RealmCatalogFamily._();

/// A request owns its cache lease and publishes only snapshots fetched with
/// enough coverage. Cache loading remains Riverpod loading; cache failure is a
/// typed Riverpod error and can recover on a later cache update.
final class RealmCatalogProvider
    extends $AsyncNotifierProvider<RealmCatalog, RealmEditorCatalogSnapshot> {
  /// A request owns its cache lease and publishes only snapshots fetched with
  /// enough coverage. Cache loading remains Riverpod loading; cache failure is a
  /// typed Riverpod error and can recover on a later cache update.
  RealmCatalogProvider._({
    required RealmCatalogFamily super.from,
    required RealmEditorCatalogRequest super.argument,
  }) : super(
         retry: null,
         name: r'realmCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmCatalogHash();

  @override
  String toString() {
    return r'realmCatalogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RealmCatalog create() => RealmCatalog();

  @override
  bool operator ==(Object other) {
    return other is RealmCatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmCatalogHash() => r'fe4b0ca469ec44607537dd1027e7025320e38740';

/// A request owns its cache lease and publishes only snapshots fetched with
/// enough coverage. Cache loading remains Riverpod loading; cache failure is a
/// typed Riverpod error and can recover on a later cache update.

final class RealmCatalogFamily extends $Family
    with
        $ClassFamilyOverride<
          RealmCatalog,
          AsyncValue<RealmEditorCatalogSnapshot>,
          RealmEditorCatalogSnapshot,
          FutureOr<RealmEditorCatalogSnapshot>,
          RealmEditorCatalogRequest
        > {
  RealmCatalogFamily._()
    : super(
        retry: null,
        name: r'realmCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A request owns its cache lease and publishes only snapshots fetched with
  /// enough coverage. Cache loading remains Riverpod loading; cache failure is a
  /// typed Riverpod error and can recover on a later cache update.

  RealmCatalogProvider call(RealmEditorCatalogRequest request) =>
      RealmCatalogProvider._(argument: request, from: this);

  @override
  String toString() => r'realmCatalogProvider';
}

/// A request owns its cache lease and publishes only snapshots fetched with
/// enough coverage. Cache loading remains Riverpod loading; cache failure is a
/// typed Riverpod error and can recover on a later cache update.

abstract class _$RealmCatalog
    extends $AsyncNotifier<RealmEditorCatalogSnapshot> {
  late final _$args = ref.$arg as RealmEditorCatalogRequest;
  RealmEditorCatalogRequest get request => _$args;

  FutureOr<RealmEditorCatalogSnapshot> build(RealmEditorCatalogRequest request);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<RealmEditorCatalogSnapshot>,
              RealmEditorCatalogSnapshot
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<RealmEditorCatalogSnapshot>,
                RealmEditorCatalogSnapshot
              >,
              AsyncValue<RealmEditorCatalogSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// The full catalog read uses the same readiness contract as scoped reads.

@ProviderFor(realmEditorCatalog)
final realmEditorCatalogProvider = RealmEditorCatalogProvider._();

/// The full catalog read uses the same readiness contract as scoped reads.

final class RealmEditorCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmEditorCatalogSnapshot>,
          RealmEditorCatalogSnapshot,
          FutureOr<RealmEditorCatalogSnapshot>
        >
    with
        $FutureModifier<RealmEditorCatalogSnapshot>,
        $FutureProvider<RealmEditorCatalogSnapshot> {
  /// The full catalog read uses the same readiness contract as scoped reads.
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
  $FutureProviderElement<RealmEditorCatalogSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RealmEditorCatalogSnapshot> create(Ref ref) {
    return realmEditorCatalog(ref);
  }
}

String _$realmEditorCatalogHash() =>
    r'610328e79a5f3ab860b34c4f594869e04f457100';

@ProviderFor(realmEditorCatalogForType)
final realmEditorCatalogForTypeProvider = RealmEditorCatalogForTypeFamily._();

final class RealmEditorCatalogForTypeProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmEditorCatalogSnapshot>,
          RealmEditorCatalogSnapshot,
          FutureOr<RealmEditorCatalogSnapshot>
        >
    with
        $FutureModifier<RealmEditorCatalogSnapshot>,
        $FutureProvider<RealmEditorCatalogSnapshot> {
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
  $FutureProviderElement<RealmEditorCatalogSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RealmEditorCatalogSnapshot> create(Ref ref) {
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
    r'db85324f2ce5afe659338a9604b14a4739369488';

final class RealmEditorCatalogForTypeFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<RealmEditorCatalogSnapshot>,
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

/// Returns page definitions from the latest complete realm catalog.

@ProviderFor(realmPageDefinitions)
final realmPageDefinitionsProvider = RealmPageDefinitionsProvider._();

/// Returns page definitions from the latest complete realm catalog.

final class RealmPageDefinitionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RealmTypeEntry>>,
          AsyncValue<List<RealmTypeEntry>>,
          AsyncValue<List<RealmTypeEntry>>
        >
    with $Provider<AsyncValue<List<RealmTypeEntry>>> {
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
  $ProviderElement<AsyncValue<List<RealmTypeEntry>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<RealmTypeEntry>> create(Ref ref) {
    return realmPageDefinitions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<RealmTypeEntry>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<RealmTypeEntry>>>(
        value,
      ),
    );
  }
}

String _$realmPageDefinitionsHash() =>
    r'05842649a4bf22dbe5de4beb02ce9ede0b0de12a';

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
    r'35503692f3d39d7972e63a2b8575e54cf5588ab5';
