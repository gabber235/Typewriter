// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'realm_inbox.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(realmLocationReveal)
final realmLocationRevealProvider = RealmLocationRevealFamily._();

final class RealmLocationRevealProvider
    extends
        $FunctionalProvider<
          PortableLocationRevealController,
          PortableLocationRevealController,
          PortableLocationRevealController
        >
    with $Provider<PortableLocationRevealController> {
  RealmLocationRevealProvider._({
    required RealmLocationRevealFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmLocationRevealProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmLocationRevealHash();

  @override
  String toString() {
    return r'realmLocationRevealProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PortableLocationRevealController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PortableLocationRevealController create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmLocationReveal(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortableLocationRevealController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortableLocationRevealController>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmLocationRevealProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmLocationRevealHash() =>
    r'12337a2749f89b993e297662a60e96771307aabc';

final class RealmLocationRevealFamily extends $Family
    with
        $FunctionalFamilyOverride<
          PortableLocationRevealController,
          AuthoringScope
        > {
  RealmLocationRevealFamily._()
    : super(
        retry: null,
        name: r'realmLocationRevealProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealmLocationRevealProvider call(AuthoringScope scope) =>
      RealmLocationRevealProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmLocationRevealProvider';
}

/// Joins immutable observations from their existing owners without retaining work.

@ProviderFor(realmInbox)
final realmInboxProvider = RealmInboxFamily._();

/// Joins immutable observations from their existing owners without retaining work.

final class RealmInboxProvider
    extends
        $FunctionalProvider<RealmInboxState, RealmInboxState, RealmInboxState>
    with $Provider<RealmInboxState> {
  /// Joins immutable observations from their existing owners without retaining work.
  RealmInboxProvider._({
    required RealmInboxFamily super.from,
    required AuthoringScope super.argument,
  }) : super(
         retry: null,
         name: r'realmInboxProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realmInboxHash();

  @override
  String toString() {
    return r'realmInboxProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RealmInboxState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RealmInboxState create(Ref ref) {
    final argument = this.argument as AuthoringScope;
    return realmInbox(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmInboxState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmInboxState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RealmInboxProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realmInboxHash() => r'cbd7ec46c76fb9246d9e74160580ca8dd5bb28ea';

/// Joins immutable observations from their existing owners without retaining work.

final class RealmInboxFamily extends $Family
    with $FunctionalFamilyOverride<RealmInboxState, AuthoringScope> {
  RealmInboxFamily._()
    : super(
        retry: null,
        name: r'realmInboxProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Joins immutable observations from their existing owners without retaining work.

  RealmInboxProvider call(AuthoringScope scope) =>
      RealmInboxProvider._(argument: scope, from: this);

  @override
  String toString() => r'realmInboxProvider';
}

/// Reuses the resource navigation registry for inbox destinations.

@ProviderFor(openRealmInboxLocation)
final openRealmInboxLocationProvider = OpenRealmInboxLocationFamily._();

/// Reuses the resource navigation registry for inbox destinations.

final class OpenRealmInboxLocationProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Reuses the resource navigation registry for inbox destinations.
  OpenRealmInboxLocationProvider._({
    required OpenRealmInboxLocationFamily super.from,
    required (AuthoringScope, skir.ValueLocation) super.argument,
  }) : super(
         retry: null,
         name: r'openRealmInboxLocationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$openRealmInboxLocationHash();

  @override
  String toString() {
    return r'openRealmInboxLocationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (AuthoringScope, skir.ValueLocation);
    return openRealmInboxLocation(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is OpenRealmInboxLocationProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$openRealmInboxLocationHash() =>
    r'c934dc60b27f759ba05293f1e3b8528e7f3f30b4';

/// Reuses the resource navigation registry for inbox destinations.

final class OpenRealmInboxLocationFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<bool>,
          (AuthoringScope, skir.ValueLocation)
        > {
  OpenRealmInboxLocationFamily._()
    : super(
        retry: null,
        name: r'openRealmInboxLocationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reuses the resource navigation registry for inbox destinations.

  OpenRealmInboxLocationProvider call(
    AuthoringScope scope,
    skir.ValueLocation location,
  ) =>
      OpenRealmInboxLocationProvider._(argument: (scope, location), from: this);

  @override
  String toString() => r'openRealmInboxLocationProvider';
}
