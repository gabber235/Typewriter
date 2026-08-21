import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/topology_scenarios.dart";

void main() {
  testWidgets("services story selects a host through the shared inspector", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final topology = topologyScenario();
    final services = topologyScenarioServices(topology);
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
            child: ServicesGrid(services: services, topology: topology),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("PAPER HOST"));
    await tester.pumpAndSettle();

    expect(find.text("Execution"), findsOneWidget);
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
