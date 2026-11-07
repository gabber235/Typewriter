import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a retarget continues from where the value is", (tester) async {
    final press = (await resolveMotionIn(
      tester,
      MotionToken.press,
    )).motion.duration;
    final (panel, start) = await tester.startProbe(MotionToken.press);
    await tester.pump(press ~/ 6); // mid travel, still rising
    final before = panel.boundsOf("probe").left;
    await tester.showComponent(
      const MotionProbe(token: MotionToken.press, target: 0),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final after = panel.boundsOf("probe").left;

    expect(after, greaterThan(before), reason: "its velocity carries it on");
    expect((after - before).abs(), lessThan(20), reason: "it does not jump");
    await panel.settle();
    expect(panel.boundsOf("probe").left, start);
  });

  testWidgets("a reversal eases back at full length", (tester) async {
    final press = (await resolveMotionIn(
      tester,
      MotionToken.press,
    )).motion.duration;
    final (panel, start) = await tester.startProbe(MotionToken.press);
    await tester.pump(press ~/ 4);
    final before = panel.boundsOf("probe").left;
    // A quarter of its time is the repeat floor; a reversal is no repeat.
    await tester.showComponent(
      const MotionProbe(token: MotionToken.press, target: 0),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(panel.boundsOf("probe").left, greaterThan(start));
    expect(
      (panel.boundsOf("probe").left - before).abs(),
      lessThan(20),
      reason: "it does not jump",
    );
    await tester.pump(press ~/ 2);
    expect(panel.shows("probe settled"), isFalse, reason: "full length");
    await panel.settle();
    expect(panel.boundsOf("probe").left, start);
  });

  testWidgets("a same direction repeat shortens", (tester) async {
    final move = (await resolveMotionIn(
      tester,
      MotionToken.focusMove,
    )).motion.duration;
    final panel = await tester.mountComponent(
      const MotionProbe(token: MotionToken.focusMove, target: 0),
    );
    await tester.showComponent(
      const MotionProbe(token: MotionToken.focusMove, target: 1),
      settle: false,
    );
    await tester.pump(move ~/ 2);
    await tester.showComponent(
      const MotionProbe(token: MotionToken.focusMove, target: 2),
      settle: false,
    );
    expect(panel.shows("probe settled"), isFalse);
    // Repeated at half its time, the move takes half its time.
    await tester.pump(move ~/ 2);
    await tester.pump();
    expect(panel.shows("probe settled"), isTrue);
  });

  testWidgets("a move repeated faster than its floor jumps", (tester) async {
    final move = (await resolveMotionIn(
      tester,
      MotionToken.focusMove,
    )).motion.duration;
    final panel = await tester.mountComponent(
      const MotionProbe(token: MotionToken.focusMove, target: 0),
    );
    final start = panel.boundsOf("probe").left;
    for (final target in [1.0, 2.0, 3.0]) {
      await tester.showComponent(
        MotionProbe(token: MotionToken.focusMove, target: target),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(panel.boundsOf("probe").left, start + 300);

    await tester.pump(move); // longer than one move: the next travels again
    await tester.showComponent(
      const MotionProbe(token: MotionToken.focusMove, target: 0),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(panel.boundsOf("probe").left, greaterThan(start));
  });

  testWidgets("reduced motion lands at once", (tester) async {
    final panel = await tester.mountComponent(
      const ReducedMotion(
        child: MotionProbe(token: MotionToken.rowIn, target: 0),
      ),
    );
    final start = panel.boundsOf("probe").left;
    await tester.showComponent(
      const ReducedMotion(
        child: MotionProbe(token: MotionToken.rowIn, target: 1),
      ),
      settle: false,
    );
    await tester.pump();
    expect(panel.boundsOf("probe").left, start + 100);
  });

  testWidgets("a busy word does not hold up settling", (tester) async {
    final panel = await tester.showComponent(
      const MotionProbe(token: MotionToken.ripple, target: 1, loop: true),
    );
    await panel.settle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets("with the standard table a busy word keeps looping", (
    tester,
  ) async {
    await tester.pumpWidget(
      Theme(
        data: buildTheme(Brightness.light),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: MotionProbe(token: MotionToken.ripple, target: 1, loop: true),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets("settled turns true when the value lands", (tester) async {
    final panel = await tester.mountComponent(
      const MotionProbe(token: MotionToken.rowIn, target: 0),
    );
    expect(panel.shows("probe settled"), isTrue);
    await tester.showComponent(
      const MotionProbe(token: MotionToken.rowIn, target: 1),
      settle: false,
    );
    expect(panel.shows("probe settled"), isFalse);
    await panel.settle();
    expect(panel.shows("probe settled"), isTrue);
  });

  testWidgets("typing keeps the shared letters", (tester) async {
    final step = (await resolveMotionIn(
      tester,
      MotionToken.type,
    )).motion.duration;
    for (final reduced in [false, true]) {
      Widget typing(String text) =>
          reduced ? ReducedMotion(child: TypingProbe(text)) : TypingProbe(text);
      final panel = await tester.mountComponent(typing("Publish"));
      expect(panel.shows("Publish"), isTrue, reason: "reduced: $reduced");
      await tester.showComponent(typing("Publishing"), settle: false);
      expect(panel.shows("Publish"), isTrue, reason: "reduced: $reduced");
      await tester.pump(step);
      expect(panel.shows("Publishi"), isTrue, reason: "reduced: $reduced");
      await tester.pump(step);
      expect(panel.shows("Publishin"), isTrue, reason: "reduced: $reduced");
      await panel.settle();
      expect(panel.shows("Publishing"), isTrue, reason: "reduced: $reduced");
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets("a state change plays its move and a data change lands", (
    tester,
  ) async {
    final hoverIn = await resolveMotionIn(tester, MotionToken.hoverIn);
    final hoverOut = await resolveMotionIn(tester, MotionToken.hoverOut);
    final press = await resolveMotionIn(tester, MotionToken.press);
    ResolvedMotion<Landing>? played;
    void record(ResolvedMotion<Landing> motion) => played = motion;

    final panel = await tester.mountComponent(
      StateMotionProbe(states: const {}, target: 0, onMotion: record),
    );
    final start = panel.boundsOf("probe").left;
    await tester.showComponent(
      StateMotionProbe(
        states: const {WidgetState.hovered},
        target: 1,
        onMotion: record,
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      panel.boundsOf("probe").left,
      allOf(greaterThan(start), lessThan(start + 100)),
      reason: "hoverIn travels",
    );
    expect(played!.motion.duration, hoverIn.motion.duration);
    await panel.settle();

    await tester.showComponent(
      StateMotionProbe(
        states: const {WidgetState.hovered},
        target: 2,
        onMotion: record,
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(panel.boundsOf("probe").left, start + 200, reason: "data lands");

    await tester.showComponent(
      StateMotionProbe(states: const {}, target: 2, onMotion: record),
    );
    expect(played!.motion.duration, hoverOut.motion.duration);

    await tester.showComponent(
      StateMotionProbe(
        states: const {WidgetState.pressed, WidgetState.hovered},
        target: 2,
        onMotion: record,
      ),
    );
    expect(played!.motion.duration, press.motion.duration);

    MotionOverride? slowHover(MotionToken<Landing> move) =>
        move == MotionToken.hoverIn
        ? const MotionOverride(duration: Duration(seconds: 1))
        : null;
    await tester.showComponent(
      StateMotionProbe(
        states: const {},
        target: 2,
        onMotion: record,
        overrideFor: slowHover,
      ),
    );
    await tester.showComponent(
      StateMotionProbe(
        states: const {WidgetState.hovered},
        target: 2,
        onMotion: record,
        overrideFor: slowHover,
      ),
    );
    expect(played!.motion.duration, const Duration(seconds: 1));
    await tester.showComponent(
      StateMotionProbe(
        states: const {},
        target: 2,
        onMotion: record,
        overrideFor: slowHover,
      ),
    );
    expect(played!.motion.duration, hoverOut.motion.duration);
  });

  testWidgets("a typed value retargets from what is shown", (tester) async {
    const first = Rect.fromLTWH(0, 0, 20, 20);
    const second = Rect.fromLTWH(200, 0, 60, 20);
    const third = Rect.fromLTWH(0, 200, 20, 60);
    final panel = await tester.mountComponent(
      const RectMotionProbe(token: MotionToken.rowIn, target: first),
    );
    await tester.showComponent(
      const RectMotionProbe(token: MotionToken.rowIn, target: second),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    final shown = panel.boundsOf("probe");
    await tester.showComponent(
      const RectMotionProbe(token: MotionToken.rowIn, target: third),
      settle: false,
    );
    final continued = panel.boundsOf("probe");
    expect((continued.left - shown.left).abs(), lessThan(4));
    expect((continued.top - shown.top).abs(), lessThan(4));
    expect((continued.width - shown.width).abs(), lessThan(4));
    await panel.settle();
    expect(panel.boundsOf("probe").size, third.size);
  });

  testWidgets("a typed value turning back eases back at full length", (
    tester,
  ) async {
    final press = (await resolveMotionIn(
      tester,
      MotionToken.press,
    )).motion.duration;
    const first = Rect.fromLTWH(0, 0, 20, 20);
    const second = Rect.fromLTWH(200, 0, 20, 20);
    final panel = await tester.mountComponent(
      const RectMotionProbe(token: MotionToken.press, target: first),
    );
    final home = panel.boundsOf("probe");
    await tester.showComponent(
      const RectMotionProbe(token: MotionToken.press, target: second),
      settle: false,
    );
    await tester.pump(press ~/ 4);
    final shown = panel.boundsOf("probe").left;
    await tester.showComponent(
      const RectMotionProbe(token: MotionToken.press, target: first),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 16));
    final left = panel.boundsOf("probe").left;
    expect((left - shown).abs(), lessThan(20), reason: "it does not jump");
    await tester.pump(press ~/ 2);
    expect(panel.boundsOf("probe"), isNot(home), reason: "full length");
    await panel.settle();
    expect(panel.boundsOf("probe"), home);
  });
}
