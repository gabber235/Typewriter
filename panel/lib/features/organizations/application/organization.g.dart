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
    extends $StreamNotifierProvider<Organizations, List<skir.Organization>> {
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

String _$organizationsHash() => r'4fdfc782308cb8e6eda04399426dbccb514cad96';

/// Owns the current user's organization list projection.
///
/// The provider combines an initial snapshot with ordered change events. A
/// duplicate event is ignored, an ordered event updates the projection, and a
/// sequence gap invalidates the stream so the server snapshot can re establish
/// authority. Mutations apply their returned event immediately, avoiding a
/// second request while preserving the same sequence rules.

abstract class _$Organizations
    extends $StreamNotifier<List<skir.Organization>> {
  Stream<List<skir.Organization>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<skir.Organization>>,
              List<skir.Organization>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<skir.Organization>>,
                List<skir.Organization>
              >,
              AsyncValue<List<skir.Organization>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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
    extends $AsyncNotifierProvider<Organization, skir.Organization?> {
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

String _$organizationHash() => r'd4cda6e0dfe3677f2e7f8da86e9848e23c4308df';

/// Selects the routed organization from the user's canonical organization list.
///
/// This is a read projection, not a second organization cache. It stays null
/// until the route has an identity or the membership stream contains that
/// identity, which prevents nested pages from using stale organization data.

abstract class _$Organization extends $AsyncNotifier<skir.Organization?> {
  FutureOr<skir.Organization?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<skir.Organization?>, skir.Organization?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<skir.Organization?>, skir.Organization?>,
              AsyncValue<skir.Organization?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
