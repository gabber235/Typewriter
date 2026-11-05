import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final drags = [
    (
      name: "dragging a segment moves it",
      cue: _scene,
      startEdge: false,
      committed: (id: _scene, start: 15, end: 25),
    ),
    (
      name: "dragging a segment's start edge resizes it",
      cue: _scene,
      startEdge: true,
      committed: (id: _scene, start: 15, end: 20),
    ),
    (
      name: "dragging a keyframe moves it",
      cue: _mark,
      startEdge: false,
      committed: (id: _mark, start: 15, end: 15),
    ),
  ];
  for (final drag in drags) {
    testWidgets("${drag.name}: the drag previews, release commits", (
      tester,
    ) async {
      final timeline = CueTimeline(_cues);
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(timeline),
      );
      final pixelsPerFrame =
          (panel.item(_mark).rect.center.dx -
              panel.item(_start).rect.center.dx) /
          10;
      final before = panel.item(drag.cue).rect;
      final grip = drag.startEdge
          ? before.centerLeft + const Offset(2, 0)
          : before.center;

      final gesture = await tester.startGesture(grip);
      // The first movement only wins the drag; it moves nothing.
      await gesture.moveBy(const Offset(kTouchSlop + 2, 0));
      await tester.pump();
      await gesture.moveBy(Offset(5 * pixelsPerFrame, 0));

      await panel.eventually(
        () => expect(
          panel.item(drag.cue).rect.left - before.left,
          closeTo(5 * pixelsPerFrame, 1),
          reason: "the cue shows where the drag takes it",
        ),
      );
      expect(timeline.commits, isEmpty);

      await gesture.up();
      await panel.settle();

      expect(timeline.commits, [
        [drag.committed],
      ]);
    });
  }

  testWidgets("tapping a cue opens it", (tester) async {
    final timeline = CueTimeline(_cues);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(timeline),
    );

    await panel.item(_scene).select();
    await panel.item(_mark).select();

    expect(timeline.opened, [_scene, _mark]);
    expect(timeline.commits, isEmpty);
  });
}

const _scene = "Scene";
const _start = "Start";
const _mark = "Mark";

/// Resource cues as the resources layout builds them: a segment from frame 10
/// to 20 on one track, keyframes at 0 and 10 on another.
const _cues = [
  CueSpec.segment(_scene, track: "Scenes", from: 10, to: 20),
  CueSpec.keyframe(_start, track: "Marks", at: 0),
  CueSpec.keyframe(_mark, track: "Marks", at: 10),
];
