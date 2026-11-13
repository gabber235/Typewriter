import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// What a search shows instead of results: placeholders while the first
/// results load, the source's failures, its guidance, or that nothing
/// matched.
@widgetbook.UseCase(name: "Default", type: SearchResultEmptyState)
Widget searchResultEmptyStateUseCase(BuildContext context) {
  final state = context.knobs.object.dropdown(
    label: "Snapshot",
    options: const [
      "Loading",
      "Empty",
      "Guidance",
      "Error",
      "Errors",
      "Failed without a summary",
    ],
    initialOption: "Empty",
  );
  final width = context.knobs.width(const {"Wide": 640, "Narrow": 300});
  final snapshot = switch (state) {
    "Errors" => SearchSourceSnapshot.error(
      nodes: const [],
      errorSummaries: storySearchErrors,
    ),
    "Failed without a summary" => const SearchSourceSnapshot(
      status: SearchSourceStatus.error,
      nodes: [],
    ),
    _ => storySearchSnapshots[state]!,
  };
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 480,
        child: SearchResultEmptyState(snapshot: snapshot),
      ),
    ),
  );
}
