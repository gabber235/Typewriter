// GENERATED CODE. DO NOT MODIFY BY HAND

part of 'authoring_resource_navigation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE. DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authoringResourceNavigationRegistry)
final authoringResourceNavigationRegistryProvider =
    AuthoringResourceNavigationRegistryProvider._();

final class AuthoringResourceNavigationRegistryProvider
    extends
        $FunctionalProvider<
          AuthoringResourceNavigationRegistry,
          AuthoringResourceNavigationRegistry,
          AuthoringResourceNavigationRegistry
        >
    with $Provider<AuthoringResourceNavigationRegistry> {
  AuthoringResourceNavigationRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authoringResourceNavigationRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$authoringResourceNavigationRegistryHash();

  @$internal
  @override
  $ProviderElement<AuthoringResourceNavigationRegistry> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthoringResourceNavigationRegistry create(Ref ref) {
    return authoringResourceNavigationRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthoringResourceNavigationRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthoringResourceNavigationRegistry>(
        value,
      ),
    );
  }
}

String _$authoringResourceNavigationRegistryHash() =>
    r'3e3263179712ef51f0bccf5f518d8982bf67b913';

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

@ProviderFor(resourceOperationNavigation)
final resourceOperationNavigationProvider =
    ResourceOperationNavigationProvider._();

final class ResourceOperationNavigationProvider
    extends
        $FunctionalProvider<
          ResourceOperationNavigation,
          ResourceOperationNavigation,
          ResourceOperationNavigation
        >
    with $Provider<ResourceOperationNavigation> {
  ResourceOperationNavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourceOperationNavigationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourceOperationNavigationHash();

  @$internal
  @override
  $ProviderElement<ResourceOperationNavigation> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResourceOperationNavigation create(Ref ref) {
    return resourceOperationNavigation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourceOperationNavigation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourceOperationNavigation>(value),
    );
  }
}

String _$resourceOperationNavigationHash() =>
    r'b38133298af2033d336ff084812d6feac3d15b84';
