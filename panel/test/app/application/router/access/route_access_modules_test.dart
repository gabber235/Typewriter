import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/app/application/router/access/authentication_route_access.dart";
import "package:typewriter_panel/app/application/router/access/organization_route_access.dart";
import "package:typewriter_panel/app/application/router/access/route_access_coordinator.dart";

void main() {
  test("authentication emits only for changed stable decisions", () async {
    final access = AuthenticationRouteAccess();
    var notifications = 0;
    access.reevaluation.addListener(() => notifications++);
    final waiting = access.waitUntilReady();

    access.setDecision(const RouteAuthenticationDecision.authenticated());
    await waiting;
    expect(notifications, 0);
    access
      ..setDecision(const RouteAuthenticationDecision.loading())
      ..setDecision(const RouteAuthenticationDecision.authenticated());
    expect(notifications, 0);
    access.setDecision(const RouteAuthenticationDecision.unauthenticated());
    expect(notifications, 1);
    access.setDecision(const RouteAuthenticationDecision.unavailable());
    expect(notifications, 2);
    access.dispose();
  });

  test("organization preserves baseline through transient states", () {
    final access = OrganizationRouteAccess();
    var notifications = 0;
    access.reevaluation.addListener(() => notifications++);
    access.setState(
      OrganizationRouteAccessState.available(
        principalId: "user",
        organizationIds: {"org", "other"},
      ),
    );
    expect(access.decisionFor("org"), OrganizationRouteDecision.member);
    expect(notifications, 0);

    access
      ..setState(const OrganizationRouteAccessState.loading())
      ..setState(const OrganizationRouteAccessState.unavailable());
    expect(access.decisionFor("org"), OrganizationRouteDecision.unavailable);
    access.setState(
      OrganizationRouteAccessState.available(
        principalId: "user",
        organizationIds: {"other", "org"},
      ),
    );
    expect(notifications, 0);

    access.setState(
      const OrganizationRouteAccessState.available(
        principalId: "user",
        organizationIds: {"other"},
      ),
    );
    expect(notifications, 1);
    access.setState(
      const OrganizationRouteAccessState.available(
        principalId: "other-user",
        organizationIds: {"other"},
      ),
    );
    expect(notifications, 2);
    access.dispose();
  });

  test(
    "authentication disposal resolves pending waiters as unavailable",
    () async {
      final access = AuthenticationRouteAccess();
      final waiting = access.waitUntilReady();

      access.dispose();
      await waiting;

      expect(access.decision, const RouteAuthenticationDecision.unavailable());
    },
  );

  test(
    "organization disposal resolves pending waiters as unavailable",
    () async {
      final access = OrganizationRouteAccess();
      final waiting = access.waitUntilReady();

      access.dispose();
      await waiting;

      expect(access.state, const OrganizationRouteAccessState.unavailable());
      expect(access.decisionFor("org"), OrganizationRouteDecision.unavailable);
    },
  );

  test("coordinator forwards semantic notifications", () {
    final authentication = AuthenticationRouteAccess()
      ..setDecision(const RouteAuthenticationDecision.authenticated());
    final organizations = OrganizationRouteAccess();
    final coordinator = RouteAccessCoordinator(
      authentication: authentication,
      organizations: organizations,
    );
    var notifications = 0;
    coordinator.addListener(() => notifications++);

    authentication.setDecision(
      const RouteAuthenticationDecision.unauthenticated(),
    );
    organizations.setState(const OrganizationRouteAccessState.unavailable());
    expect(notifications, 1);
    coordinator.dispose();
  });
}
