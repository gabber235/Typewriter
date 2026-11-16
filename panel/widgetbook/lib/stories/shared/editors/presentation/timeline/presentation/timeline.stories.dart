import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The whole frame editor: track headers beside the ruler and plane, a
/// header width handle, scroll and pinch to pan and zoom, and cues to drag
/// and resize. A dropped cue stays where it lands; a read only timeline
/// offers no edits.
@widgetbook.UseCase(name: "Tracks and cues", type: Timeline)
Widget timelineUseCase(BuildContext context) {
  final cues = context.knobs.cues();
  final readOnly = context.knobs.boolean(label: "Read only");
  final width = context.knobs.width(const {"Wide": 900, "Narrow": 360});
  return Story(
    context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
    at: PanelLocation.component(
      StoryTimeline(
        cues: cues,
        editable: !readOnly,
        width: width,
        builder: (label) =>
            (_, data) => TimelineCue(
              data: data,
              label: label,
              selectableId: TestSelectableIdentifier(id: label),
            ),
      ),
    ),
  );
}
