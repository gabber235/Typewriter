import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("auth and organization redirects use separate guard instances", () {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final authRoute = router.routes.singleWhere(
      (route) => route.path == "/auth",
    );
    final organizationRoute = router.routes.singleWhere(
      (route) => route.path == "/organization/:organizationId",
    );

    expect(authRoute.guards, hasLength(1));
    expect(organizationRoute.guards, hasLength(2));
    expect(authRoute.guards.single, isNot(same(organizationRoute.guards.last)));
  });

  test("realm resource routes inherit the organization guards", () {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final organizationRoute = router.routes.singleWhere(
      (route) => route.path == "/organization/:organizationId",
    );
    final realmRoute = organizationRoute.children!.singleWhere(
      (route) => route.path == "realm/:realmId",
    );

    expect(organizationRoute.guards, hasLength(2));
    expect(realmRoute.children!.map((route) => route.path), [
      "",
      "resource/:resourceId",
    ]);
    expect(
      router.routes.where((route) => route.path.contains("/book/")),
      isEmpty,
    );
  });

  test("bare organization path key maps to the organization table ID", () {
    final container = ProviderContainer.test(
      overrides: [
        routeParamProvider("organizationId").overrideWithValue("org1"),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(organizationIdProvider),
      skir.recordId("organization:org1"),
    );
  });
}
