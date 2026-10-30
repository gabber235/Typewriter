import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _message =
    "The Realm did not answer within 10 seconds. "
    "TimeoutException after 0:00:10.000000: Future not completed\n"
    "  at RealmConnection.request (realm_connection.dart:118)\n"
    "  at AuthoringCapabilities.observe (authoring_capabilities.dart:64)";

@widgetbook.UseCase(name: "Default", type: ErrorScreen)
Widget errorScreenUseCase(BuildContext context) {
  final size = context.knobs.object.segmented(
    label: "Size",
    options: const ["Full", "Small"],
    initialOption: "Full",
  );
  final action = context.knobs.boolean(label: "Retry action");
  final retry = action
      ? FilledButton(onPressed: () {}, child: const Text("Retry"))
      : null;
  return Story(
    context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
    at: PanelLocation.component(switch (size) {
      "Small" => ErrorScreen.small(
        title: "Realm unavailable",
        message: _message,
        child: retry,
      ),
      _ => ErrorScreen(
        title: "Realm unavailable",
        message: _message,
        child: retry,
      ),
    }),
  );
}
