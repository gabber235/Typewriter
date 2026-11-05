import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: RealmSuspensionBarrier)
Widget realmSuspensionBarrierUseCase(BuildContext context) {
  final connection = context.knobs.object.dropdown(
    label: "Connection",
    options: const [
      RealmConnectionState.offline,
      RealmConnectionState.checking,
      RealmConnectionState.unavailable,
      RealmConnectionState.online,
    ],
    initialOption: RealmConnectionState.offline,
    labelBuilder: (state) => state.name,
  );
  final known = context.knobs.boolean(label: "Realm known");
  final retry = context.knobs.boolean(label: "Retry");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 720,
        height: 480,
        child: RealmSuspensionBarrier(
          interaction: RealmInteractionState(connectionState: connection),
          realm: known
              ? completeTopologyScenario().topology.realms.first
              : null,
          onRetry: retry ? () {} : null,
          child: Card(
            child: Center(
              child: FilledButton(
                onPressed: () {},
                child: const Text("Edit dialogue"),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
