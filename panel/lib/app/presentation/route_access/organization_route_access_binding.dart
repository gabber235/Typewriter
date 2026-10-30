import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Mirrors principal and organization membership providers into [access].
///
/// Both subscriptions publish one state built from the current value of both
/// providers. They listen to the providers themselves rather than to a
/// combined derived provider, which Riverpod would only recompute on its next
/// scheduled flush: a navigation that follows a membership mutation, such as
/// opening an organization right after creating it, must already see the new
/// membership. [organizationRouteAccessState] intentionally reports loading
/// or unavailable before exposing retained membership data.
List<ProviderSubscription<Object?>> bindOrganizationRouteAccess(
  WidgetRef ref,
  OrganizationRouteAccess access,
) {
  void publish() => access.setState(
    organizationRouteAccessState(
      ref.read(userIdProvider),
      ref.read(organizationsProvider),
    ),
  );
  return [
    ref.listenManual(userIdProvider, (_, _) => publish()),
    ref.listenManual(
      organizationsProvider,
      (_, _) => publish(),
      fireImmediately: true,
    ),
  ];
}

/// Converts principal and membership observations into route access state.
///
/// A loading or failed principal blocks membership decisions. Membership IDs
/// are reduced to a set because guards only need membership lookup, not the
/// provider's organization presentation model.
OrganizationRouteAccessState organizationRouteAccessState(
  AsyncValue<String?> principal,
  AsyncValue<List<skir.Organization>> membership,
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
