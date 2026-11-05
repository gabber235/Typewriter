import "package:typewriter_panel/typewriter_panel.dart";

import "package:typewriter_testkit/src/shared/selectables/test_selectable.dart";

/// One cue a [CueTimeline] shows on the track named [track]: a segment from
/// [start] to [end], or a keyframe at [start] when [end] is null.
final class CueSpec {
  /// A segment cue spanning the frames [from] to [to].
  const CueSpec.segment(
    this.label, {
    required this.track,
    required int from,
    required int to,
  }) : start = from,
       end = to;

  /// A keyframe cue at frame [at].
  const CueSpec.keyframe(this.label, {required this.track, required int at})
    : start = at,
      end = null;

  final String label;
  final String track;
  final int start;
  final int? end;
}

/// A timeline of labeled [cues] beside the current interaction mode, as an
/// editor page shows them, recording what the user does to its cues.
///
/// With [selectable] each cue joins the selection when chosen; otherwise
/// choosing a cue opens it and lands in [opened]. With [editable] false the
/// caller cannot save, so the timeline offers no edits.
class CueTimeline extends StatelessWidget {
  CueTimeline(
    this.cues, {
    super.key,
    this.selectable = false,
    this.editable = true,
  });

  final List<CueSpec> cues;
  final bool selectable;
  final bool editable;

  /// Every commit in order: the cues it moved, each by label with the frames
  /// it now spans.
  final commits = <List<({String id, int start, int end})>>[];

  /// The labels of the cues the user opened, in order.
  final opened = <String>[];

  TimelineElementBuilder _cue(String label) =>
      (_, data) => TimelineCue(
        data: data,
        label: label,
        selectableId: selectable ? TestSelectableIdentifier(id: label) : null,
        onOpen: selectable ? null : () => opened.add(label),
      );

  @override
  Widget build(BuildContext context) {
    final tracks = {for (final cue in cues) cue.track};
    return SizedBox(
      width: 1000,
      height: 400,
      child: Column(
        children: [
          const ModeDisplayWidget(),
          Expanded(
            child: Timeline(
              data: TimelineData(
                tracks: [
                  for (final track in tracks)
                    TimelineTrack(
                      id: TimelineIdentifier(track),
                      header: (_) => Text(track),
                      elements: [
                        for (final cue in cues.where((c) => c.track == track))
                          if (cue.end case final end?)
                            TimelineSegment(
                              id: TimelineIdentifier(cue.label),
                              startFrame: cue.start,
                              endFrame: end,
                              parentId: null,
                              color: Colors.blue,
                              children: const [],
                              builder: _cue(cue.label),
                            )
                          else
                            TimelineKeyframe(
                              id: TimelineIdentifier(cue.label),
                              frame: cue.start,
                              parentId: null,
                              color: Colors.orange,
                              builder: _cue(cue.label),
                            ),
                      ],
                    ),
                ],
              ),
              onElementsCommited: editable
                  ? (changes) async => commits.add([
                      for (final change in changes)
                        (
                          id: change.id.id,
                          start: change.startFrame,
                          end: change.endFrame,
                        ),
                    ])
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
