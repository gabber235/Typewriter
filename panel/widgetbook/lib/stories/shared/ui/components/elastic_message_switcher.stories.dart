import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [ElasticMessageSwitcher] under a field: pick another Message to watch
/// it drop in while the old one leaves and the space follows; None leaves
/// no space.
@widgetbook.UseCase(name: "Default", type: ElasticMessageSwitcher)
Widget elasticMessageSwitcherUseCase(BuildContext context) {
  final message = context.knobs.object.segmented(
    label: "Message",
    options: const ["None", "Short", "Long"],
    initialOption: "Short",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          final style = context.text.sentenceSmall.copyWith(
            color: context.colors.dangerText,
          );
          return SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Join code name"),
                ElasticMessageSwitcher(
                  child: switch (message) {
                    "Short" => Text(
                      "A name is required.",
                      key: const ValueKey("short"),
                      style: style,
                    ),
                    "Long" => Text(
                      "Another join code in this organization already uses "
                      "this name. Pick a name nobody uses yet.",
                      key: const ValueKey("long"),
                      style: style,
                    ),
                    _ => null,
                  },
                ),
                const Text("Next field"),
              ],
            ),
          );
        },
      ),
    ),
  );
}
