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

/// Reads an inherited path parameter from the router's active top route.
///
/// A missing parameter returns null. Consumers use this provider for route
/// scoped resource lookup and should handle that absence before constructing an
/// identifier.
@riverpod
String? routeParam(Ref ref, String id) {
  final router = ref.watch(navigationRouterProvider);
  final params = router.topRoute.inheritedPathParams;
  return params.optString(id);
}
