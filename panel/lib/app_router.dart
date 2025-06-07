import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/routes/auth/route.dart";
import "package:typewriter_panel/routes/organization/library/route.dart";
import "package:typewriter_panel/routes/organization/route.dart";
import "package:typewriter_panel/routes/route.dart";

part "app_router.g.dart";
part "app_router.gr.dart";

@Riverpod(keepAlive: true)
Raw<AppRouter> appRouter(Ref ref) => AppRouter(ref);

@AutoRouterConfig(replaceInRouteName: "Page,Route")
class AppRouter extends RootStackRouter {
  AppRouter(this.ref);

  final Ref ref;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: AuthRoute.page,
          path: "/auth",
          keepHistory: false,
          maintainState: false,
        ),
        AutoRoute(
          page: IndexRoute.page,
          path: "/",
          initial: true,
          guards: [AuthGuard(ref)],
          children: [
            AutoRoute(
              page: OrganizationRoute.page,
              path: "organization/:organizationId",
              children: [
                RedirectRoute(path: "", redirectTo: LibraryRoute.name),
                AutoRoute(
                  page: LibraryRoute.page,
                  path: "library",
                  initial: true,
                ),
              ],
            ),
          ],
        ),
      ];
}

class AuthGuard extends AutoRouteGuard {
  const AuthGuard(this.ref);
  final Ref ref;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final isAuthenticated = ref.read(isAuthenticatedProvider).requireValue;
    debugPrint("AuthGuard: isAuthenticated: $isAuthenticated");

    if (isAuthenticated) {
      resolver.next();
      return;
    }

    resolver.redirectUntil(
      AuthRoute(
        onResult: (isAuthenticated) {
          resolver.next(isAuthenticated);
        },
      ),
    );
  }
}

class InvalidatorNavigatorObserver extends NavigatorObserver {
  InvalidatorNavigatorObserver(this.invalidator);
  final void Function() invalidator;

  @override
  void didPop(Route route, Route? previousRoute) => invalidator();

  @override
  void didPush(Route route, Route? previousRoute) => invalidator();

  @override
  void didRemove(Route route, Route? previousRoute) => invalidator();

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => invalidator();
}

/// Provides the current route data for the given [name].
@Riverpod(keepAlive: true)
RouteData? currentRouteData(Ref ref, String path) {
  final router = ref.watch(appRouterProvider);
  return _fetchCurrentRouteData(path, router);
}

/// Fetch a nested route from the current route.
RouteData? _fetchCurrentRouteData(String name, RoutingController controller) {
  if (controller.current.name == name) {
    return controller.current;
  }
  final child = controller.innerRouterOf(controller.current.name);
  return child != null ? _fetchCurrentRouteData(name, child) : null;
}
