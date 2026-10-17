import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

LocalWorkScope _scope(String organization) => LocalWorkScope(
  userId: "user",
  organizationId: skir.recordId("organization:$organization"),
);

RouteAccessCoordinator _access() => RouteAccessCoordinator(
  authentication: AuthenticationRouteAccess()
    ..setDecision(const RouteAuthenticationDecision.authenticated()),
  organizations: OrganizationRouteAccess()
    ..setState(
      const OrganizationRouteAccessState.available(
        principalId: "user",
        organizationIds: {"one", "two"},
      ),
    ),
);

Future<bool> _guard(
  AppRouter router,
  AutoRoute route, {
  Parameters params = const Parameters({}),
}) async {
  final result = Completer<ResolverResult>();
  final resolver = NavigationResolver(
    router,
    result,
    RouteMatch(
      config: route,
      segments: const [],
      stringMatch: route.path,
      key: ValueKey(route.path),
      params: params,
    ),
  );

  await router.guards.single.onNavigation(resolver, router);
  return (await result.future).continueNavigation;
}

void main() {
  test("voluntary organization transition follows confirmation", () async {
    final access = _access();
    var confirmations = 0;
    var decision = false;
    final router = AppRouter(
      access,
      WorkSessionLossController(() => _scope("one"), () => true),
      confirmWorkSessionLoss: (_) async {
        confirmations++;
        return decision;
      },
    );
    addTearDown(access.dispose);
    final organization = router.routes.singleWhere(
      (route) => route.path == "/organization/:organizationId",
    );

    expect(
      await _guard(
        router,
        organization,
        params: const Parameters({"organizationId": "two"}),
      ),
      isFalse,
    );
    decision = true;
    expect(
      await _guard(
        router,
        organization,
        params: const Parameters({"organizationId": "two"}),
      ),
      isTrue,
    );
    expect(confirmations, 2);
  });

  test("nested navigation in the same organization remains free", () async {
    final access = _access();
    var confirmations = 0;
    final router = AppRouter(
      access,
      WorkSessionLossController(() => _scope("one"), () => true),
      confirmWorkSessionLoss: (_) async {
        confirmations++;
        return false;
      },
    );
    addTearDown(access.dispose);
    final organization = router.routes.singleWhere(
      (route) => route.path == "/organization/:organizationId",
    );
    final services = organization.children!.singleWhere(
      (route) => route.path == "services",
    );

    expect(await _guard(router, services), isTrue);
    expect(confirmations, 0);
  });

  test("forced authentication revocation bypasses confirmation", () async {
    final access = _access();
    access.authentication.setDecision(
      const RouteAuthenticationDecision.unauthenticated(),
    );
    var confirmations = 0;
    final router = AppRouter(
      access,
      WorkSessionLossController(() => _scope("one"), () => true),
      confirmWorkSessionLoss: (_) async {
        confirmations++;
        return false;
      },
    );
    addTearDown(access.dispose);
    final index = router.routes.singleWhere((route) => route.path == "/");

    expect(await _guard(router, index), isTrue);
    expect(confirmations, 0);
  });
}
