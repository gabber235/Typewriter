import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final intro = cue("Intro", from: 10, to: 20);
  final outro = cue("Outro", from: 40, to: 50);
  final music = cue("Music", from: 0, to: 30);
  final opening = scene(
    "Opening",
    tracks: [
      track("Camera", cues: [intro, outro]),
      track("Sound", cues: [music]),
    ],
  );

  testWidgets("a cue moved with Shift M and arrows saves its new frames "
      "when Escape commits", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(scenes: [opening]),
    ]);
    await panel.openSurface(opening.sceneId);
    // Switch Focus moves by direction: down into the timeline, then left
    // along the Camera track to its first cue.
    const cues = {"Intro", "Outro", "Music"};
    for (var step = 0; step < 6 && !cues.contains(panel.focused); step++) {
      await panel.press(LogicalKeyboardKey.arrowDown);
    }
    for (var step = 0; step < 4 && panel.focused != "Intro"; step++) {
      await panel.press(LogicalKeyboardKey.arrowLeft);
    }
    expect(panel.focused, "Intro", reason: "the cue is reachable by keyboard");
    await panel.press(LogicalKeyboardKey.space);
    expect(panel.resources.selected, [intro.cueId]);

    await panel.pressShifted(LogicalKeyboardKey.keyM);
    for (var step = 0; step < 3; step++) {
      await panel.press(LogicalKeyboardKey.arrowRight);
    }
    expect(
      panel.world.requireRealm.saves,
      isEmpty,
      reason: "the move is a preview until Escape commits it",
    );
    await panel.press(LogicalKeyboardKey.escape);

    await panel.eventually(() {
      final saved = panel.world.requireRealm.document;
      expect(saved.frames(intro.cueId), (13, 23));
      expect(saved.frames(outro.cueId), (40, 50));
      expect(saved.frames(music.cueId), (0, 30));
    });
  });
}
