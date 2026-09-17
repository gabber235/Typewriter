// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the current user's organization list projection.
///
/// The provider combines an initial snapshot with ordered change events. A
/// duplicate event is ignored, an ordered event updates the projection, and a
/// sequence gap invalidates the stream so the server snapshot can re establish
/// authority. Mutations apply their returned event immediately, avoiding a
/// second request while preserving the same sequence rules.

@ProviderFor(Organizations)
final organizationsProvider = OrganizationsProvider._();

/// Owns the current user's organization list projection.
///
/// The provider combines an initial snapshot with ordered change events. A
/// duplicate event is ignored, an ordered event updates the projection, and a
/// sequence gap invalidates the stream so the server snapshot can re establish
/// authority. Mutations apply their returned event immediately, avoiding a
/// second request while preserving the same sequence rules.
final class OrganizationsProvider
    extends $StreamNotifierProvider<Organizations, List<OrganizationData>> {
  /// Owns the current user's organization list projection.
  ///
  /// The provider combines an initial snapshot with ordered change events. A
  /// duplicate event is ignored, an ordered event updates the projection, and a
  /// sequence gap invalidates the stream so the server snapshot can re establish
  /// authority. Mutations apply their returned event immediately, avoiding a
  /// second request while preserving the same sequence rules.
  OrganizationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationsHash();

  @$internal
  @override
  Organizations create() => Organizations();
}

String _$organizationsHash() => r'cee411b116915b0b6e4da21ef292d6a4b640f7ec';

/// Owns the current user's organization list projection.
///
/// The provider combines an initial snapshot with ordered change events. A
/// duplicate event is ignored, an ordered event updates the projection, and a
/// sequence gap invalidates the stream so the server snapshot can re establish
/// authority. Mutations apply their returned event immediately, avoiding a
/// second request while preserving the same sequence rules.

abstract class _$Organizations extends $StreamNotifier<List<OrganizationData>> {
  Stream<List<OrganizationData>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<OrganizationData>>, List<OrganizationData>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<OrganizationData>>,
                List<OrganizationData>
              >,
              AsyncValue<List<OrganizationData>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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

String _$organizationIdHash() => r'9902444ecead9e5ebb83f436a847d913ff97d987';

/// Selects the routed organization from the user's canonical organization list.
///
/// This is a read projection, not a second organization cache. It stays null
/// until the route has an identity or the membership stream contains that
/// identity, which prevents nested pages from using stale organization data.

@ProviderFor(Organization)
final organizationProvider = OrganizationProvider._();

/// Selects the routed organization from the user's canonical organization list.
///
/// This is a read projection, not a second organization cache. It stays null
/// until the route has an identity or the membership stream contains that
/// identity, which prevents nested pages from using stale organization data.
final class OrganizationProvider
    extends $AsyncNotifierProvider<Organization, OrganizationData?> {
  /// Selects the routed organization from the user's canonical organization list.
  ///
  /// This is a read projection, not a second organization cache. It stays null
  /// until the route has an identity or the membership stream contains that
  /// identity, which prevents nested pages from using stale organization data.
  OrganizationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizationHash();

  @$internal
  @override
  Organization create() => Organization();
}

String _$organizationHash() => r'45b1ea19bda17c75a1327fff03857ac4732f2038';

/// Selects the routed organization from the user's canonical organization list.
///
/// This is a read projection, not a second organization cache. It stays null
/// until the route has an identity or the membership stream contains that
/// identity, which prevents nested pages from using stale organization data.

abstract class _$Organization extends $AsyncNotifier<OrganizationData?> {
  FutureOr<OrganizationData?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OrganizationData?>, OrganizationData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OrganizationData?>, OrganizationData?>,
              AsyncValue<OrganizationData?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
