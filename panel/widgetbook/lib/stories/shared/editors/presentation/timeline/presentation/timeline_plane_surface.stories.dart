import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The plane with its pointer navigation and no headers or ruler: drag or
/// scroll to pan, pinch or scroll with Control to zoom. The cues are plain
/// labels, so every gesture lands on the plane.
@widgetbook.UseCase(name: "Pan and zoom", type: TimelinePlaneSurface)
Widget timelinePlaneSurfaceUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    TimelinePlaneSurfaceStory(
      cues: context.knobs.cues(initial: StoryTimelineCues.many),
      width: context.knobs.width(const {"Wide": 700, "Narrow": 240}),
    ),
  ),
);

/// A [TimelinePlaneSurface] over [cues] whose controller the story owns,
/// laid out the way a [Timeline] lays out its plane.
class TimelinePlaneSurfaceStory extends HookWidget {
  const TimelinePlaneSurfaceStory({
    required this.cues,
    required this.width,
    super.key,
  });

  final StoryTimelineCues cues;
  final double width;

  static const _height = 320.0;

  @override
  Widget build(BuildContext context) {
    final controller = useTimelineController(
      tickerProvider: useSingleTickerProvider(),
    );
    useListenable(controller);
    final parts = storyTimelineParts(
      context,
      cues: cues,
      size: Size(width, _height),
      pixelsPerFrame: controller.pixelsPerFrame,
      horizontalOffset: controller.horizontalOffset,
      verticalOffset: controller.verticalOffset,
    );
    return SizedBox(
      width: width,
      height: _height,
      child: TimelinePlaneSurface(
        controller: controller,
        style: parts.style,
        viewport: parts.viewport,
        placement: parts.placement,
        onCommitPreviews: (_) async {},
        resolveMovePreviews: (_) => const [],
        resolveResizePreviews: (_, _) => const [],
      ),
    );
  }
}
