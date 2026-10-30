import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _globex = organization("Globex");

const _notAMember = "You do not have access to this organization.";

void main() {
  group("authentication", () {
    testWidgets("a signed out user opening a private route lands on sign in", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.route(OrganizationRoute(organizationId: "acme")),
      );

      expect(panel.path, "/auth");
    });

    testWidgets("a signed in user opening sign in returns to the index", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
      ], at: const PanelLocation.route(AuthRoute()));

      await panel.eventually(() => expect(panel.path, "/"));
    });

    testWidgets("an unreachable identity provider keeps the user off sign in", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        unreachableAtStartup(StartupDependency.identityProvider),
      ], at: const PanelLocation.route(IndexRoute()));

      expect(panel.path, isNot("/auth"));
      expect(
        find.textContaining("The identity provider is unreachable"),
        findsOneWidget,
      );
    });
  });

  group("organization membership", () {
    testWidgets("a nonmember opening an organization lands on the index", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);

      await panel.open("/organization/globex/services");

      await panel.eventually(() => expect(panel.path, "/"));
      expect(find.text(_notAMember), findsOneWidget);
    });

    testWidgets(
      "a nonmember opening a realm resource is denied once by its organization",
      (tester) async {
        final panel = await tester.pumpPanel([
          signedIn(ada, organization: acme),
        ]);

        await panel.open("/organization/globex/realm/main/resource/first");

        await panel.eventually(() => expect(panel.path, "/"));
        expect(find.text(_notAMember), findsOneWidget);
      },
    );

    testWidgets("a member removed mid session is sent to the index", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [_globex]),
      ]);
      expect(panel.path, startsWith("/organization/acme"));

      panel.world.organizations.leave(ada.id, acme.organizationId);
      await panel.settle();

      await panel.eventually(() => expect(panel.path, "/"));
      expect(
        find.text("You no longer have access to this organization."),
        findsOneWidget,
      );
    });

    testWidgets("the organization in the address is the one the panel opens", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [_globex]),
      ], at: PanelLocation.route(OrganizationRoute(organizationId: "globex")));

      expect(
        panel.container.read(organizationIdProvider),
        _globex.organizationId,
      );
    });

    testWidgets("switching organization through the address opens it", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [_globex]),
      ]);

      await panel.open("/organization/globex/services");

      await panel.eventually(
        () => expect(
          panel.container.read(organizationIdProvider),
          _globex.organizationId,
        ),
      );
    });
  });
}
