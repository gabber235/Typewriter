import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Labelled cues as an editor page shows them. A selectable cue joins the
/// selection on a press and opens on a double press; otherwise a press
/// opens it. The last opened cue shows above the timeline.
@widgetbook.UseCase(name: "Select and open", type: TimelineCue)
Widget timelineCueUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    TimelineCueStory(
      cues: context.knobs.object.segmented(
        label: "Cues",
        options: const [StoryTimelineCues.scene, StoryTimelineCues.longNames],
        initialOption: StoryTimelineCues.scene,
        labelBuilder: (cues) => cues.label,
      ),
      selectable: context.knobs.boolean(
        label: "Selectable",
        initialValue: true,
      ),
      width: context.knobs.width(const {"Wide": 900, "Narrow": 360}),
    ),
  ),
);

/// A [StoryTimeline] of [TimelineCue]s that names the cue last opened.
class TimelineCueStory extends HookWidget {
  const TimelineCueStory({
    required this.cues,
    required this.selectable,
    required this.width,
    super.key,
  });

  final StoryTimelineCues cues;
  final bool selectable;
  final double width;

  @override
  Widget build(BuildContext context) {
    final opened = useState<String?>(null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(switch (opened.value) {
          null => "Nothing opened",
          final label => "Opened $label",
        }),
        StoryTimeline(
          cues: cues,
          width: width,
          builder: (label) =>
              (_, data) => TimelineCue(
                data: data,
                label: label,
                selectableId: selectable
                    ? TestSelectableIdentifier(id: label)
                    : null,
                onOpen: () => opened.value = label,
              ),
        ),
      ],
    );
  }
}
