import "package:typewriter_panel/typewriter_panel.dart";

part "navigation.g.dart";

/// The router as code below the app sees it: auto_route's stack plus the
/// revision that pending navigation work checks.
///
/// AppRouter extends it. Destinations and navigation runners hold it instead of
/// the application router, so they do not depend on the app's route tree.
abstract class NavigationRouter extends RootStackRouter {
  /// Changes when a new route command supersedes pending navigation work.
  int get navigationRevision;

  /// Navigates to [route] once leaving the current work scope is admitted.
  ///
  /// [isCurrent] is checked after admission; when it returns false the
  /// request is abandoned because the work that asked for it is stale.
  @override
  Future<dynamic> navigate(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool Function()? isCurrent,
  });
}

/// The application router for code below the app.
///
/// The app installs it through appOverrides; reading it without the app is a
/// wiring error.
@Riverpod(keepAlive: true)
Raw<NavigationRouter> navigationRouter(Ref ref) => throw UnimplementedError(
  "navigationRouterProvider is installed by appOverrides",
);

/// Exposes the router's current path as reactive application state.
@riverpod
class CurrentRoute extends _$CurrentRoute {
  @override
  String build() {
    final router = ref.watch(navigationRouterProvider);
    return router.currentPath;
  }
}

/// Reads a path parameter from the router's active route chain, the nearest
/// route that declares it winning.
///
/// The chain is read instead of the top route's inherited parameters: when a
/// navigation updates an existing parent route in place, such as switching
/// organization, the child route keeps the parameters it inherited before.
/// Until the child router applies them, the parent's pending children stand in
/// for the shown ones, so parameters never pair two scopes.
///
/// Such an in place update pushes no page, so the navigator observers that
/// invalidate route state never hear of it; the provider follows the router
/// itself and rebuilds once the parameter changed.
///
/// A missing parameter returns null. Consumers use this provider for route
/// scoped resource lookup and should handle that absence before constructing an
/// identifier.
@Riverpod(keepAlive: true)
String? routeParam(Ref ref, String id) {
  final router = ref.watch(navigationRouterProvider);
  String? read() {
    final params = <String, dynamic>{};
    RoutingController? controller = router;
    while (controller != null) {
      final route = controller.currentChild;
      if (route == null) break;
      params.addAll(route.params.rawMap);
      // Children an in place update has yet to apply replace the ones still
      // shown, whose parameters belong to the previous parent.
      if (route.hasPendingChildren) {
        for (final pending in route.pendingChildren.last.flattened) {
          params.addAll(pending.params.rawMap);
        }
        break;
      }
      controller = controller.innerRouterOf<RoutingController>(route.name);
    }
    return Parameters(params).optString(id);
  }

  final value = read();
  void follow() {
    if (read() != value) ref.invalidateSelf();
  }

  router.addListener(follow);
  ref.onDispose(() => router.removeListener(follow));
  return value;
}
