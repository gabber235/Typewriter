import "package:typewriter_panel/typewriter_panel.dart";

/// The realm feature's route tree as authoring navigates it.
///
/// A realm lives below its organization's route; its home and resource pages
/// are the realm route's children.
final class RealmRouteTree implements RealmRoutes {
  const RealmRouteTree();

  @override
  PageRouteInfo<Object?> realm(AuthoringScope scope) => OrganizationRoute(
    organizationId: scope.organizationId.id,
    children: [RealmRoute(realmId: scope.realmId.id)],
  );

  @override
  PageRouteInfo<Object?> surface(AuthoringScope scope, SurfaceTarget target) =>
      OrganizationRoute(
        organizationId: scope.organizationId.id,
        children: [
          RealmRoute(
            realmId: scope.realmId.id,
            children: [
              switch (target) {
                HomeTarget() => const RealmHomeRoute(),
                ResourceTarget(:final routed) => ResourceRoute(
                  resourceId: routed.value,
                ),
              },
            ],
          ),
        ],
      );
}
