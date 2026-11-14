import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The plane that paints the track rows and frame grid and places each
/// visible cue at its frames; a segment that holds others paints the room
/// they sit in. Nothing here moves: the plane only draws what it is given.
@widgetbook.UseCase(name: "Placed cues", type: TimelinePlane)
Widget timelinePlaneUseCase(BuildContext context) {
  final cues = context.knobs.cues();
  final zoom = context.knobs.zoom(close: 12, far: 2);
  final width = context.knobs.width(const {"Wide": 700, "Narrow": 240});
  return Story(
    const [],
    at: PanelLocation.component(
      ClipRect(
        child: StoryTimelinePart(
          width: width,
          height: 320,
          plane: Size(width, 320),
          cues: cues,
          pixelsPerFrame: zoom,
          builder: (context, parts) => TimelinePlane(
            placement: parts.placement,
            viewport: parts.viewport,
            style: parts.style,
            children: [
              for (final placed in parts.placement.visibleElements)
                TimelinePlaneChild(
                  key: ValueKey(placed.element.id),
                  rect: placed.rect,
                  childRect: placed.childrenRect,
                  color: placed.element.color,
                  child: storyCueLabel(
                    context,
                    placed.element.id.id,
                    placed.element.color,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
