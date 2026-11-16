import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [SectionTitle] over its rows; a long title ends in an ellipsis on one
/// line instead of wrapping.
@widgetbook.UseCase(name: "Default", type: SectionTitle)
Widget sectionTitleUseCase(BuildContext context) {
  final title = context.knobs.object.segmented(
    label: "Title",
    options: const [
      "Join requests",
      "Join requests waiting for an organization owner to answer them",
    ],
    initialOption: "Join requests",
  );
  final width = context.knobs.width(const {"Wide": 420, "Narrow": 200});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: title),
            const PanelRow(title: Text("Grace")),
            const PanelRow(title: Text("Linus")),
          ],
        ),
      ),
    ),
  );
}
