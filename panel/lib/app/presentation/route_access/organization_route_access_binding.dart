import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/access/access.dart";
import "package:typewriter_panel/features/auth/application/application.dart";
import "package:typewriter_panel/features/organizations/application/application.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

part "organization_route_access_binding.freezed.dart";

@freezed
abstract class _OrganizationAccessSnapshot with _$OrganizationAccessSnapshot {
  const factory _OrganizationAccessSnapshot({
    required AsyncValue<String?> principal,
    required AsyncValue<List<OrganizationData>> membership,
  }) = __OrganizationAccessSnapshot;
}

/// Combines principal and membership observations into one binding snapshot.
///
/// Keeping the observations together makes a session change one coherent
/// route access update rather than two independently ordered callbacks.
final _organizationAccessSnapshotProvider =
    Provider<_OrganizationAccessSnapshot>(
      (ref) => _OrganizationAccessSnapshot(
        principal: ref.watch(userIdProvider),
        membership: ref.watch(organizationsProvider),
      ),
    );

/// Mirrors principal and organization membership providers into [access].
///
/// The combined subscription fires immediately and on either dependency's
/// change. [organizationRouteAccessState] intentionally reports loading or
/// unavailable before exposing retained membership data.
ProviderSubscription<Object?> bindOrganizationRouteAccess(
  WidgetRef ref,
  OrganizationRouteAccess access,
) => ref.listenManual<_OrganizationAccessSnapshot>(
  _organizationAccessSnapshotProvider,
  (_, next) => access.setState(
    organizationRouteAccessState(next.principal, next.membership),
  ),
  fireImmediately: true,
);

/// Converts principal and membership observations into route access state.
///
/// A loading or failed principal blocks membership decisions. Membership IDs
/// are reduced to a set because guards only need membership lookup, not the
/// provider's organization presentation model.
OrganizationRouteAccessState organizationRouteAccessState(
  AsyncValue<String?> principal,
  AsyncValue<List<OrganizationData>> membership,
) {
  if (principal.isLoading) {
    return const OrganizationRouteAccessState.loading();
  }
  if (principal.hasError) {
    return const OrganizationRouteAccessState.unavailable();
  }
  if (membership.isLoading) {
    return const OrganizationRouteAccessState.loading();
  }
  if (membership.hasError) {
    return const OrganizationRouteAccessState.unavailable();
  }
  return OrganizationRouteAccessState.available(
    principalId: principal.requireValue,
    organizationIds: {
      for (final organization in membership.requireValue)
        organization.organizationId.id,
    },
  );
}
