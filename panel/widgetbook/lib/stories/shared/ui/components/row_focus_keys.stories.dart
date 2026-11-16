import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/ui/row_focus.stories.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The keys of a table of row stops, which [RowFocusKeys] gives an
/// [AnimatedTable]: Up, Down, J and K move between rows, Home and End reach
/// the ends, Right and L enter the row's Member cell, Tab leaves the table.
@widgetbook.UseCase(name: "Table keys", type: RowFocusKeys)
Widget rowFocusKeysUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: const PanelLocation.component(RowFocusStory()),
  );
}
