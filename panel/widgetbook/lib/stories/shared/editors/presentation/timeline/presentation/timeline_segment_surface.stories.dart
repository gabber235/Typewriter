import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Segments on their own surface: dragging the body moves one, dragging an
/// edge resizes it, and touching segments resize together. A segment that
/// holds others keeps room for its edge handles.
@widgetbook.UseCase(name: "Move and resize", type: TimelineSegmentSurface)
Widget timelineSegmentSurfaceUseCase(BuildContext context) {
  final cues = context.knobs.object.segmented(
    label: "Cues",
    options: const [StoryTimelineCues.adjacent, StoryTimelineCues.nested],
    initialOption: StoryTimelineCues.adjacent,
    labelBuilder: (cues) => cues.label,
  );
  final strong = context.knobs.boolean(label: "Strong outline");
  final readOnly = context.knobs.boolean(label: "Read only");
  return Story(
    const [],
    at: PanelLocation.component(
      StoryTimeline(
        cues: cues,
        editable: !readOnly,
        builder: (label) => (context, data) {
          final color = data.element.color;
          if (data.element is! TimelineSegment) {
            return storyCueLabel(context, label, color);
          }
          return TimelineSegmentSurface(
            data: data,
            fillColor: color.withValues(alpha: 0.2),
            outlineColor: strong ? color : color.withValues(alpha: 0.4),
            outlineWidth: strong ? 2 : 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ),
          );
        },
      ),
    ),
  );
}
