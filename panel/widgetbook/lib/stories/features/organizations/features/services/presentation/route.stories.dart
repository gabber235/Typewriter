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

Widget servicesPageStory({
  DisplayState servicesState = DisplayState.fewItems,
  OrganizationTopology? topology,
}) {
  return FakeApp(
    overrides: [
      organizationTopologyStreamProvider.overrideWith(
        topology == null ? _EmptyTopology.new : () => _StoryTopology(topology),
      ),
      servicesProvider.overrideWith(
        topology == null
            ? () => _StoryServices(displayState: servicesState)
            : () => _TopologyServices(topology),
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
  _TopologyServices(this.topology);

  final OrganizationTopology topology;

  @override
  Stream<List<Service>> build() =>
      Stream.value(topologyScenarioServices(topology));
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
