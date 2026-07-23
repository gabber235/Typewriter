part of "../app_router.dart";

final class _AuthGuard extends AutoRouteGuard {
  const _AuthGuard(this.access);
  final AuthenticationRouteAccess access;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await access.waitUntilReady();
    if (resolver.isResolved) return;
    switch (access.decision) {
      case RouteAuthenticationAuthenticated():
        resolver.next();
      case RouteAuthenticationUnauthenticated():
        resolver.redirectUntil(const AuthRoute());
      case RouteAuthenticationLoading():
      case RouteAuthenticationUnavailable():
        resolver.next(false);
    }
  }
}

final class _UnAuthGuard extends AutoRouteGuard {
  const _UnAuthGuard(this.access, this.redirectCoordinator);
  final AuthenticationRouteAccess access;
  final _IndexRedirectCoordinator redirectCoordinator;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await access.waitUntilReady();
    if (resolver.isResolved) return;
    if (access.decision is! RouteAuthenticationAuthenticated) {
      resolver.next();
      return;
    }
    resolver.resolveNext(false, reevaluateNext: false);
    redirectCoordinator.schedule(
      router,
      shouldRedirect: () =>
          router.stack.isEmpty || router.topRoute.name == AuthRoute.name,
    );
  }
}
