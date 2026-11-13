import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [ElasticSwitcher] swapping a card's content: pick another Content to
/// watch the new one arrive with `loadIn`, the old leave with `listOut` and
/// the card follow the new size. Nothing removes the content.
@widgetbook.UseCase(name: "Default", type: ElasticSwitcher)
Widget elasticSwitcherUseCase(BuildContext context) {
  final content = context.knobs.object.segmented(
    label: "Content",
    options: const ["Short", "Tall", "Nothing"],
    initialOption: "Short",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      StoryCard(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElasticSwitcher(
            child: switch (content) {
              "Tall" => const Column(
                key: ValueKey("tall"),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Three members"),
                  Text("Ada, owner"),
                  Text("Grace, editor"),
                  Text("Linus, viewer"),
                ],
              ),
              "Nothing" => null,
              _ => const Text("One member", key: ValueKey("short")),
            },
          ),
        ),
      ),
    ),
  );
}
