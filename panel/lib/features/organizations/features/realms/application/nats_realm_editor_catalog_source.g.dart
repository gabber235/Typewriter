// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'nats_realm_editor_catalog_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(realmCatalogInvalidations)
final realmCatalogInvalidationsProvider = RealmCatalogInvalidationsFamily._();

final class RealmCatalogInvalidationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.CatalogInvalidated>,
          skir.CatalogInvalidated,
          Stream<skir.CatalogInvalidated>
        >
    with
        $FutureModifier<skir.CatalogInvalidated>,
        $StreamProvider<skir.CatalogInvalidated> {
  RealmCatalogInvalidationsProvider._({
    required RealmCatalogInvalidationsFamily super.from,
    required (skir.RecordId, skir.RecordId) super.argument,
  }) : super(
         retry: null,
         name: r'realmCatalogInvalidationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmCatalogInvalidationsHash();

  @override
  String toString() {
    return r'realmCatalogInvalidationsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<skir.CatalogInvalidated> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<skir.CatalogInvalidated> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId);
    return realmCatalogInvalidations(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is RealmCatalogInvalidationsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmCatalogInvalidationsHash() =>
    r'a38412fd87522b3b3985136e44b70b93c7de433c';

final class RealmCatalogInvalidationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<skir.CatalogInvalidated>,
          (skir.RecordId, skir.RecordId)
        > {
  RealmCatalogInvalidationsFamily._()
    : super(
        retry: null,
        name: r'realmCatalogInvalidationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmCatalogInvalidationsProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => RealmCatalogInvalidationsProvider._(
    argument: (organizationId, realmId),
    from: this,
  );

  @override
  String toString() => r'realmCatalogInvalidationsProvider';
}

@ProviderFor(realmCatalogTransfer)
final realmCatalogTransferProvider = RealmCatalogTransferFamily._();

final class RealmCatalogTransferProvider
    extends
        $FunctionalProvider<
          AsyncValue<skir.EditorCatalogWireSnapshot>,
          skir.EditorCatalogWireSnapshot,
          FutureOr<skir.EditorCatalogWireSnapshot>
        >
    with
        $FutureModifier<skir.EditorCatalogWireSnapshot>,
        $FutureProvider<skir.EditorCatalogWireSnapshot> {
  RealmCatalogTransferProvider._({
    required RealmCatalogTransferFamily super.from,
    required (skir.RecordId, skir.RecordId, String) super.argument,
  }) : super(
         retry: null,
         name: r'realmCatalogTransferProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmCatalogTransferHash();

  @override
  String toString() {
    return r'realmCatalogTransferProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<skir.EditorCatalogWireSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<skir.EditorCatalogWireSnapshot> create(Ref ref) {
    final argument = this.argument as (skir.RecordId, skir.RecordId, String);
    return realmCatalogTransfer(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is RealmCatalogTransferProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmCatalogTransferHash() =>
    r'0e71d278632e6ffc3108f758987d80075addc6d2';

final class RealmCatalogTransferFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<skir.EditorCatalogWireSnapshot>,
          (skir.RecordId, skir.RecordId, String)
        > {
  RealmCatalogTransferFamily._()
    : super(
        retry: null,
        name: r'realmCatalogTransferProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmCatalogTransferProvider call(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String fetchId,
  ) => RealmCatalogTransferProvider._(
    argument: (organizationId, realmId, fetchId),
    from: this,
  );

  @override
  String toString() => r'realmCatalogTransferProvider';
}
