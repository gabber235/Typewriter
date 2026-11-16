import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Keyframes on their own surface: a diamond that a drag moves to another
/// frame. Segments draw as plain labels here.
@widgetbook.UseCase(name: "Move", type: TimelineKeyframeSurface)
Widget timelineKeyframeSurfaceUseCase(BuildContext context) {
  final strong = context.knobs.boolean(label: "Strong outline");
  final readOnly = context.knobs.boolean(label: "Read only");
  return Story(
    context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
    at: PanelLocation.component(
      StoryTimeline(
        cues: StoryTimelineCues.scene,
        editable: !readOnly,
        builder: (label) => (context, data) {
          final color = data.element.color;
          if (data.element is! TimelineKeyframe) {
            return storyCueLabel(context, label, color);
          }
          return TimelineKeyframeSurface(
            data: data,
            fillColor: color,
            outlineColor: strong
                ? Theme.of(context).colorScheme.onSurface
                : color.withValues(alpha: 0.4),
            outlineWidth: strong ? 2 : 1,
            child: const SizedBox.expand(),
          );
        },
      ),
    ),
  );
}
