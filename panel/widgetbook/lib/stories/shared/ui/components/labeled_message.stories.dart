import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [LabeledMessage] between two lines of text: switching between parts
/// grows or shrinks its space with `loadIn`, and Empty takes no space at
/// all. The long message wraps at narrow width.
@widgetbook.UseCase(name: "Default", type: LabeledMessage)
Widget labeledMessageUseCase(BuildContext context) {
  final parts = context.knobs.object.segmented(
    label: "Parts",
    options: const ["Both", "Label", "Message", "Long", "Empty"],
    initialOption: "Both",
  );
  final width = context.knobs.width(const {"Wide": 420, "Narrow": 220});
  final (label, message) = switch (parts) {
    "Label" => ("Nothing found", null),
    "Message" => (null, "Try another word."),
    "Long" => (
      "The realm did not answer",
      "Search results from this realm are missing until it answers again. "
          "Results from other realms are still shown.",
    ),
    "Empty" => (null, null),
    _ => ("Nothing found", "Try another word."),
  };
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Text("Above"),
            LabeledMessage(label: label, message: message),
            const Text("Below"),
          ],
        ),
      ),
    ),
  );
}
