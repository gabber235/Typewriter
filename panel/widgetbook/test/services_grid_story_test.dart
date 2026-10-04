import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/route.stories.dart";
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
    expect(
      scenario.services.any((service) => service.isConnectedAt(DateTime.now())),
      isTrue,
    );
    expect(
      scenario.services.any(
        (service) => !service.isConnectedAt(DateTime.now()),
      ),
      isTrue,
    );
    expect(
      scenario.services.where((service) => service.isCustom),
      hasLength(4),
    );
  });

  testWidgets("service inspector story renders the portable backend host", (
    tester,
  ) async {
    final service = completeTopologyScenario().services.first;
    await tester.pumpWidget(serviceInspectorStory(service: service));
    await tester.pumpAndSettle();

    expect(find.byType(PortablePresentationRenderer), findsOneWidget);
    expect(find.text("Name"), findsOneWidget);
    expect(find.text(service.name), findsOneWidget);
    expect(find.text("Connection"), findsOneWidget);
    expect(find.text("Connected"), findsOneWidget);
    expect(find.text("Version"), findsOneWidget);
    expect(find.text(service.role.version), findsOneWidget);
    expect(find.text("Last seen"), findsOneWidget);
    expect(find.text(service.lastSeen!.toIso8601String()), findsOneWidget);
    expect(find.text("The presentation value is not text"), findsNothing);
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
          canonicalOrganizationServicesProvider.overrideWith2(
            (_) => _StoryServices(services),
          ),
          organizationTopologyControllerProvider.overrideWith2(
            (_) => _StoryTopology(topology),
          ),
          organizationIdProvider.overrideWithValue(
            recordId("organization:story"),
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

    expect(find.byType(PortablePresentationRenderer), findsOneWidget);
    expect(find.text("Name"), findsOneWidget);
    expect(find.text("Connection"), findsOneWidget);
    expect(find.text("Entry point"), findsOneWidget);
    expect(find.text("Realm hosting"), findsOneWidget);
    expect(find.text("Runtime health"), findsOneWidget);
    expect(find.text("Host a Realm"), findsOneWidget);
    expect(find.text("Run an execution engine"), findsOneWidget);
    expect(find.text("Apply"), findsNothing);
    expect(find.text("Save"), findsOneWidget);

    expect(find.byTooltip("Zoom to fit"), findsNothing);
    expect(find.text("Enabled"), findsNothing);
    expect(find.text("Disabled"), findsNothing);
    expect(find.text("Assigned Realm"), findsNothing);
    final realmSwitch = find.byType(Switch).first;
    expect(tester.widget<Switch>(realmSwitch).value, isTrue);
    await tester.ensureVisible(realmSwitch);
    await tester.tap(realmSwitch);
    await tester.pumpAndSettle();
    expect(find.text("Assigned Realm"), findsOneWidget);
    expect(find.text("Hosted here"), findsNothing);
    expect(find.text("Existing Realm"), findsNothing);
    await tester.ensureVisible(realmSwitch);
    await tester.tap(realmSwitch);
    await tester.pumpAndSettle();
    expect(find.text("Assigned Realm"), findsOneWidget);
    final engineSwitch = find.byType(Switch).last;
    final wasEnabled = tester.widget<Switch>(engineSwitch).value;
    await tester.ensureVisible(engineSwitch);
    await tester.tap(engineSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(engineSwitch).value, !wasEnabled);
    expect(
      find.text("Engine target"),
      wasEnabled ? findsNothing : findsOneWidget,
    );
  });
}

class _StoryServices extends CanonicalOrganizationServices {
  _StoryServices(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build(skir.RecordId organizationId) =>
      Stream.value(services);
}

class _StoryTopology extends OrganizationTopologyController {
  _StoryTopology(this.topology);

  final OrganizationTopology topology;

  @override
  Stream<OrganizationTopology> build(skir.RecordId organizationId) =>
      Stream.value(topology);
}
