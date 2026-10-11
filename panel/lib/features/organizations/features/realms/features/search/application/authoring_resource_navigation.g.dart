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
    r'4591c3075b662a59d4f2b2d7e7d611074320c367';
