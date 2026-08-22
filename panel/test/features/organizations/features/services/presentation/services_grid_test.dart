import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("registration control stacks within a narrow content pane", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: const SizedBox(width: 360, child: RegistrationTokenInput()),
    );

    final inputTop = tester.getTopLeft(find.byType(EditorTextField)).dy;
    final buttonTop = tester.getTopLeft(find.text("Connect")).dy;
    expect(buttonTop, greaterThan(inputTop));
  });

  testWidgets(
    "shows custom services and every topology resource in one graph",
    (tester) async {
      final fixture = _Fixture(connected: true);
      await tester.pumpTestApp(
        child: SizedBox(
          width: 1200,
          height: 720,
          child: ServicesGraph(
            services: fixture.services,
            topology: fixture.topology,
          ),
        ),
        overrides: fixture.overrides,
      );

      expect(find.text("DISCORD SERVICE"), findsOneWidget);
      expect(find.text("PAPER HOST"), findsOneWidget);
      expect(find.text("REALM"), findsOneWidget);
      expect(find.text("ENGINE"), findsOneWidget);
      expect(find.text("Discord Bridge"), findsOneWidget);
      expect(find.text("Paper Eu"), findsNWidgets(2));
      expect(find.byType(Graph), findsOneWidget);
      final graph = tester.widget<Graph>(find.byType(Graph));
      expect(graph.data.elements, hasLength(4));
      expect(graph.data.edges, hasLength(2));
      expect(find.byTooltip("Zoom to fit"), findsNothing);
    },
  );

  testWidgets("keeps orphan runtimes visible without topology edges", (
    tester,
  ) async {
    final fixture = _Fixture(connected: true);
    final orphaned = fixture.topology.copyWith(hosts: []);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 1200,
        height: 720,
        child: ServicesGraph(
          services: [fixture.customService],
          topology: orphaned,
        ),
      ),
      overrides: fixture.overrides,
    );

    final graph = tester.widget<Graph>(find.byType(Graph));
    expect(graph.data.elements, hasLength(3));
    expect(graph.data.edges, isEmpty);
    expect(find.text("REALM"), findsOneWidget);
    expect(find.text("ENGINE"), findsOneWidget);
  });

  testWidgets("host selection uses the shared presentation inspector", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _Fixture(connected: true);
    await tester.pumpTestApp(
      child: InspectorScaffold(
        child: ServicesGraph(
          services: fixture.services,
          topology: fixture.topology,
        ),
      ),
      overrides: fixture.overrides,
    );

    await tester.tap(find.text("PAPER HOST"));
    await tester.pumpAndSettle();

    expect(find.text("Service"), findsOneWidget);
    expect(find.text("Identity and connection"), findsOneWidget);
    expect(find.text("CONNECTION"), findsOneWidget);
    expect(find.text("Host"), findsOneWidget);
    expect(find.text("Capabilities and runtime health"), findsOneWidget);
    expect(find.text("CAPABILITIES"), findsOneWidget);
    expect(find.text("RUNTIME HEALTH"), findsOneWidget);
    expect(find.text("Configuration"), findsOneWidget);
    expect(find.text("REALM HOSTING"), findsOneWidget);
    expect(find.text("EXECUTION ENGINE"), findsOneWidget);
    expect(find.text("Host a Realm"), findsOneWidget);
    expect(find.text("Run an execution engine"), findsOneWidget);
    expect(find.text("Assigned Realm"), findsNothing);
    expect(find.text("Hosted Realm"), findsNothing);
    expect(find.text("Message"), findsNothing);
    expect(find.byType(TypedEditor), findsOneWidget);
    expect(find.text("Unbind"), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsWidgets);

    await tester.ensureVisible(find.text("Host a Realm"));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(find.text("Assigned Realm"), findsOneWidget);
    expect(find.text("Hosted Realm"), findsNothing);
  });

  testWidgets("custom service selection exposes unbind without open", (
    tester,
  ) async {
    final fixture = _Fixture(connected: true);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 1200,
        height: 720,
        child: InspectorScaffold(
          child: ServicesGraph(
            services: fixture.services,
            topology: fixture.topology,
          ),
        ),
      ),
      overrides: fixture.overrides,
    );

    await tester.tap(find.text("Discord Bridge"));
    await tester.pumpAndSettle();

    expect(find.text("Unbind"), findsOneWidget);
    expect(find.text("Open"), findsNothing);
  });

  testWidgets("runtime selection groups health and placement details", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _Fixture(
      connected: true,
      childMessage: "Deployment needs attention",
    );
    await tester.pumpTestApp(
      child: InspectorScaffold(
        child: ServicesGraph(
          services: fixture.services,
          topology: fixture.topology,
        ),
      ),
      overrides: fixture.overrides,
    );

    await tester.tap(find.text("ENGINE"));
    await tester.pumpAndSettle();

    expect(find.text("Runtime"), findsOneWidget);
    expect(find.text("Current deployment health"), findsOneWidget);
    expect(find.text("STATUS"), findsOneWidget);
    expect(find.text("Placement"), findsOneWidget);
    expect(find.text("Where this runtime executes"), findsOneWidget);
    expect(find.text("ASSIGNMENT"), findsOneWidget);
    expect(find.text("Assigned Realm"), findsOneWidget);
    expect(find.text("Message"), findsOneWidget);
    expect(find.text("Deployment needs attention"), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets("offline Realm selection does not expose open", (tester) async {
    final fixture = _Fixture(connected: false);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 1200,
        height: 720,
        child: InspectorScaffold(
          child: ServicesGraph(
            services: fixture.services,
            topology: fixture.topology,
          ),
        ),
      ),
      overrides: fixture.overrides,
    );

    await tester.tap(find.text("REALM"));
    await tester.pumpAndSettle();

    expect(find.text("Host offline"), findsNWidgets(2));
    expect(find.text("Open"), findsNothing);
  });
}

class _Fixture {
  _Fixture({required bool connected, String? childMessage}) {
    hostService = _service(
      id: "paper-eu",
      name: "paper_eu",
      connected: connected,
      role: HostServiceRole(version: "1.0.0"),
    );
    customService = _service(
      id: "discord",
      name: "discord_bridge",
      connected: true,
      role: CustomServiceRole(name: "discord", version: "1.0.0"),
    );
    host = skir.ServiceHost(
      hostId: recordId("service_host:paper-eu"),
      serviceId: hostService.serviceId,
      revision: 2,
      entrypoint: "PAPER",
      canHostRealm: true,
      supportedEngines: [
        skir.SupportedEngine(engineId: "paper", supportedMajorVersions: [1]),
      ],
      topologyRevision: skir.ReconciledRevision(desired: 2, applied: 2),
      state: skir.HostRuntimeState(
        status: skir.HostRuntimeStatus.active,
        message: null,
        updatedAt: DateTime.utc(2026, 8, 20),
      ),
    );
    realm = skir.RealmInstance(
      realmId: recordId("realm_instance:adventure"),
      ownerHost: skir.OwnerHost(id: host.hostId, name: hostService.name),
      revision: 3,
      targetEngine: skir.EngineTarget(engineId: "paper", majorVersion: 1),
      manifestRevision: skir.ReconciledRevision(desired: 4, applied: 4),
      state: _childState(message: childMessage),
    );
    engine = skir.EngineInstance(
      engineId: recordId("engine_instance:paper-eu"),
      ownerHost: skir.OwnerHost(id: host.hostId, name: hostService.name),
      realm: skir.RealmInfo(realmId: realm.realmId, ownerHost: realm.ownerHost),
      revision: 4,
      target: skir.EngineTarget(engineId: "paper", majorVersion: 1),
      manifestRevision: skir.ReconciledRevision(desired: 4, applied: 4),
      state: _childState(message: childMessage),
    );
    topology = OrganizationTopology(
      hosts: [TopologyHost.fromSkir(host)],
      realmInstances: [TopologyRealm.fromSkir(realm)],
      engineInstances: [TopologyEngine.fromSkir(engine)],
    );
  }

  late final Service hostService;
  late final Service customService;
  late final skir.ServiceHost host;
  late final skir.RealmInstance realm;
  late final skir.EngineInstance engine;
  late final OrganizationTopology topology;

  List<Service> get services => [hostService, customService];

  List<Override> get overrides => [
    servicesProvider.overrideWith(() => _FixtureServices(services)),
    organizationTopologyStreamProvider.overrideWith(
      () => _FixtureTopology(topology),
    ),
  ];
}

class _FixtureServices extends Services {
  _FixtureServices(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build() => Stream.value(services);
}

class _FixtureTopology extends OrganizationTopologyStream {
  _FixtureTopology(this.topology);

  final OrganizationTopology topology;

  @override
  Stream<OrganizationTopology> build() => Stream.value(topology);
}

Service _service({
  required String id,
  required String name,
  required bool connected,
  required ServiceRole role,
}) => Service(
  serviceId: recordId("service:$id"),
  revision: 1,
  name: name,
  role: role,
  createdAt: DateTime.utc(2026, 8, 20),
  organization: recordId("organization:test"),
  state: ServiceState(
    status: connected ? ServiceStateStatus.online : ServiceStateStatus.offline,
    lastSeen: DateTime.now(),
  ),
);

skir.ChildRuntimeState _childState({String? message}) => skir.ChildRuntimeState(
  status: skir.ChildRuntimeStatus.active,
  activeArtifactVersion: "1.0.0",
  message: message,
  updatedAt: DateTime.utc(2026, 8, 20),
);
