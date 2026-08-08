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

String _$realmIdHash() => r'b5a53b8148bc725c81264d33431670fd5da2a607';

@ProviderFor(selectedRealm)
final selectedRealmProvider = SelectedRealmProvider._();

final class SelectedRealmProvider
    extends
        $FunctionalProvider<AsyncValue<Service?>, Service?, FutureOr<Service?>>
    with $FutureModifier<Service?>, $FutureProvider<Service?> {
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
  $FutureProviderElement<Service?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Service?> create(Ref ref) {
    return selectedRealm(ref);
  }
}

String _$selectedRealmHash() => r'52c7cdbcd54e832ff7316e07bad84f4ec27c9a32';

@ProviderFor(realms)
final realmsProvider = RealmsProvider._();

final class RealmsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Service>>,
          List<Service>,
          FutureOr<List<Service>>
        >
    with $FutureModifier<List<Service>>, $FutureProvider<List<Service>> {
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
  $FutureProviderElement<List<Service>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Service>> create(Ref ref) {
    return realms(ref);
  }
}

String _$realmsHash() => r'ed7e28e4f95f33cf44d5e3ea8d82d914c9796313';

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

String _$realmConnectionHash() => r'03fd58db72aa6a5bcb5647e9c97821de9590dd36';

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
