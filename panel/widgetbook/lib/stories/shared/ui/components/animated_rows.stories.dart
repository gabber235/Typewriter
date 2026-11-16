import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/ui/row_focus.stories.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Cards in [SliverAnimatedRows]: rows added from elsewhere slide in with
/// `rowIn`, removed rows squash shut with `listOut`, and Send focused
/// strikes a row through while it is sent.
@widgetbook.UseCase(name: "Cards", type: SliverAnimatedRows)
Widget sliverAnimatedRowsUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: const PanelLocation.component(
      RowFocusStory(layout: RowFocusLayout.cards),
    ),
  );
}
