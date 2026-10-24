// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_scope.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the route's realm parameter to the typed topology identifier.
///
/// A missing parameter deliberately remains `null`; it represents the
/// organization level route, not a failed lookup. Authoring reads it, so it
/// sits below authoring.

@ProviderFor(realmId)
final realmIdProvider = RealmIdProvider._();

/// Resolves the route's realm parameter to the typed topology identifier.
///
/// A missing parameter deliberately remains `null`; it represents the
/// organization level route, not a failed lookup. Authoring reads it, so it
/// sits below authoring.

final class RealmIdProvider
    extends $FunctionalProvider<skir.RecordId?, skir.RecordId?, skir.RecordId?>
    with $Provider<skir.RecordId?> {
  /// Resolves the route's realm parameter to the typed topology identifier.
  ///
  /// A missing parameter deliberately remains `null`; it represents the
  /// organization level route, not a failed lookup. Authoring reads it, so it
  /// sits below authoring.
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

String _$realmIdHash() => r'8107d153417198d64ff1502ee6bef9393e24bbe4';
