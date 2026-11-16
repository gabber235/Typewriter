import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A tooltip that waits briefly on hover, then grows out of its control with
/// panelIn and leaves with panelOut; a long message wraps. Motion switches to
/// reduced motion.
@widgetbook.UseCase(name: "Default", type: PanelTooltip)
Widget panelTooltipUseCase(BuildContext context) {
  final message = context.knobs.object.segmented(
    label: "Message",
    options: const [
      "Published to every server in this Realm",
      "Published to every server in this Realm. Players see the change the "
          "next time they join, and nobody online loses progress.",
    ],
    initialOption: "Published to every server in this Realm",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Center(
        child: PanelTooltip(message: message, child: const Icon(Icons.public)),
      ),
    ),
  );
}
