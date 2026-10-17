// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_route_access_binding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Combines principal and membership observations into one binding snapshot.
///
/// Keeping the observations together makes a session change one coherent
/// route access update rather than two independently ordered callbacks.

@ProviderFor(_organizationAccessSnapshot)
final _organizationAccessSnapshotProvider =
    _OrganizationAccessSnapshotProvider._();

/// Combines principal and membership observations into one binding snapshot.
///
/// Keeping the observations together makes a session change one coherent
/// route access update rather than two independently ordered callbacks.

final class _OrganizationAccessSnapshotProvider
    extends
        $FunctionalProvider<
          _OrganizationAccessSnapshot,
          _OrganizationAccessSnapshot,
          _OrganizationAccessSnapshot
        >
    with $Provider<_OrganizationAccessSnapshot> {
  /// Combines principal and membership observations into one binding snapshot.
  ///
  /// Keeping the observations together makes a session change one coherent
  /// route access update rather than two independently ordered callbacks.
  _OrganizationAccessSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_organizationAccessSnapshotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_organizationAccessSnapshotHash();

  @$internal
  @override
  $ProviderElement<_OrganizationAccessSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  _OrganizationAccessSnapshot create(Ref ref) {
    return _organizationAccessSnapshot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(_OrganizationAccessSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<_OrganizationAccessSnapshot>(value),
    );
  }
}

String _$_organizationAccessSnapshotHash() =>
    r'8f6f84251d5dc19f5a197cd2b95ca7192f1646a6';
