import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app/application/router/access/authentication_route_access.dart";
import "package:typewriter_panel/app/application/router/access/organization_route_access.dart";
import "package:typewriter_panel/app/application/router/access/route_access_coordinator.dart";
import "package:typewriter_panel/app/application/router/route_reevaluation_coordinator.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "app_router.g.dart";
part "app_router.gr.dart";
part "guards/auth_guard.dart";
part "guards/organization_guard.dart";
part "organization_access_redirect.dart";

@Riverpod(keepAlive: true)
Raw<AppRouter> appRouter(Ref ref) {
  final access = RouteAccessCoordinator(
    authentication: AuthenticationRouteAccess(),
    organizations: OrganizationRouteAccess(),
  );
  final router = AppRouter(access);
  final reevaluation = RouteReevaluationCoordinator(
    access: access,
    reevaluateGuards: router.reevaluateGuards,
  );
  ref.onDispose(() {
    reevaluation.dispose();
    access.dispose();
  });
  return router;
}

@AutoRouterConfig(replaceInRouteName: "Page,Route")
class AppRouter extends RootStackRouter {
  AppRouter(this.access)
    : _authGuard = _AuthGuard(access.authentication),
      _unAuthGuard = _UnAuthGuard(
        access.authentication,
        _IndexRedirectCoordinator(),
      ),
      _organizationGuard = _OrganizationGuard(
        access.organizations,
        _IndexRedirectCoordinator(),
      );

  final RouteAccessCoordinator access;
  final _AuthGuard _authGuard;
  final _UnAuthGuard _unAuthGuard;
  final _OrganizationGuard _organizationGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: AuthRoute.page,
      path: "/auth",
      keepHistory: false,
      maintainState: false,
      guards: [_unAuthGuard],
    ),
    AutoRoute(page: IndexRoute.page, path: "/", guards: [_authGuard]),
    AutoRoute(
      page: OrganizationRoute.page,
      path: "/organization/:organizationId",
      // TODO: Validate scoped resource existence and finer-grained access.
      guards: [_authGuard, _organizationGuard],
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
          guards: [_authGuard],
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
      // TODO: Validate realm/book existence and finer-grained book access.
      guards: [_authGuard, _organizationGuard],
      children: [AutoRoute(page: RouteRoute.page, path: "page/:pageId")],
    ),
  ];
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
