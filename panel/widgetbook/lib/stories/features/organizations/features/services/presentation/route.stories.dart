import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/topology_scenarios.dart";
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "Default", type: ServicesPage)
Widget servicesPageUseCase(BuildContext context) {
  final servicesState = context.knobs.displayState(
    label: "Services State",
    initialOption: DisplayState.fewItems,
  );

  return servicesPageStory(servicesState: servicesState);
}

@widgetbook.UseCase(name: "Runtime topology", type: ServicesPage)
Widget servicesPageTopologyUseCase(BuildContext context) {
  final distributed = context.knobs.boolean(
    label: "Distributed",
    initialValue: true,
  );
  return servicesPageStory(
    topology: topologyScenario(distributed: distributed),
  );
}

@widgetbook.UseCase(name: "Offline topology", type: ServicesPage)
Widget servicesPageOfflineTopologyUseCase(BuildContext context) {
  final topology = topologyScenario();
  return servicesPageStory(
    topology: topology,
    topologyServices: topologyScenarioServices(topology, connected: false),
  );
}

@widgetbook.UseCase(name: "Dense topology", type: ServicesPage)
Widget servicesPageDenseTopologyUseCase(BuildContext context) {
  final topology = denseTopologyScenario();
  return servicesPageStory(topology: topology);
}

Widget servicesPageStory({
  DisplayState servicesState = DisplayState.fewItems,
  OrganizationTopology? topology,
  List<Service>? topologyServices,
}) {
  return FakeApp(
    overrides: [
      organizationTopologyStreamProvider.overrideWith(
        topology == null ? _EmptyTopology.new : () => _StoryTopology(topology),
      ),
      servicesProvider.overrideWith(
        topology == null
            ? () => _StoryServices(displayState: servicesState)
            : () => _TopologyServices(
                topologyServices ?? topologyScenarioServices(topology),
              ),
      ),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.fewItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: ServicesPage()),
  );
}

class _StoryServices extends ServicesMock {
  _StoryServices({required super.displayState});

  @override
  Stream<List<Service>> build() async* {
    await for (final services in super.build()) {
      yield [
        for (final service in services)
          service.copyWith(
            role: CustomServiceRole(name: "integration", version: "1.0.0"),
          ),
      ];
    }
  }
}

class _TopologyServices extends Services {
  _TopologyServices(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build() => Stream.value(services);
}

class _EmptyTopology extends OrganizationTopologyStream {
  @override
  Stream<OrganizationTopology> build() async* {
    yield OrganizationTopology.empty;
  }
}

class _StoryTopology extends OrganizationTopologyStream {
  _StoryTopology(this.topology);

  final OrganizationTopology topology;

  @override
  Stream<OrganizationTopology> build() async* {
    yield topology;
  }
}
