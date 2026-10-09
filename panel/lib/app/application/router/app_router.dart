import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "app_router.g.dart";
part "app_router.gr.dart";
part "guards/auth_guard.dart";
part "guards/organization_guard.dart";
part "guards/work_session_loss_guard.dart";
part "work_session_navigation.dart";
part "organization_access_redirect.dart";

typedef WorkSessionLossRouteConfirmation = Future<bool> Function(
  NavigationResolver resolver,
);
typedef WorkSessionLossPopConfirmation = Future<bool> Function();

/// Creates the process wide router and its route access owners.
///
/// The provider keeps one router for the application lifetime. Its disposal
/// order releases reevaluation first, then the access coordinator and its
/// modules, preventing callbacks from reaching disposed route state.
@Riverpod(keepAlive: true)
Raw<AppRouter> appRouter(Ref ref) {
  final access = RouteAccessCoordinator(
    authentication: AuthenticationRouteAccess(),
    organizations: OrganizationRouteAccess(),
  );
  final workSessionLoss = ref.watch(workSessionLossProvider);
  final router = AppRouter(access, workSessionLoss);
  final reevaluation = RouteReevaluationCoordinator(
    access: access,
    reevaluateGuards: router.reevaluateGuards,
  );
  ref.onDispose(() {
    reevaluation.dispose();
    router.dispose();
    access.dispose();
  });
  return router;
}

/// Defines the panel's route tree and the guards protecting each scope.
///
/// Authentication guards protect the public and private roots. The shared
/// organization guard protects organization and book routes, while nested realm
/// routes currently rely on the authenticated parent scope.
@AutoRouterConfig(replaceInRouteName: "Page,Route")
class AppRouter extends RootStackRouter {
  AppRouter(
    this.access,
    this.workSessionLoss, {
    WorkSessionLossRouteConfirmation? confirmWorkSessionLoss,
    this.confirmWorkSessionPop,
  }) : _authGuard = _AuthGuard(access.authentication),
       _unAuthGuard = _UnAuthGuard(
         access.authentication,
         _IndexRedirectCoordinator(),
       ),
       _organizationGuard = _OrganizationGuard(
         access.organizations,
         _IndexRedirectCoordinator(),
       ),
       _workSessionLossGuard = _WorkSessionLossGuard(
         access,
         workSessionLoss,
         confirmWorkSessionLoss ??
             (resolver) => showWorkSessionLossConfirmation(resolver.context),
       );

  final RouteAccessCoordinator access;
  final WorkSessionLossController workSessionLoss;
  final _AuthGuard _authGuard;
  final _UnAuthGuard _unAuthGuard;
  final _OrganizationGuard _organizationGuard;
  final _WorkSessionLossGuard _workSessionLossGuard;
  final WorkSessionLossPopConfirmation? confirmWorkSessionPop;

  @override
  List<AutoRouteGuard> get guards => [_workSessionLossGuard];

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    if (hasPagelessTopRoute) return super.maybePop(result);
    final observation = _WorkRouteObservation.capture(this);
    final destination = _scopeAfterPop();
    if (destination != null) {
      final current = workSessionLoss.currentScope;
      final allowed = await workSessionLoss.allowScopeLoss(
        destination: destination,
        forced: _scopeLossIsForced(access, current),
        confirm: _confirmPop,
      );
      if (!allowed || !observation.matches(this)) return true;
    }
    return super.maybePop(result);
  }

  LocalWorkScope? _scopeAfterPop() {
    if (stackData.length < 2) return null;
    final current = workSessionLoss.currentScope;
    final previous = stackData[stackData.length - 2];
    final organizationId = previous.inheritedPathParams.optString(
      "organizationId",
    );
    return current.copyWith(
      organizationId: organizationId == null
          ? null
          : skir.recordId("organization:$organizationId"),
    );
  }

  Future<bool> _confirmPop() {
    final supplied = confirmWorkSessionPop;
    if (supplied != null) return supplied();
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value(false);
    return showWorkSessionLossConfirmation(context);
  }

  AutoRouterDelegate? _workDelegate;
  bool _closed = false;

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    final delegate = _workDelegate;
    _workDelegate = null;
    delegate?.dispose();
    navigationHistory.dispose();
    super.dispose();
  }

  @override
  AutoRouterDelegate delegate({
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    DeepLinkBuilder? deepLinkBuilder,
    bool rebuildStackOnDeepLink = false,
    Listenable? reevaluateListenable,
    Clip clipBehavior = Clip.hardEdge,
  }) => _workDelegate ??= _WorkSessionRouterDelegate(
    this,
    navRestorationScopeId: navRestorationScopeId,
    placeholder: placeholder,
    navigatorObservers: navigatorObservers,
    deepLinkBuilder: deepLinkBuilder,
    rebuildStackOnDeepLink: rebuildStackOnDeepLink,
    reevaluateListenable: reevaluateListenable,
    clipBehavior: clipBehavior,
  );

  @override
  Future<dynamic> navigate(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) => _admitNavigation([
    matcher.matchByRoute(route),
  ], () => super.navigate(route, onFailure: onFailure));

  @override
  Future<void> navigateAll(
    List<RouteMatch> routes, {
    OnNavigationFailure? onFailure,
  }) async {
    await _admitNavigation(
      routes,
      () => super.navigateAll(routes, onFailure: onFailure),
    );
  }

  @override
  Future<void> navigatePath(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    await _admitNavigation(
      matcher.match(path, includePrefixMatches: includePrefixMatches) ?? [],
      () => super.navigatePath(
        path,
        includePrefixMatches: includePrefixMatches,
        onFailure: onFailure,
      ),
    );
  }

  @override
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) => _admitNavigation([
    matcher.matchByRoute(route),
  ], () => super.replace<T>(route, onFailure: onFailure));

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    await _admitNavigation(
      routes.map(matcher.matchByRoute).toList(),
      () => super.replaceAll(
        routes,
        onFailure: onFailure,
        updateExistingRoutes: updateExistingRoutes,
      ),
    );
  }

  @override
  Future<T?> replacePath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) => _admitNavigation(
    matcher.match(path, includePrefixMatches: includePrefixMatches) ?? [],
    () => super.replacePath<T>(
      path,
      includePrefixMatches: includePrefixMatches,
      onFailure: onFailure,
    ),
  );

  Future<R?> _admitNavigation<R>(
    List<RouteMatch?> candidates,
    Future<R?> Function() navigate,
  ) async {
    if (candidates.isEmpty || candidates.any((route) => route == null)) {
      return navigate();
    }
    final matches = candidates.cast<RouteMatch>();
    final inherited = Zone.current[_workAdmissionZoneKey];
    if (inherited is _WorkNavigationAdmission &&
        inherited.covers(matches, workSessionLoss.currentScope)) {
      return navigate();
    }
    final observation = _WorkRouteObservation.capture(this);
    final source = workSessionLoss.currentScope;
    final destination = _workDestinationScope(matches, source);
    final resolver = NavigationResolver(
      this,
      Completer<ResolverResult>(),
      matches.first,
      pendingRoutes: matches.skip(1).toList(),
    );
    final allowed = await workSessionLoss.allowScopeLoss(
      destination: destination,
      forced: _scopeLossIsForced(access, source),
      confirm: () => _workSessionLossGuard.confirm(resolver),
    );
    if (!allowed || !observation.matches(this)) return null;
    final admission = _WorkNavigationAdmission(source, matches);
    try {
      return await runZoned(
        navigate,
        zoneValues: {_workAdmissionZoneKey: admission},
      );
    } finally {
      admission.close();
    }
  }

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
      // TODO: Validate scoped resource existence and finer grained access.
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
      usesPathAsKey: true,
      // TODO: Validate realm/book existence and finer-grained book access.
      guards: [_authGuard, _organizationGuard],
      children: [AutoRoute(page: RouteRoute.page, path: "page/:pageId")],
    ),
  ];
}

bool _scopeLossIsForced(RouteAccessCoordinator access, LocalWorkScope current) {
  if (access.authentication.decision is RouteAuthenticationUnauthenticated) {
    return true;
  }
  final organizationId = current.organizationId?.id;
  return organizationId != null &&
      access.organizations.decisionFor(organizationId) ==
          OrganizationRouteDecision.nonMember;
}

/// Invalidates route parameter providers after every navigator mutation.
///
/// The callback is owned by the application shell and is responsible for
/// deferring invalidation until the current frame has completed.
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

/// Logs navigator transitions using route names and inherited parameters.
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

/// Provides a compact diagnostic representation for navigator logging.
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

/// Exposes the router's current path as reactive application state.
@riverpod
class CurrentRoute extends _$CurrentRoute {
  @override
  String build() {
    final router = ref.watch(appRouterProvider);
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
  final router = ref.watch(appRouterProvider);
  final params = router.topRoute.inheritedPathParams;
  return params.optString(id);
}
