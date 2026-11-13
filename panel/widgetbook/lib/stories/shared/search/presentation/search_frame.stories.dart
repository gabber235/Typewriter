import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The window widths that place the preview, by the name a story knob
/// shows: a bottom sheet under 880 px, a column inside the frame, then a
/// card beside it.
const _windows = {
  "Sheet": Size(720, 800),
  "Inline": Size(1200, 800),
  "Beside": Size(1800, 900),
};

/// The layout of a search: the query on top, the results under it, the key
/// hints at the bottom, and the preview of the highlighted result where
/// the window has room for it.
@widgetbook.UseCase(name: "Default", type: SearchFrame)
Widget searchFrameUseCase(BuildContext context) {
  final window = context.knobs.object.segmented(
    label: "Window",
    options: _windows.keys.toList(),
    initialOption: "Inline",
  );
  final preview = context.knobs.object.segmented(
    label: "Preview",
    options: ["None", ...storyPreviewAnswers.keys],
    initialOption: "Data",
  );
  final results = context.knobs.object.segmented(
    label: "Results",
    options: const ["Sections", "Many", "Empty"],
    initialOption: "Sections",
  );
  final size = _windows[window]!;
  return Story(
    const [],
    at: PanelLocation.component(
      FittedBox(
        child: SizedBox.fromSize(
          size: size,
          child: StorySearchRoot(
            snapshot: storySearchSnapshots[results]!,
            previewed: preview == "None" ? null : storyFirstResultId,
            previewAnswer: storyPreviewAnswers[preview],
            child: const _Frame(),
          ),
        ),
      ),
    ),
  );
}

/// The frame around the search's own query bar, results and preview.
class _Frame extends ConsumerWidget {
  const _Frame();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    return SearchFrame(
      queryBar: QueryBar(
        query: controller.query,
        selectors: const [],
        onQueryChanged: controller.updateQuery,
        inputDecoration: const InputDecoration(
          hintText: "Search pages",
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      searchResults: SearchTreeResults(rowRenderers: storySearchRowRenderers),
      actionBar: const ActionRow(),
      preview: controller.currentPreview == null
          ? null
          : SearchPreview(previewRenderers: storySearchPreviewRenderers),
    );
  }
}
