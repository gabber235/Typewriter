import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// A whole search inside its root, as the search overlay and inline fields
/// show it: the focused query field, the outcome of the last command, the
/// result tree, the key hints and the preview. Typing narrows the pages;
/// Enter opens the highlighted one.
///
/// Reduced motion is left out: under it the query bar throws
/// "RenderAnimatedSize was mutated in its own performLayout"
/// (query_bar_view.dart:13).
@widgetbook.UseCase(name: "Default", type: SearchBody)
Widget searchBodyUseCase(BuildContext context) {
  final snapshot = context.knobs.searchResults();
  final commandState = context.knobs.searchCommand();
  final preview = context.knobs.object.segmented(
    label: "Preview",
    options: ["None", ...storyPreviewAnswers.keys],
    initialOption: "None",
  );
  final width = context.knobs.width(const {"Overlay": 880, "Narrow": 360});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 640,
        child: StorySearchRoot(
          snapshot: snapshot,
          commandState: commandState,
          previewed: preview == "None" ? null : storyFirstResultId,
          previewAnswer: storyPreviewAnswers[preview],
          child: SearchBody(
            searchHint: "Search pages",
            rowRenderers: storySearchRowRenderers,
            previewRenderers: storySearchPreviewRenderers,
          ),
        ),
      ),
    ),
  );
}
