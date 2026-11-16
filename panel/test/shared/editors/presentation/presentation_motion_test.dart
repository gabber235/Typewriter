import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("no policy leaves every move as tuned", () {
    const skir.PresentationTransitionPolicy? none = null;
    expect(none.reading, const MotionReading.read(MoveOverrides()));
  });

  test("an override follows the move of the state it is keyed by", () {
    final reading = transitionOverrides(
      selected: timedTransition(milliseconds: 750),
    ).reading;
    final overrides = (reading as MotionRead<MoveOverrides>).value;
    expect(
      overrides.forMove(MotionToken.ink),
      const MotionOverride(duration: Duration(milliseconds: 750)),
    );
    expect(overrides.forMove(MotionToken.hoverIn), isNull);
    expect(overrides.forMove(MotionToken.hoverOut), isNull);
  });

  test("hover in and out share the hovered override", () {
    final overrides =
        (transitionOverrides(hovered: timedTransition(milliseconds: 300))
                    .reading
                as MotionRead<MoveOverrides>)
            .value;
    expect(overrides.forMove(MotionToken.hoverIn), isNotNull);
    expect(
      overrides.forMove(MotionToken.hoverIn),
      overrides.forMove(MotionToken.hoverOut),
    );
  });

  test(
    "a malformed override reads as the diagnostic message, never a throw",
    () {
      expect(
        transitionOverrides(pressed: timedTransition(milliseconds: -1)).reading,
        const MotionReading<MoveOverrides>.failed(
          "Presentation duration cannot be negative",
        ),
      );
      expect(
        transitionOverrides(
          hovered: timedTransition(
            curve: skir.PresentationTimedCurve.wrapStrike(1.5),
          ),
        ).reading,
        const MotionReading<MoveOverrides>.failed(
          "Strike overshoot must be between 0 and 1",
        ),
      );
    },
  );

  test(
    "a collection with no item motion lets rowIn and listOut play as tuned",
    () {
      final appearance = itemMotionAppearance();
      expect(
        appearance.arrivalReading,
        const MotionReading<MotionOverride?>.read(null),
      );
      expect(
        appearance.leaveReading,
        const MotionReading<MotionOverride?>.read(null),
      );
    },
  );

  test("a collection's item arrival and leave overrides reach the engine", () {
    final appearance = itemMotionAppearance(
      arrival: timedTransition(milliseconds: 400),
      leave: skir.PresentationTransition.wrapSpring(
        skir.PresentationSpring(stiffness: 380, damping: 30),
      ),
    );
    expect(
      appearance.arrivalReading,
      const MotionReading<MotionOverride?>.read(
        MotionOverride(duration: Duration(milliseconds: 400)),
      ),
    );
    expect(
      appearance.leaveReading,
      const MotionReading<MotionOverride?>.read(
        MotionOverride(curve: MotionShape.spring(stiffness: 380, damping: 30)),
      ),
    );
  });

  test("a malformed item override reads as the diagnostic message", () {
    final appearance = itemMotionAppearance(
      arrival: timedTransition(milliseconds: -1),
    );
    expect(
      appearance.arrivalReading,
      const MotionReading<MotionOverride?>.failed(
        "Presentation duration cannot be negative",
      ),
    );
  });
}
