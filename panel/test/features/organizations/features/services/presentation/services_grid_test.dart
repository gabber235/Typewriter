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

  testWidgets("shows custom services and every topology resource in one grid", (
    tester,
  ) async {
    final fixture = _Fixture(connected: true);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 1200,
        height: 720,
        child: ServicesGrid(
          services: fixture.services,
          topology: fixture.topology,
        ),
      ),
      overrides: fixture.overrides,
    );

    expect(find.text("SERVICE"), findsOneWidget);
    expect(find.text("PAPER HOST"), findsOneWidget);
    expect(find.text("REALM"), findsOneWidget);
    expect(find.text("ENGINE"), findsOneWidget);
    expect(find.text("Discord Bridge"), findsOneWidget);
    expect(find.text("Paper Eu"), findsNWidgets(2));
    expect(find.byTooltip("Zoom to fit"), findsNothing);
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
        child: ServicesGrid(
          services: fixture.services,
          topology: fixture.topology,
        ),
      ),
      overrides: fixture.overrides,
    );

    await tester.tap(find.text("PAPER HOST"));
    await tester.pumpAndSettle();

    expect(find.text("Service"), findsWidgets);
    expect(find.text("Host"), findsOneWidget);
    expect(find.text("Execution"), findsOneWidget);
    expect(find.text("Host a Realm"), findsOneWidget);
    expect(find.text("Run an execution engine"), findsOneWidget);
    expect(find.byType(TypedEditor), findsOneWidget);
  });

  testWidgets("offline Realm selection does not expose open", (tester) async {
    final fixture = _Fixture(connected: false);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 1200,
        height: 720,
        child: InspectorScaffold(
          child: ServicesGrid(
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
  _Fixture({required bool connected}) {
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
      ownerHostId: host.hostId,
      revision: 3,
      targetEngine: skir.EngineTarget(engineId: "paper", majorVersion: 1),
      manifestRevision: skir.ReconciledRevision(desired: 4, applied: 4),
      state: _childState(),
    );
    engine = skir.EngineInstance(
      engineId: recordId("engine_instance:paper-eu"),
      ownerHostId: host.hostId,
      realmId: realm.realmId,
      revision: 4,
      target: skir.EngineTarget(engineId: "paper", majorVersion: 1),
      manifestRevision: skir.ReconciledRevision(desired: 4, applied: 4),
      state: _childState(),
    );
    topology = OrganizationTopology(
      hosts: [host],
      realmInstances: [realm],
      engineInstances: [engine],
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

skir.ChildRuntimeState _childState() => skir.ChildRuntimeState(
  status: skir.ChildRuntimeStatus.active,
  activeArtifactVersion: "1.0.0",
  message: null,
  updatedAt: DateTime.utc(2026, 8, 20),
);
