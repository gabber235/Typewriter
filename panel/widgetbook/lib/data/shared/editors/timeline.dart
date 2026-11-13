/// The cues the timeline stories show, and the timeline parts a story of
/// one part builds around it.
library;

import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";

/// One cue of a story timeline: a segment from [start] to [end] on [track],
/// or a keyframe at [start] when [end] is null. A segment's [children] count
/// their frames from the segment's start.
final class StoryCue {
  const StoryCue.segment(
    this.label, {
    required this.track,
    required this.start,
    required int this.end,
    this.children = const [],
  });

  const StoryCue.keyframe(this.label, {required this.track, required int at})
    : start = at,
      end = null,
      children = const [];

  final String label;
  final String track;
  final int start;
  final int? end;
  final List<StoryCue> children;

  /// This cue moved to the frames [start] to [end].
  StoryCue movedTo(int start, int end) => this.end == null
      ? StoryCue.keyframe(label, track: track, at: start)
      : StoryCue.segment(
          label,
          track: track,
          start: start,
          end: end,
          children: children,
        );
}

/// The sets of cues a timeline story knob offers.
enum StoryTimelineCues {
  /// One track with nothing on it.
  empty("Empty"),

  /// A scene track and a track of marks, as a short cinematic has.
  scene("Scene"),

  /// Segments that touch, so resizing one edge moves its neighbour.
  adjacent("Adjacent"),

  /// A chapter segment holding its own scenes.
  nested("Nested"),

  /// Twelve tracks of cues, more than the plane shows at once.
  many("Many"),

  /// Track and cue names longer than their room.
  longNames("Long names");

  const StoryTimelineCues(this.label);

  final String label;

  /// The cues of this set.
  List<StoryCue> get cues => switch (this) {
    empty => const [],
    scene => const [
      StoryCue.segment("Arrival", track: "Scenes", start: 0, end: 30),
      StoryCue.segment("Market", track: "Scenes", start: 40, end: 90),
      StoryCue.keyframe("Bell", track: "Marks", at: 10),
      StoryCue.keyframe("Door", track: "Marks", at: 60),
    ],
    adjacent => const [
      StoryCue.segment("Arrival", track: "Scenes", start: 0, end: 30),
      StoryCue.segment("Market", track: "Scenes", start: 31, end: 70),
      StoryCue.segment("Farewell", track: "Scenes", start: 71, end: 100),
    ],
    nested => const [
      StoryCue.segment(
        "Chapter one",
        track: "Chapters",
        start: 10,
        end: 110,
        children: [
          StoryCue.segment("Intro", track: "Chapters", start: 0, end: 30),
          StoryCue.segment("Fight", track: "Chapters", start: 31, end: 80),
        ],
      ),
      StoryCue.keyframe("Bell", track: "Marks", at: 50),
    ],
    many => [
      for (var track = 1; track <= 12; track++) ...[
        for (var cue = 0; cue < 4; cue++)
          StoryCue.segment(
            "Shot $track.${cue + 1}",
            track: "Camera $track",
            start: cue * 50 + track * 3,
            end: cue * 50 + track * 3 + 35,
          ),
        StoryCue.keyframe("Cut $track", track: "Camera $track", at: 220),
      ],
    ],
    longNames => const [
      StoryCue.segment(
        "The mayor walks slowly across the crowded village square at dusk",
        track: "Cinematic camera path through the old village square",
        start: 0,
        end: 40,
      ),
      StoryCue.keyframe(
        "Church bell rings for the evening gathering",
        track: "Sound effects and ambient village noise",
        at: 20,
      ),
    ],
  };

  /// The track names this set shows, so an empty set still has a track.
  List<String> get tracks => switch (this) {
    empty => const ["Scenes"],
    _ => [
      ...{for (final cue in cues) cue.track},
    ],
  };
}

/// What a story timeline builds for the cue named by its label.
typedef StoryCueBuilder = TimelineElementBuilder Function(String label);

/// The timeline data of [cues] on [tracks], each cue built by [builder].
TimelineData storyTimelineData({
  required List<String> tracks,
  required List<StoryCue> cues,
  required StoryCueBuilder builder,
}) {
  TimelineElement element(StoryCue cue, TimelineIdentifier? parent) {
    final id = TimelineIdentifier(cue.label);
    if (cue.end case final end?) {
      return TimelineSegment(
        id: id,
        startFrame: cue.start,
        endFrame: end,
        parentId: parent,
        color: parent == null ? Colors.blue : Colors.teal,
        children: [for (final child in cue.children) element(child, id)],
        builder: builder(cue.label),
      );
    }
    return TimelineKeyframe(
      id: id,
      frame: cue.start,
      parentId: parent,
      color: Colors.orange,
      builder: builder(cue.label),
    );
  }

  return TimelineData(
    tracks: [
      for (final track in tracks)
        TimelineTrack(
          id: TimelineIdentifier(track),
          header: (_) => Text(track, overflow: TextOverflow.ellipsis),
          elements: [
            for (final cue in cues.where((cue) => cue.track == track))
              element(cue, null),
          ],
        ),
    ],
  );
}

/// A timeline over [cues] at [width], above the current interaction mode,
/// that keeps every commit: a moved cue stays where it was dropped. Without
/// [editable] the caller cannot save, so the timeline offers no edits.
class StoryTimeline extends HookWidget {
  const StoryTimeline({
    required this.cues,
    required this.builder,
    this.editable = true,
    this.width = 900,
    this.height = 360,
    super.key,
  });

  final StoryTimelineCues cues;
  final StoryCueBuilder builder;
  final bool editable;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final moved = useState(<String, (int, int)>{});
    StoryCue placed(StoryCue cue) => switch (moved.value[cue.label]) {
      (final start, final end) => cue.movedTo(start, end),
      null => cue,
    };
    final data = storyTimelineData(
      tracks: cues.tracks,
      cues: [for (final cue in cues.cues) placed(cue)],
      builder: builder,
    );
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModeDisplayWidget(),
          Expanded(
            child: Timeline(
              data: data,
              onElementsCommited: editable
                  ? (changes) async => moved.value = {
                      ...moved.value,
                      for (final change in changes)
                        change.id.id: (change.startFrame, change.endFrame),
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The parts a timeline builds from [data] at [size]: its style, the
/// viewport of its plane, and where each track and cue lands.
typedef StoryTimelineParts = ({
  TimelineStyle style,
  TimelineViewport viewport,
  TimelinePlacementResult placement,
});

/// The [StoryTimelineParts] of [cues] in a plane of [size], zoomed to
/// [pixelsPerFrame] and scrolled by [horizontalOffset] and
/// [verticalOffset]. Each cue is drawn as its label; without [cues] the
/// timeline has no tracks.
StoryTimelineParts storyTimelineParts(
  BuildContext context, {
  required Size size,
  StoryTimelineCues? cues,
  double pixelsPerFrame = 6,
  double horizontalOffset = 0,
  double verticalOffset = 0,
}) {
  final data = cues == null
      ? TimelineData(tracks: const [])
      : storyTimelineData(
          tracks: cues.tracks,
          cues: cues.cues,
          builder: (label) =>
              (context, data) =>
                  storyCueLabel(context, label, data.element.color),
        );
  final style = TimelineStyle.fallback(Theme.of(context));
  final viewport = TimelineViewport(
    headerWidth: 200,
    planeWidth: size.width,
    planeHeight: size.height,
    horizontalOffset: horizontalOffset,
    verticalOffset: verticalOffset,
    pixelsPerFrame: pixelsPerFrame,
  );
  return (
    style: style,
    viewport: viewport,
    placement: const TimelinePlacementEngine().build(
      layout: const TimelineLayoutEngine().build(data: data),
      viewport: viewport,
      style: style,
    ),
  );
}

/// One timeline part at [width] and [height], built by [builder] from the
/// [storyTimelineParts] of [cues] in a plane of [plane] size.
class StoryTimelinePart extends StatelessWidget {
  const StoryTimelinePart({
    required this.width,
    required this.plane,
    required this.builder,
    this.height,
    this.cues,
    this.pixelsPerFrame = 6,
    this.horizontalOffset = 0,
    this.verticalOffset = 0,
    super.key,
  });

  final double width;
  final double? height;
  final Size plane;
  final StoryTimelineCues? cues;
  final double pixelsPerFrame;
  final double horizontalOffset;
  final double verticalOffset;
  final Widget Function(BuildContext context, StoryTimelineParts parts) builder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: builder(
        context,
        storyTimelineParts(
          context,
          size: plane,
          cues: cues,
          pixelsPerFrame: pixelsPerFrame,
          horizontalOffset: horizontalOffset,
          verticalOffset: verticalOffset,
        ),
      ),
    );
  }
}

/// Knobs that shape timeline stories.
extension TimelineStoryKnobs on KnobsBuilder {
  /// The Cues dropdown over every [StoryTimelineCues]; returns the chosen
  /// set, [initial] at start.
  StoryTimelineCues cues({
    StoryTimelineCues initial = StoryTimelineCues.scene,
  }) => object.dropdown(
    label: "Cues",
    options: StoryTimelineCues.values,
    initialOption: initial,
    labelBuilder: (cues) => cues.label,
  );

  /// The Zoom segments over [close], six and [far] pixels per frame;
  /// returns the chosen zoom, six at start.
  double zoom({required double close, required double far}) => object.segmented(
    label: "Zoom",
    options: [close, 6.0, far],
    initialOption: 6.0,
    labelBuilder: (zoom) => zoom == close
        ? "Close"
        : zoom == far
        ? "Far"
        : "Default",
  );
}

/// The label a story draws inside a cue it builds without a surface.
Widget storyCueLabel(BuildContext context, String label, Color color) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      border: Border.all(color: color),
      borderRadius: context.shapes.mediumBorderRadius,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
    ),
  );
}
