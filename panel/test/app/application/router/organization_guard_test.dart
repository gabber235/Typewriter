import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
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

  test("organization and book routes share one organization guard", () {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final organizationRoute = router.routes.singleWhere(
      (route) => route.path == "/organization/:organizationId",
    );
    final bookRoute = router.routes.singleWhere(
      (route) =>
          route.path ==
          "/organization/:organizationId/realm/:realmId/book/:bookId",
    );

    expect(organizationRoute.guards, hasLength(2));
    expect(bookRoute.guards, hasLength(2));
    expect(organizationRoute.guards.last, same(bookRoute.guards.last));
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
      recordId("organization:org1"),
    );
  });
}
