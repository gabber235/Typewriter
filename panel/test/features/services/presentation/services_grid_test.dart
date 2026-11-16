import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const unbindOne = "Unbind this service? It disconnects straight away.";
const _unbindSubject = "cloud.to.user.ada.organization.acme.services.unbind";
const _bindSubject = "cloud.to.user.ada.organization.acme.services.bind";

final _paper = service(
  "paper_eu",
  organization: acme.organizationId,
  createdAt: DateTime.utc(2026, 8, 20),
);

final _discord = service(
  "discord",
  name: "discord_bridge",
  role: skir.ServiceRole.createCustom(name: "discord", version: "1.0.0"),
  organization: acme.organizationId,
  createdAt: DateTime.utc(2026, 8, 20),
);

final _host = paperHost(
  "paper_eu",
  revision: 2,
  engines: ["paper"],
  state: hostRuntimeState(updatedAt: DateTime.utc(2026, 8, 20)),
);

final _realm = realmInstance(
  "adventure",
  host: "paper_eu",
  hostName: "paper_eu",
  version: "^1",
  revision: 3,
  state: childRuntimeState(updatedAt: DateTime.utc(2026, 8, 20)),
);

final _topology = topologySnapshot(
  hosts: [_host],
  realms: [_realm],
  engines: [
    engineInstance(
      "paper_eu",
      realm: _realm,
      revision: 4,
      state: childRuntimeState(updatedAt: DateTime.utc(2026, 8, 20)),
    ),
  ],
);

void main() {
  test("Realm navigation opens the Realm by its own id", () {
    final route = realmNavigationRoute(
      skir.recordId("organization:test"),
      skir.recordId("realm_instance:adventure"),
    );

    expect(route.rawPathParams["organizationId"], "test");
    expect(route.initialChildren!.single.rawPathParams["realmId"], "adventure");
  });

  testWidgets("the registration control stacks within a narrow pane", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      [signedIn(ada, organization: acme)],
      at: const PanelLocation.component(
        SizedBox(width: 360, child: RegistrationTokenInput()),
      ),
    );

    expect(
      tester.getTopLeft(panel.labeled("Connect").first).dy,
      greaterThan(panel.field("Enter registration token").rect.top),
    );
  });

  testWidgets("a malformed token is refused with a message and never "
      "sent", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(services: [_paper, _discord], topology: _topology),
    ]);

    await panel.field("Enter registration token").type("not a token");
    await panel.tapOn(panel.labeled("Connect").first);

    expect(
      panel.shows("Token must be 10 uppercase alphanumeric characters"),
      isTrue,
    );
    expect(panel.world.nats.requestsTo(_bindSubject), isEmpty);
  });

  testWidgets("the graph shows every custom service and topology resource", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(services: [_paper, _discord], topology: _topology),
    ]);

    expect(
      panel.services.cards,
      unorderedEquals([
        "Discord service, Discord Bridge, Connected",
        "Paper host, Paper Eu, Active",
        "Realm, Paper Eu, Active",
        "Engine, paper ^1, Active",
      ]),
    );
  });

  testWidgets("runtimes stay visible when their host is gone", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(
        services: [_discord],
        topology: topologySnapshot(
          realms: [..._topology.realms],
          engines: [..._topology.engines],
        ),
      ),
    ]);

    expect(
      panel.services.cards,
      unorderedEquals([
        "Discord service, Discord Bridge, Connected",
        "Realm, Paper Eu, Host offline",
        "Engine, paper ^1, Host offline",
      ]),
    );
  });

  testWidgets("a selected host shows its identity, connection, capabilities "
      "and configuration", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(services: [_paper, _discord], topology: _topology),
    ]);

    await panel.services.card("Paper host", "Paper Eu").select();

    for (final label in [
      "Name",
      "CONNECTION",
      "Connected",
      "Version",
      "Entry point",
      "Realm hosting",
      "Supported engines",
      "RUNTIME HEALTH",
      "Host a Realm",
      "Run an execution engine",
    ]) {
      expect(panel.shows(label), isTrue, reason: "The inspector shows $label");
    }
    for (final label in ["Assigned Realm", "Message"]) {
      expect(panel.shows(label), isFalse, reason: "$label stays hidden");
    }
    expect(panel.inspector.operations, [unbindOne]);

    expect(panel.inspector.isChecked("Host a Realm"), isTrue);
    await panel.inspector.toggle("Host a Realm");

    expect(panel.inspector.isChecked("Host a Realm"), isFalse);
    expect(panel.shows("Assigned Realm"), isTrue);
  });

  testWidgets("a selected custom service offers Unbind and no Open", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(services: [_paper, _discord], topology: _topology),
    ]);

    await panel.services.card("Discord service", "Discord Bridge").select();

    expect(panel.inspector.operations, [unbindOne]);
  });

  testWidgets("Unbind in the inspector removes the service", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(services: [_paper, _discord], topology: _topology),
    ]);
    panel.world.nats.registerHandler(
      _unbindSubject,
      (_) => skir.UnbindServiceResponse.serializer.toBytes(
        skir.UnbindServiceResponse.createSuccess(),
      ),
    );
    await panel.services.card("Discord service", "Discord Bridge").select();

    await panel.holdButton(unbindOne);

    await panel.eventually(
      () => expect(
        panel.services.cards,
        isNot(contains(startsWith("Discord service"))),
      ),
    );
  });

  testWidgets("a rejected Unbind keeps the service and tells the author", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(services: [_paper, _discord], topology: _topology),
    ]);
    panel.world.nats.registerHandler(
      _unbindSubject,
      (_) => skir.UnbindServiceResponse.serializer.toBytes(
        skir.UnbindServiceResponse.createServiceNotFoundError(),
      ),
    );
    await panel.services.card("Discord service", "Discord Bridge").select();

    await panel.holdButton(unbindOne);

    expect(panel.refusalOn(unbindOne), "Service not found");
    expect(panel.shows("Needs attention"), isTrue);
    expect(
      panel.container
          .read(canonicalServicesProvider)
          .requireValue
          .map((service) => service.name),
      contains("discord_bridge"),
    );
  });

  testWidgets("a selected engine groups health and placement details", (
    tester,
  ) async {
    final attention = childRuntimeState(
      message: "Deployment needs attention",
      updatedAt: DateTime.utc(2026, 8, 20),
    );
    final realm = (_realm.toMutable()..state = attention).toFrozen();
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(
        services: [_paper, _discord],
        topology: topologySnapshot(
          hosts: [_host],
          realms: [realm],
          engines: [
            engineInstance(
              "paper_eu",
              realm: realm,
              revision: 4,
              state: attention,
            ),
          ],
        ),
      ),
    ]);

    await panel.services.card("Engine", "paper ^1").select();

    for (final label in [
      "Owner host",
      "Target",
      "STATUS",
      "Artifact",
      "Assigned Realm",
      "Message",
      "Deployment needs attention",
    ]) {
      expect(panel.shows(label), isTrue, reason: "The inspector shows $label");
    }
    double left(String label) => tester.getTopLeft(find.text(label)).dx;
    for (final label in ["Artifact", "Updated"]) {
      expect(left(label), closeTo(left("STATUS"), 0.01));
    }
    for (final label in ["Owner host", "Target"]) {
      expect(left(label), closeTo(left("ASSIGNMENT"), 0.01));
    }
  });

  testWidgets("a Realm on an offline host reads offline and offers no "
      "Open", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(
        services: [
          service(
            "paper_eu",
            organization: acme.organizationId,
            createdAt: DateTime.utc(2026, 8, 20),
            status: skir.ServiceStatus.offline,
          ),
          _discord,
        ],
        topology: _topology,
      ),
    ]);

    expect(panel.services.statusOf("Realm", "Paper Eu"), "Host offline");
    await panel.services.card("Realm", "Paper Eu").select();

    expect(panel.shows("Open"), isFalse);
  });

  testWidgets("leaving the services page while its projections restart "
      "fails nothing", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(services: [_paper, _discord], topology: _topology),
    ]);

    await panel.follow(const IndexRoute());

    expect(panel.path, "/");
    expect(tester.takeException(), isNull);
  });
}
