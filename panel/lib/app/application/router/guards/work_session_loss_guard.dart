part of "../app_router.dart";

/// Protects navigation only when it destroys the current local work scope.
final class _WorkSessionLossGuard extends AutoRouteGuard {
  const _WorkSessionLossGuard(this.access, this.controller, this.confirm);

  final RouteAccessCoordinator access;
  final WorkSessionLossController controller;
  final WorkSessionLossRouteConfirmation confirm;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (resolver.routeName == AuthRoute.name &&
        access.authentication.decision is RouteAuthenticationAuthenticated) {
      resolver.next();
      return;
    }

    try {
      final current = controller.currentScope;
      final admission = Zone.current[_workAdmissionZoneKey];
      if (admission is _WorkNavigationAdmission &&
          admission.consume(resolver.route, current)) {
        resolver.next();
        return;
      }
      final destinationOrganization = _destinationOrganization(
        resolver,
        current,
      );
      final allowed = await controller.allowScopeLoss(
        destination: current.copyWith(
          organizationId: destinationOrganization == null
              ? null
              : skir.recordId("organization:$destinationOrganization"),
        ),
        forced: _scopeLossIsForced(access, current),
        confirm: () => confirm(resolver),
      );
      if (!resolver.isResolved) resolver.next(allowed);
    } on Object catch (error, stackTrace) {
      if (!resolver.isResolved) resolver.next(false);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: "Typewriter routing",
          context: ErrorDescription("confirming local work session loss"),
        ),
      );
    }
  }

  String? _destinationOrganization(
    NavigationResolver resolver,
    LocalWorkScope current,
  ) {
    if (resolver.routeName == IndexRoute.name ||
        resolver.routeName == AuthRoute.name) {
      return null;
    }

    final direct = resolver.route.params.optString("organizationId");
    if (direct != null && direct.isNotEmpty) return direct;
    for (final pending in resolver.pendingRoutes) {
      for (final route in pending.flattened) {
        final organizationId = route.params.optString("organizationId");
        if (organizationId != null && organizationId.isNotEmpty) {
          return organizationId;
        }
      }
    }
    return current.organizationId?.id;
  }
}
