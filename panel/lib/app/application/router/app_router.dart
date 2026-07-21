import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
      guards: [UnAuthGuard(ref)],
    ),
    AutoRoute(page: IndexRoute.page, path: "/", guards: [AuthGuard(ref)]),
    AutoRoute(
      page: OrganizationRoute.page,
      path: "/organization/:organizationId",
      // TODO: Add guard that organizationId exists and user has access to it.
      guards: [AuthGuard(ref)],
      children: [
        AutoRoute(page: ServicesRoute.page, path: "services", initial: true),
        AutoRoute(
          page: MembersRoute.page,
          path: "members",
          children: [
            AutoRoute(page: MemberListRoute.page, path: "", initial: true),
            AutoRoute(page: JoinRequestsRoute.page, path: "join-requests"),
            AutoRoute(page: JoinCodesRoute.page, path: "join-codes"),
          ],
        ),
        AutoRoute(
          page: RealmRoute.page,
          path: "realm/:realmId",
          // TODO: Add guard that organizationId and realmId exist and user has access to it.
          guards: [AuthGuard(ref)],
          children: [
            AutoRoute(page: LibraryRoute.page, path: "library", initial: true),
            AutoRoute(page: TagsRoute.page, path: "tags"),
          ],
        ),
      ],
    ),
    AutoRoute(
      page: BookRoute.page,
      path: "/organization/:organizationId/realm/:realmId/book/:bookId",
      // TODO: Add guard that organizationId, realmId, and bookId exist and user has access to it.
      guards: [AuthGuard(ref)],
      children: [AutoRoute(page: RouteRoute.page, path: "page/:pageId")],
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

class UnAuthGuard extends AutoRouteGuard {
  const UnAuthGuard(this.ref);
  final Ref ref;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final isAuthenticated = ref.read(isAuthenticatedProvider).requireValue;
    debugPrint("UnAuthGuard: isAuthenticated: $isAuthenticated");

    if (!isAuthenticated) {
      resolver.next();
      return;
    }

    resolver
      ..overrideNext(children: [IndexRoute()])
      ..next();
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

class LoggerNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint(
      "NavigatorObserver: didPop '${previousRoute?.display}' -> ${route.display}",
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint(
      "NavigatorObserver: didPush '${previousRoute?.display}' -> ${route.display}",
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    debugPrint(
      "NavigatorObserver: didRemove '${previousRoute?.display}' -> ${route.display}",
    );
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    debugPrint(
      "NavigatorObserver: didReplace '${oldRoute?.display}' -> ${newRoute?.display}",
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

extension RouteExtensions on Route {
  String get display {
    final route = data;
    if (route == null) return "null";
    final params = route.params.rawMap.entries
        .map((e) => "${e.key}: ${e.value}")
        .join(", ");
    return "${route.name}($params)";
  }
}

@riverpod
class CurrentRoute extends _$CurrentRoute {
  @override
  String build() {
    final router = ref.watch(appRouterProvider);
    return router.currentPath;
  }
}

@riverpod
String? routeParam(Ref ref, String id) {
  final router = ref.watch(appRouterProvider);
  final params = router.topRoute.inheritedPathParams;
  return params.optString(id);
}
