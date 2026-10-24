// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_routes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The realm routes for authoring.
///
/// The app installs the realms feature's routes through appOverrides; reading
/// it without the app is a wiring error.

@ProviderFor(realmRoutes)
final realmRoutesProvider = RealmRoutesProvider._();

/// The realm routes for authoring.
///
/// The app installs the realms feature's routes through appOverrides; reading
/// it without the app is a wiring error.

final class RealmRoutesProvider
    extends $FunctionalProvider<RealmRoutes, RealmRoutes, RealmRoutes>
    with $Provider<RealmRoutes> {
  /// The realm routes for authoring.
  ///
  /// The app installs the realms feature's routes through appOverrides; reading
  /// it without the app is a wiring error.
  RealmRoutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realmRoutesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realmRoutesHash();

  @$internal
  @override
  $ProviderElement<RealmRoutes> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RealmRoutes create(Ref ref) {
    return realmRoutes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RealmRoutes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RealmRoutes>(value),
    );
  }
}

String _$realmRoutesHash() => r'ce0cba9467929b7638bcfee0e63369d7f8b1df97';
