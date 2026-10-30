import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final edits = [
    (
      name: "Shift M moves the selected cue",
      mode: LogicalKeyboardKey.keyM,
      shown: "MOVE",
      step: LogicalKeyboardKey.arrowRight,
      frames: (start: 13, end: 23),
    ),
    (
      name: "Shift S moves the selected cue's start",
      mode: LogicalKeyboardKey.keyS,
      shown: "RESIZE",
      step: LogicalKeyboardKey.arrowLeft,
      frames: (start: 7, end: 20),
    ),
    (
      name: "Shift E moves the selected cue's end",
      mode: LogicalKeyboardKey.keyE,
      shown: "RESIZE",
      step: LogicalKeyboardKey.arrowRight,
      frames: (start: 10, end: 23),
    ),
  ];
  for (final edit in edits) {
    testWidgets("${edit.name}; Escape commits the frames the arrows chose", (
      tester,
    ) async {
      final timeline = CueTimeline(_cues, selectable: true);
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(timeline),
      );

      await panel.tabTo(_cue);
      await panel.press(LogicalKeyboardKey.space);
      expect(panel.container.read(selectionProvider), [
        TestSelectableIdentifier(id: _cue),
      ]);
      await panel.pressShifted(edit.mode);
      expect(panel.shows(edit.shown), isTrue);
      final before = panel.item(_cue).rect;
      for (var step = 0; step < 3; step++) {
        await panel.press(edit.step);
      }
      expect(
        panel.item(_cue).rect,
        isNot(before),
        reason: "the cue shows the edit before it is committed",
      );
      expect(timeline.commits, isEmpty);
      await panel.press(LogicalKeyboardKey.escape);

      expect(timeline.commits, [
        [(id: _cue, start: edit.frames.start, end: edit.frames.end)],
      ]);
      expect(panel.shows(edit.shown), isFalse);
    });
  }

  testWidgets("a timeline its caller cannot save offers no edit mode", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        CueTimeline(_cues, selectable: true, editable: false),
      ),
    );

    await panel.tabTo(_cue);
    await panel.press(LogicalKeyboardKey.space);
    expect(panel.container.read(selectionProvider), [
      TestSelectableIdentifier(id: _cue),
    ]);
    for (final mode in [
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyE,
    ]) {
      await panel.pressShifted(mode);
      expect(panel.shows("MOVE"), isFalse);
      expect(panel.shows("RESIZE"), isFalse);
    }
  });
}

const _cue = "Cue";

/// One cue from frame 10 to 20 that joins the selection when chosen.
const _cues = [CueSpec.segment(_cue, track: "Track", from: 10, to: 20)];
