// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(realmId)
final realmIdProvider = RealmIdProvider._();

final class RealmIdProvider
    extends $FunctionalProvider<skir.RecordId?, skir.RecordId?, skir.RecordId?>
    with $Provider<skir.RecordId?> {
  RealmIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmIdHash();

  @$internal
  @override
  $ProviderElement<skir.RecordId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.RecordId? create(Ref ref) {
    return realmId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.RecordId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.RecordId?>(value),
    );
  }
}

String _$realmIdHash() => r'ffb152dbb33d651fc8a22b7ec72cdcb852832b60';

@ProviderFor(selectedRealm)
final selectedRealmProvider = SelectedRealmProvider._();

final class SelectedRealmProvider
    extends
        $FunctionalProvider<
          AsyncValue<TopologyRealm?>,
          TopologyRealm?,
          FutureOr<TopologyRealm?>
        >
    with $FutureModifier<TopologyRealm?>, $FutureProvider<TopologyRealm?> {
  SelectedRealmProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedRealmProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedRealmHash();

  @$internal
  @override
  $FutureProviderElement<TopologyRealm?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TopologyRealm?> create(Ref ref) {
    return selectedRealm(ref);
  }
}

String _$selectedRealmHash() => r'c519620c0a77a2ee3ece7e8496937fb6a3d5ca59';

@ProviderFor(realms)
final realmsProvider = RealmsProvider._();

final class RealmsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TopologyRealm>>,
          List<TopologyRealm>,
          FutureOr<List<TopologyRealm>>
        >
    with
        $FutureModifier<List<TopologyRealm>>,
        $FutureProvider<List<TopologyRealm>> {
  RealmsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmsHash();

  @$internal
  @override
  $FutureProviderElement<List<TopologyRealm>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TopologyRealm>> create(Ref ref) {
    return realms(ref);
  }
}

String _$realmsHash() => r'a6a67271ad2071acc9794999988313a29132975d';

@ProviderFor(realmConnection)
final realmConnectionProvider = RealmConnectionProvider._();

final class RealmConnectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<RealmConnectionState>,
          RealmConnectionState,
          Stream<RealmConnectionState>
        >
    with
        $FutureModifier<RealmConnectionState>,
        $StreamProvider<RealmConnectionState> {
  RealmConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmConnectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmConnectionHash();

  @$internal
  @override
  $StreamProviderElement<RealmConnectionState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RealmConnectionState> create(Ref ref) {
    return realmConnection(ref);
  }
}

String _$realmConnectionHash() => r'9f88d82c3bc14249fa4a14555d9bc978ec857615';

@ProviderFor(realmInteraction)
final realmInteractionProvider = RealmInteractionProvider._();

final class RealmInteractionProvider
    extends
        $FunctionalProvider<
          RealmInteractionState,
          RealmInteractionState,
          RealmInteractionState
        >
    with $Provider<RealmInteractionState> {
  RealmInteractionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmInteractionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmInteractionHash();

  @$internal
  @override
  $ProviderElement<RealmInteractionState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RealmInteractionState create(Ref ref) {
    return realmInteraction(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmInteractionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmInteractionState>(value),
    );
  }
}

String _$realmInteractionHash() => r'c5ab3f670a6f9d86721d1555509b4ca8239b6b85';
