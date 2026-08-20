import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/topology_scenarios.dart";

@widgetbook.UseCase(name: "Topology workspace", type: TopologyView)
Widget topologyViewUseCase(BuildContext context) {
  final distributed = context.knobs.boolean(
    label: "Distributed",
    initialValue: true,
  );
  return FakeApp(
    overrides: [...appearanceProviderOverrides()],
    child: SizedBox(
      width: 1180,
      height: 720,
      child: TopologyView(topology: topologyScenario(distributed: distributed)),
    ),
  );
}

@widgetbook.UseCase(name: "Interactive graph", type: TopologyGraph)
Widget topologyGraphUseCase(BuildContext context) {
  final topology = topologyScenario();
  return FakeApp(
    overrides: [...appearanceProviderOverrides()],
    child: SizedBox(
      width: 900,
      height: 620,
      child: TopologyGraph(
        topology: topology,
        selectedHostId: topology.hosts.last.hostId,
        onHostSelected: (_) {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: "Paper host configuration",
  type: HostExecutionInspector,
)
Widget hostExecutionInspectorUseCase(BuildContext context) {
  final topology = topologyScenario(distributed: false);
  return FakeApp(
    overrides: [...appearanceProviderOverrides()],
    child: SizedBox(
      width: 390,
      height: 720,
      child: HostExecutionInspector(
        host: topology.hosts.single,
        topology: topology,
        onSave: (_) async {},
      ),
    ),
  );
}
