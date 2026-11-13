import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Realm content under the veil that blocks it while the Realm is offline,
/// checked or unavailable: the content stays readable behind a card naming
/// the Realm, with Retry when the caller offers one. Online, the veil fades
/// away.
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
  final width = context.knobs.width(const {"Wide": 720, "Narrow": 320});
  return Story(
    [...context.knobs.motion()],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 480,
        child: RealmSuspensionBarrier(
          interaction: RealmInteractionState(connectionState: connection),
          realm: known
              ? completeTopologyScenario().topology.realms.first
              : null,
          onRetry: retry ? () {} : null,
          child: Card(
            child: Center(
              child: Button(
                face: ButtonFace.filled,
                label: "Edit dialogue",
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A small control that dims and stops answering while the Realm is
/// suspended, and fades back when it returns.
@widgetbook.UseCase(name: "Default", type: RealmSuspensionInline)
Widget realmSuspensionInlineUseCase(BuildContext context) {
  final suspended = context.knobs.boolean(
    label: "Suspended",
    initialValue: true,
  );
  return Story(
    [...context.knobs.motion()],
    at: PanelLocation.component(
      RealmSuspensionInline(
        suspended: suspended,
        child: Button(
          face: ButtonFace.outlined,
          icon: const Icon(Icons.publish_rounded),
          label: "Publish",
          onPressed: () {},
        ),
      ),
    ),
  );
}
