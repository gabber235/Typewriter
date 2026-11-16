import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The row a search shows for a result whose kind has no row renderer: its
/// title, or its id without one, and the renderer it is missing.
@widgetbook.UseCase(name: "Default", type: MissingSearchResultRendererRow)
Widget missingSearchResultRendererRowUseCase(BuildContext context) {
  final title = context.knobs.object.segmented(
    label: "Title",
    options: const ["Title", "Long title", "Only id"],
    initialOption: "Title",
  );
  final width = context.knobs.width(const {"Wide": 560, "Narrow": 260});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: MissingSearchResultRendererRow(
          result: SearchResult(
            id: "extension:quest_marker_with_a_long_identifier",
            type: const SearchResultType(
              id: "extension.quest_marker",
              rowRendererId: "extension.quest_marker.row",
              label: "Quest marker",
            ),
            payload: "marker",
            title: switch (title) {
              "Long title" =>
                "The quest marker above the mayor's house in the lost village",
              "Only id" => null,
              _ => "Quest marker",
            },
          ),
        ),
      ),
    ),
  );
}
