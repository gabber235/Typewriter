// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_scope.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the organization route parameter into the typed record identity.
///
/// A missing route parameter yields null. No provider fabricates an organization
/// identity, so nested organization consumers can distinguish an absent route
/// from a missing membership projection.

@ProviderFor(organizationId)
final organizationIdProvider = OrganizationIdProvider._();

/// Resolves the organization route parameter into the typed record identity.
///
/// A missing route parameter yields null. No provider fabricates an organization
/// identity, so nested organization consumers can distinguish an absent route
/// from a missing membership projection.

final class OrganizationIdProvider
    extends $FunctionalProvider<skir.RecordId?, skir.RecordId?, skir.RecordId?>
    with $Provider<skir.RecordId?> {
  /// Resolves the organization route parameter into the typed record identity.
  ///
  /// A missing route parameter yields null. No provider fabricates an organization
  /// identity, so nested organization consumers can distinguish an absent route
  /// from a missing membership projection.
  OrganizationIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationIdHash();

  @$internal
  @override
  $ProviderElement<skir.RecordId?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  skir.RecordId? create(Ref ref) {
    return organizationId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(skir.RecordId? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<skir.RecordId?>(value),
    );
  }
}

String _$organizationIdHash() => r'7eb63d4df0d5163bd3cd75644fc63f619087e550';
