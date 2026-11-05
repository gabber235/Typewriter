import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final library = [book("First")];

  group("a Realm served by a reporting host", () {
    testWidgets("opens from its route and turns online once checked", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        [signedIn(ada, organization: acme), realm(books: library)],
        at: PanelLocation.route(
          OrganizationRoute(organizationId: acme.organizationId.id),
        ),
      );
      final states = panel.recordRealmConnection();

      await panel.container
          .read(appRouterProvider)
          .navigate(
            const RealmRouteTree().realm(panel.world.requireRealm.scope),
          );
      await panel.settle();

      expect(states.last, RealmConnectionState.online);
      expect(
        states.skipWhile((state) => state != RealmConnectionState.online),
        everyElement(RealmConnectionState.online),
        reason: "an online Realm never goes back to checking on its own",
      );
      expect(panel.shows("Realm connection lost"), isFalse);
    });

    testWidgets("stays available through ordinary topology changes", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: library),
      ]);
      expect(panel.realmConnection, RealmConnectionState.online);
      final states = panel.recordRealmConnection()..clear();

      panel.world.organizations.addRealm(
        acme.organizationId,
        id: skir.recordId("realm_instance:other"),
        name: "Other",
      );
      await panel.settle();

      expect(states, isNot(contains(RealmConnectionState.checking)));
      expect(panel.realmConnection, RealmConnectionState.online);
    });

    testWidgets("is suspended once its host stops reporting", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: library),
      ]);
      expect(panel.realmConnection, RealmConnectionState.online);

      panel.world.organizations.stopHost(
        panel.world.requireRealm.scope.realmId,
      );
      await panel.settle();

      expect(panel.realmConnection, RealmConnectionState.offline);
      expect(panel.shows("Realm connection lost"), isTrue);
    });

    testWidgets("is suspended once its host's last report expires", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: library),
      ]);
      expect(panel.realmConnection, RealmConnectionState.online);

      await tester.pump(const Duration(minutes: 5));
      await panel.settle();

      expect(panel.realmConnection, RealmConnectionState.offline);
    });
  });

  testWidgets("each Realm of the organization is available while its own "
      "host reports", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: library),
    ]);
    final main = panel.world.requireRealm.scope.realmId;
    final other = panel.world.organizations
        .addRealm(
          acme.organizationId,
          id: skir.recordId("realm_instance:other"),
          name: "Other",
        )
        .realmId;

    panel.world.organizations.stopHost(other);
    await panel.settle();

    expect(await panel.container.read(realmsAvailabilityProvider.future), {
      main: true,
      other: false,
    });
  });

  testWidgets("without a Realm in the route nothing is selected", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);

    expect(panel.realmConnection, RealmConnectionState.notSelected);
    expect(panel.container.read(realmInteractionProvider).suspended, isFalse);
  });

  testWidgets("a Realm missing from the topology is unavailable", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: library),
      servicesBackend(),
    ]);

    expect(panel.realmConnection, RealmConnectionState.unavailable);
    expect(panel.shows("Realm unavailable"), isTrue);
  });

  group("a Realm whose runtime is not active", () {
    testWidgets("is offline", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: library),
        realmRuntime(skir.ChildRuntimeStatus.failed),
      ]);

      expect(panel.realmConnection, RealmConnectionState.offline);
      expect(panel.shows("Realm connection lost"), isTrue);
    });

    testWidgets("resumes without checking again once its runtime is active", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: library),
        realmRuntime(skir.ChildRuntimeStatus.failed),
      ]);
      final states = panel.recordRealmConnection()..clear();

      panel.world.nats.announceTopology(
        acme.organizationId,
        skir.OrganizationTopologyChanged.wrapReplace(
          realmRuntimeTopology(skir.ChildRuntimeStatus.active),
        ),
      );
      await panel.eventually(
        () => expect(panel.realmConnection, RealmConnectionState.online),
      );

      await panel.settle();

      expect(states, isNot(contains(RealmConnectionState.checking)));
      expect(panel.shows("Realm connection lost"), isFalse);
    });
  });

  testWidgets("checking again a Realm whose topology cannot be read shows "
      "it unavailable", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: library),
      realmRuntime(skir.ChildRuntimeStatus.failed),
    ]);
    expect(panel.realmConnection, RealmConnectionState.offline);
    panel.world.nats.registerHandler(
      "cloud.to.user.${ada.id.transportIdentity}.organization."
      "${acme.organizationId.id.transportIdentity}.topology.watch",
      (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
        skir.WatchOrganizationTopologyResponse.createInternalError(),
      ),
    );

    // The veil shows progress while it checks, so the panel never settles.
    await tester.tap(find.text("Check again"));

    await panel.eventually(
      () => expect(panel.realmConnection, RealmConnectionState.unavailable),
    );
    await panel.settle();
    expect(panel.shows("Realm unavailable"), isTrue);
  });
}
