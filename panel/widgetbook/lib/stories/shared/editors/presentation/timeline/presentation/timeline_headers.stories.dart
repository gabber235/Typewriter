import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/editors/timeline.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The header widths a header story offers.
const _headerWidths = {"Desktop": 200.0, "Mobile": 100.0};

/// The corner above the track headers, as tall as the ruler beside it.
@widgetbook.UseCase(name: "Corner", type: TimelineTopLeftHeader)
Widget timelineTopLeftHeaderUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    StoryTimelinePart(
      width: context.knobs.width(_headerWidths),
      plane: const Size(600, 300),
      builder: (_, parts) =>
          TimelineTopLeftHeader(viewport: parts.viewport, style: parts.style),
    ),
  ),
);

/// The names of the tracks beside the plane, each as tall as its lanes.
/// Scrolling the plane moves them up with it; long names cut off.
@widgetbook.UseCase(name: "Track names", type: TimelineTrackHeaders)
Widget timelineTrackHeadersUseCase(BuildContext context) {
  final cues = context.knobs.cues();
  final scrolled = context.knobs.boolean(label: "Scrolled");
  final width = context.knobs.width(_headerWidths);
  return Story(
    const [],
    at: PanelLocation.component(
      StoryTimelinePart(
        width: width,
        height: 320,
        plane: const Size(600, 320),
        cues: cues,
        verticalOffset: scrolled ? 120 : 0,
        builder: (_, parts) => TimelineTrackHeaders(
          placement: parts.placement,
          viewport: parts.viewport,
          style: parts.style,
        ),
      ),
    ),
  );
}
