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
    expect(find.text("CONNECTION"), findsOneWidget);
    expect(find.text("Connected"), findsOneWidget);
    expect(find.text("Version"), findsOneWidget);
    expect(find.text(service.role.version), findsOneWidget);
    expect(find.text("Last seen"), findsOneWidget);
    expect(find.text(service.lastSeen!.toIso8601String()), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    expect(
      find.ancestor(of: find.text("Service"), matching: find.byType(DepthBox)),
      findsOneWidget,
    );
    expect(find.text("The presentation value is not text"), findsNothing);
  });

  testWidgets("host header toggles accept keyboard activation", (tester) async {
    await tester.pumpWidget(hostInspectorStory());
    await tester.pumpAndSettle();
    final checkbox = find.byType(Checkbox).first;
    await tester.ensureVisible(checkbox);
    final body = find
        .descendant(of: checkbox, matching: find.byType(CustomPaint))
        .last;
    Focus.of(tester.element(body)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(checkbox).value, isFalse);
  });

  testWidgets("host cards remain compact at narrow inspector widths", (
    tester,
  ) async {
    final scenario = completeTopologyScenario();
    for (final host in scenario.topology.hosts) {
      await tester.pumpWidget(hostInspectorStory(host: host, width: 280));
      await tester.pumpAndSettle();
      expect(find.text("CAPABILITIES"), findsOneWidget);
      expect(find.text("RUNTIME HEALTH"), findsOneWidget);
      expect(
        find.text("REALM HOSTING"),
        host.canHostRealm ? findsOneWidget : findsNothing,
      );
      expect(find.text("EXECUTION ENGINE"), findsOneWidget);
      expect(find.text(host.state.updatedAt.toIso8601String()), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets("runtime stories preserve status messages and assignments", (
    tester,
  ) async {
    final scenario = completeTopologyScenario();
    final failed = scenario.topology.realmInstances.firstWhere(
      (realm) => realm.state.status == TopologyRuntimeStatus.failed,
    );
    await tester.pumpWidget(
      runtimeInspectorStory(
        host: failed.portablePresentationHost(),
        width: 280,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Failed"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text(failed.state.message!), findsOneWidget);
    expect(find.text("ASSIGNMENT"), findsOneWidget);
    expect(find.text("Assigned Realm"), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);

    final engine = scenario.topology.engineInstances.last;
    await tester.pumpWidget(
      runtimeInspectorStory(
        host: engine.portablePresentationHost(),
        width: 280,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Rolled back"), findsOneWidget);
    expect(find.text("Assigned Realm"), findsOneWidget);
    expect(find.text(engine.state.updatedAt.toIso8601String()), findsNothing);
    expect(tester.takeException(), isNull);
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
            skir.recordId("organization:story"),
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
    expect(find.text("CONNECTION"), findsOneWidget);
    expect(find.text("Entry point"), findsOneWidget);
    expect(find.text("Realm hosting"), findsOneWidget);
    expect(find.text("RUNTIME HEALTH"), findsOneWidget);
    expect(find.text("Host a Realm"), findsOneWidget);
    expect(find.text("Run an execution engine"), findsOneWidget);
    expect(find.text("Apply"), findsNothing);
    expect(find.text("Save"), findsOneWidget);

    expect(find.byTooltip("Zoom to fit"), findsNothing);
    expect(find.text("Enabled"), findsNothing);
    expect(find.text("Disabled"), findsNothing);
    expect(find.text("Assigned Realm"), findsNothing);
    final realmSwitch = find.byType(Checkbox).first;
    expect(tester.widget<Checkbox>(realmSwitch).value, isTrue);
    await tester.ensureVisible(realmSwitch);
    await tester.tap(realmSwitch);
    await tester.pumpAndSettle();
    expect(find.text("Assigned Realm"), findsOneWidget);
    expect(find.text("Hosted here"), findsNothing);
    expect(find.text("Existing Realm"), findsNothing);
    final checkboxBody = find
        .descendant(of: realmSwitch, matching: find.byType(CustomPaint))
        .last;
    Focus.of(tester.element(checkboxBody)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(realmSwitch).value, isTrue);
    expect(find.text("Assigned Realm"), findsOneWidget);
    final engineSwitch = find.byType(Checkbox).last;
    final wasEnabled = tester.widget<Checkbox>(engineSwitch).value!;
    await tester.ensureVisible(engineSwitch);
    await tester.tap(engineSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(engineSwitch).value, !wasEnabled);
    expect(
      find.text("Engine target"),
      wasEnabled ? findsNothing : findsOneWidget,
    );
    await tester.tap(engineSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(engineSwitch).value, wasEnabled);
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
