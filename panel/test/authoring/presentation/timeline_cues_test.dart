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

  testWidgets("arrows alone reach a cue from the scene's surface", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(scenes: [opening]),
    ]);
    await panel.openSurface(opening.sceneId);

    // Switch Focus moves by direction: down into the surface and on to the
    // timeline's header width handle, which lets arrows pass while it is not
    // resizing; right onto the Sound track's cue, then up to the Camera
    // track's first cue.
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.arrowRight);
    await panel.press(LogicalKeyboardKey.arrowUp);

    expect(panel.focused, "Intro");
  });

  testWidgets("a cue moved with Shift M and arrows saves its new frames "
      "when Escape commits", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(scenes: [opening]),
    ]);
    await panel.openSurface(opening.sceneId);
    await panel.tabTo("Intro", limit: 40);
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
