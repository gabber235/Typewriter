import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The preview of the highlighted result: its renderer while the preview
/// loads, with its data, or with the failure. A result whose kind has no
/// preview renderer says so, its illustration shrinking to fit the card.
@widgetbook.UseCase(name: "Default", type: SearchPreview)
Widget searchPreviewUseCase(BuildContext context) {
  const noRenderer = "No renderer";
  final answer = context.knobs.object.segmented(
    label: "Preview",
    options: [...storyPreviewAnswers.keys, noRenderer],
    initialOption: "Data",
  );
  final width = context.knobs.width(const {"Card": 320, "Narrow": 220});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 320,
        child: StorySearchRoot(
          snapshot: storySearchSnapshots["Few"]!,
          previewed: storyFirstResultId,
          previewAnswer: storyPreviewAnswers[answer],
          child: SearchPreview(
            previewRenderers: answer == noRenderer
                ? const {}
                : storySearchPreviewRenderers,
          ),
        ),
      ),
    ),
  );
}
