import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The frame ruler above the plane: close zoom labels every few frames,
/// far zoom spaces its ticks out, and a scrolled plane starts its labels
/// later.
@widgetbook.UseCase(name: "Zoom and scroll", type: TimelineRuler)
Widget timelineRulerUseCase(BuildContext context) {
  final zoom = context.knobs.zoom(close: 24, far: 0.5);
  final scrolled = context.knobs.boolean(label: "Scrolled");
  final width = context.knobs.width(const {"Wide": 700, "Narrow": 240});
  return Story(
    const [],
    at: PanelLocation.component(
      StoryTimelinePart(
        width: width,
        plane: Size(width, 0),
        pixelsPerFrame: zoom,
        horizontalOffset: scrolled ? 1200 : 0,
        builder: (_, parts) =>
            TimelineRuler(viewport: parts.viewport, style: parts.style),
      ),
    ),
  );
}
