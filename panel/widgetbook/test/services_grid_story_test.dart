import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/topology_scenarios.dart";

void main() {
  test("complete scenario covers topology roles and runtime states", () {
    final scenario = completeTopologyScenario();
    final topology = scenario.topology;

    expect(topology.hosts.map((host) => host.entrypoint).toSet(), {
      "PAPER",
      "STANDALONE",
    });
    expect(topology.hosts.map((host) => host.state.status).toSet(), {
      TopologyHostStatus.active,
      TopologyHostStatus.reconciling,
      TopologyHostStatus.drifted,
      TopologyHostStatus.failed,
      TopologyHostStatus.offline,
    });
    expect(
      {
        ...topology.realmInstances.map((realm) => realm.state.status),
        ...topology.engineInstances.map((engine) => engine.state.status),
      },
      {
        TopologyRuntimeStatus.absent,
        TopologyRuntimeStatus.staging,
        TopologyRuntimeStatus.active,
        TopologyRuntimeStatus.quiescing,
        TopologyRuntimeStatus.failed,
        TopologyRuntimeStatus.rolledBack,
        TopologyRuntimeStatus.drifted,
      },
    );
    expect(scenario.services.any((service) => service.isOnline), isTrue);
    expect(scenario.services.any((service) => !service.isOnline), isTrue);
    expect(
      scenario.services.where((service) => service.isCustom),
      hasLength(4),
    );
  });

  testWidgets("services story selects a host through the shared inspector", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scenario = completeTopologyScenario();
    final topology = scenario.topology;
    final services = scenario.services;
    await tester.pumpWidget(
      FakeApp(
        overrides: [
          servicesProvider.overrideWith(() => _StoryServices(services)),
          organizationTopologyStreamProvider.overrideWith(
            () => _StoryTopology(topology),
          ),
          ...appearanceProviderOverrides(),
        ],
        child: SizedBox(
          width: 1180,
          height: 720,
          child: InspectorScaffold(
            child: ServicesGraph(services: services, topology: topology),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("PAPER HOST").first);
    await tester.pumpAndSettle();

    expect(find.text("Identity and connection"), findsOneWidget);
    expect(find.text("CONNECTION"), findsOneWidget);
    expect(find.text("Capabilities and runtime health"), findsOneWidget);
    expect(find.text("CAPABILITIES"), findsOneWidget);
    expect(find.text("RUNTIME HEALTH"), findsOneWidget);
    expect(find.text("Configuration"), findsOneWidget);
    expect(find.text("REALM HOSTING"), findsOneWidget);
    expect(find.text("EXECUTION ENGINE"), findsOneWidget);
    expect(find.text("Run an execution engine"), findsOneWidget);
    expect(find.byTooltip("Zoom to fit"), findsNothing);
  });
}

class _StoryServices extends Services {
  _StoryServices(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build() => Stream.value(services);
}

class _StoryTopology extends OrganizationTopologyStream {
  _StoryTopology(this.topology);

  final OrganizationTopology topology;

  @override
  Stream<OrganizationTopology> build() => Stream.value(topology);
}
