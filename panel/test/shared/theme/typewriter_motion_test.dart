import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("every token in the table resolves", (tester) async {
    for (final brightness in Brightness.values) {
      for (final token in MotionToken.values) {
        final resolved = await resolveMotionIn(
          tester,
          token,
          brightness: brightness,
        );
        expect(resolved.travels, isTrue, reason: "$token in $brightness");
      }
    }
  });

  testWidgets("reduced motion keeps every result and removes the travel", (
    tester,
  ) async {
    final hover = await resolveMotionIn(
      tester,
      MotionToken.hoverIn,
      reduced: true,
    );
    expect(hover.still, isTrue);
    expect(hover.motion, isA<InstantMotion>());

    final row = await resolveMotionIn(tester, MotionToken.rowIn, reduced: true);
    expect(row.reduced, ReducedKind.jump);
    expect(row.motion.simulate(from: 0, to: 1).x(0), 1);

    final hold = await resolveMotionIn(tester, MotionToken.hold, reduced: true);
    expect(hold.reduced, ReducedKind.paced);
    final full = await resolveMotionIn(tester, MotionToken.hold);
    expect(hold.motion.duration, full.motion.duration);
    expect((hold.motion as HoldMotion).fill.dampingRatio, closeTo(1, 1e-9));
  });

  testWidgets("an override applies before reduced motion", (tester) async {
    const slower = MotionOverride(duration: Duration(milliseconds: 750));
    final row = await resolveMotionIn(
      tester,
      MotionToken.rowIn,
      override: slower,
    );
    expect(row.motion.duration, const Duration(milliseconds: 750));
    expect((row.motion as CurveMotion).curve, isA<CarriageCurve>());

    final reducedRow = await resolveMotionIn(
      tester,
      MotionToken.rowIn,
      override: slower,
      reduced: true,
    );
    expect(reducedRow.motion, isA<InstantMotion>());

    final hold = await resolveMotionIn(
      tester,
      MotionToken.hold,
      override: const MotionOverride(duration: Duration(milliseconds: 1200)),
      reduced: true,
    );
    expect(hold.motion.duration, const Duration(milliseconds: 1200));

    const sentSpring = MotionOverride(
      duration: Duration(milliseconds: 750),
      curve: SpringShape(stiffness: 200, damping: 20),
    );
    final sprung = await resolveMotionIn(
      tester,
      MotionToken.hoverIn,
      override: sentSpring,
    );
    expect(
      sprung.motion,
      isA<SpringMotion>()
          .having((spring) => spring.stiffness, "stiffness", 200)
          .having((spring) => spring.damping, "damping", 20),
    );

    final press = await resolveMotionIn(tester, MotionToken.press);
    final shorterPress = await resolveMotionIn(
      tester,
      MotionToken.press,
      override: const MotionOverride(duration: Duration(milliseconds: 400)),
    );
    expect(
      (shorterPress.motion as SpringMotion).dampingRatio,
      closeTo((press.motion as SpringMotion).dampingRatio, 1e-9),
    );
    expect(shorterPress.motion.duration.inMilliseconds, closeTo(400, 1));

    final timed = await resolveMotionIn(
      tester,
      MotionToken.press,
      override: const MotionOverride(curve: MotionShape.exit),
    );
    expect(timed.motion, isA<CurveMotion>());
    expect(timed.motion.duration, press.motion.duration);

    final zero = await resolveMotionIn(
      tester,
      MotionToken.rowIn,
      override: const MotionOverride(duration: Duration.zero),
    );
    expect(zero.motion, isA<InstantMotion>());
    expect(
      const MotionOverride(
        duration: Duration(milliseconds: 750),
        curve: MotionShape.exit,
      ),
      const MotionOverride(
        duration: Duration(milliseconds: 750),
        curve: MotionShape.exit,
      ),
    );
  });

  testWidgets("a busy word loops until its table caps it", (tester) async {
    final free = await resolveMotionIn(tester, MotionToken.ripple);
    expect((free.motion as LoopMotion).cycles, isNull);
    final capped = await resolveMotionIn(
      tester,
      MotionToken.ripple,
      table: TypewriterMotion.standard().oneRoundLoops,
    );
    expect((capped.motion as LoopMotion).cycles, 1);
  });

  test("a state change picks one move", () {
    const hovered = WidgetState.hovered;
    const pressed = WidgetState.pressed;
    const focused = WidgetState.focused;
    const selected = WidgetState.selected;
    final cases = <(Set<WidgetState>, Set<WidgetState>, MotionToken?)>[
      (const {}, const {hovered}, MotionToken.hoverIn),
      (const {hovered}, const {}, MotionToken.hoverOut),
      (const {}, const {pressed}, MotionToken.press),
      (const {pressed}, const {}, MotionToken.press),
      (const {}, const {focused}, MotionToken.focusMove),
      (const {focused}, const {}, MotionToken.focusMove),
      (const {}, const {selected}, MotionToken.ink),
      (const {selected}, const {}, MotionToken.ink),
      (const {}, const {pressed, focused}, MotionToken.press),
      (const {}, const {focused, selected}, MotionToken.focusMove),
      (const {}, const {selected, hovered}, MotionToken.ink),
      (const {}, const {WidgetState.disabled}, null),
      (const {}, const {WidgetState.dragged}, null),
      (const {}, const {WidgetState.error}, null),
      (const {hovered}, const {hovered}, null),
    ];
    for (final (from, to, move) in cases) {
      expect(from.moveTo(to), move, reason: "$from to $to");
    }
  });

  testWidgets("the panel plays the table it is given", (tester) async {
    final standard = TypewriterMotion.standard();
    final row = standard.spec(MotionToken.rowIn);
    final slow = standard.withSpec(
      MotionToken.rowIn,
      row.copyWith(motion: row.motion.withDuration(const Duration(seconds: 1))),
    );
    final panel = await tester.pumpPanel([playsMotion(slow)]);
    expect(
      panel.resolveOnPage(MotionToken.rowIn).motion.duration,
      const Duration(seconds: 1),
    );
  });
}
