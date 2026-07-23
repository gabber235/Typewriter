import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/access/organization_route_access.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/application.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

typedef _OrganizationAccessSnapshot = ({
  AsyncValue<String?> principal,
  AsyncValue<List<OrganizationData>> membership,
});

final _organizationAccessSnapshotProvider =
    Provider<_OrganizationAccessSnapshot>(
      (ref) => (
        principal: ref.watch(userIdProvider),
        membership: ref.watch(organizationsProvider),
      ),
    );

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
