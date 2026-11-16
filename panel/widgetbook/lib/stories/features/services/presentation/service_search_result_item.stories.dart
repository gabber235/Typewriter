import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// A service in the primary search: its name over the state its card on the
/// services page shows, Connected or Offline for a custom service and the
/// host's runtime state for a host.
@widgetbook.UseCase(name: "Default", type: ServiceSearchResultItem)
Widget serviceSearchResultItemUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  final hosts = {
    for (final host in scenario.topology.hosts) host.serviceId: host,
  };
  final items = [
    for (final service in scenario.services)
      ServiceSearchItem(
        service: service,
        host: hosts[service.serviceId],
        connected: service.isConnectedAt(clock.now()),
      ),
  ];
  final item = context.knobs.object.dropdown(
    label: "Service",
    options: items,
    initialOption: items.first,
    labelBuilder: (item) => item.service.displayName,
  );
  final state = context.knobs.object.segmented(
    label: "Row",
    options: storyRowStates,
    initialOption: storyRowStates.first,
  );
  final width = context.knobs.width(const {"Wide": 560, "Narrow": 280});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: ServiceSearchResultItem(
          item: item,
          row: storyRowContext(
            serviceSearchResultType,
            item,
            title: item.service.displayName,
            state: state,
          ),
        ),
      ),
    ),
  );
}
