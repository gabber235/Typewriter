import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The stack around the authored cover text, not one the test app adds.
final coverStack = find
    .ancestor(of: find.text("Cover"), matching: find.byType(Stack))
    .first;

/// The surface the authored container paints around the cover text.
final _surface = find
    .ancestor(of: find.text("Cover"), matching: find.byType(SurfaceContainer))
    .first;

/// The nearest transform above the authored cover text.
final coverTransform = find
    .ancestor(of: find.text("Cover"), matching: find.byType(Transform))
    .first;

void main() {
  late PortablePresentationScope scope;
  setUp(() {
    scope = unboundPresentationScope();
  });

  final selected = skir.PresentationStateMatch(
    required_: [skir.PresentationInteractionState.selected],
    excluded: const [],
  );
  final hovered = skir.PresentationStateMatch(
    required_: [skir.PresentationInteractionState.hovered],
    excluded: const [],
  );
  final selectMotion = transitionOverrides(
    selected: skir.PresentationTransition.wrapSpring(
      skir.PresentationSpring(stiffness: 280, damping: 17),
    ),
  );
  final label = presentationText("label", textLiteral("Cover"));

  testWidgets(
    "positioned stack children follow state and play the service's override for the selection move",
    (tester) async {
      final root = presentationNode(
        "stack",
        skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createStack(
            alignment: skir.PresentationAlignment.center,
            children: [
              skir.StackChild.wrapFlow(label),
              skir.StackChild.createPositioned(
                child: presentationText("spine", textLiteral("Spine")),
                top: stateNumber(10, match: selected, value: 15),
                start: null,
                end: stateNumber(0, match: selected, value: 14),
                bottom: stateNumber(10, match: selected, value: 15),
                width: presentationNumber(30),
                height: null,
                transition: selectMotion,
              ),
            ],
          ),
        ),
      );
      final interact = await tester.showInteractiveNode(root, scope: scope);
      // Where the spine sits inside the authored stack: its distance to the
      // stack's top and end edges.
      (double, double) inset() {
        final spine = tester.getRect(find.text("Spine"));
        final stack = tester.getRect(coverStack);
        return (spine.top - stack.top, stack.right - spine.right);
      }

      // The flow child sits at the center of the stack.
      expect(
        tester.getCenter(find.text("Cover")),
        offsetMoreOrLessEquals(tester.getCenter(coverStack)),
      );
      expect(inset(), (10, 0));
      expect(tester.getSize(find.text("Spine")).width, 30);

      // Entering the selected state plays ink with the service's spring: it
      // overshoots before settling.
      interact(const PresentationInteraction(selected: true));
      await tester.pump();
      var overshoot = false;
      while (tester.hasRunningAnimations) {
        await tester.pump(const Duration(milliseconds: 25));
        if (inset().$1 > 15.01) overshoot = true;
      }
      expect(overshoot, isTrue);
      expect(inset().$1, closeTo(15, 0.01));
      expect(inset().$2, closeTo(14, 0.01));

      // Leaving it plays ink again with the same spring: it is on its way
      // back at once, and settles in its own place.
      interact(const PresentationInteraction());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(inset().$1, inExclusiveRange(10, 15));
      await tester.pumpAndSettle();
      expect(inset().$1, closeTo(10, 0.01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("an overconstrained positioned child shows a diagnostic", (
    tester,
  ) async {
    final root = presentationNode(
      "stack",
      skir.PresentationElement.wrapChildren(
        skir.ChildrenElement.createStack(
          alignment: null,
          children: [
            skir.StackChild.wrapFlow(label),
            skir.StackChild.createPositioned(
              child: presentationText("edge", textLiteral("Edge")),
              top: null,
              start: presentationNumber(0),
              end: presentationNumber(0),
              bottom: null,
              width: presentationNumber(10),
              height: null,
              transition: null,
            ),
          ],
        ),
      ),
    );
    await tester.showInteractiveNode(root, scope: scope);
    expect(
      find.text("A positioned child declares at most two bounds per axis"),
      findsOneWidget,
    );
    expect(find.text("Edge"), findsNothing);
  });

  testWidgets("a size layout keeps its exact size inside a looser parent", (
    tester,
  ) async {
    final root = presentationNode(
      "align",
      skir.PresentationElement.createAlign(
        alignment: skir.PresentationAlignment.center,
        child: presentationNode(
          "size",
          skir.PresentationElement.createSize(
            child: presentationNode(
              "surface",
              skir.PresentationElement.createContainer(
                child: label,
                border: null,
                backgroundColor: skir.PresentationColor.wrapValue(
                  const Color(0xff3f51b5).portableExpression,
                ),
                radius: skir.PresentationRadius.large,
                foregroundColor: null,
                transition: null,
                shadows: const [],
              ),
            ),
            width: numberLiteral(175),
            height: numberLiteral(230),
            minimumWidth: null,
            maximumWidth: null,
            minimumHeight: null,
            maximumHeight: null,
          ),
        ),
      ),
    );
    await tester.showInteractiveNode(
      root,
      scope: scope,
      size: const Size(240, 333),
    );
    expect(tester.getSize(_surface), const Size(175, 230));
  });

  testWidgets("a container paints its authored shadow", (tester) async {
    final root = presentationNode(
      "surface",
      skir.PresentationElement.createContainer(
        child: label,
        border: null,
        backgroundColor: null,
        radius: skir.PresentationRadius.large,
        foregroundColor: null,
        transition: null,
        shadows: [
          skir.PresentationShadow(
            color: skir.PresentationColor.wrapValue(
              const Color(0x66000000).portableExpression,
            ),
            blur: 8,
            spread: 1,
            offsetX: 0,
            offsetY: 2,
          ),
        ],
      ),
    );
    await tester.showInteractiveNode(root, scope: scope);
    // A shadow has no semantics; the painted decoration is what the user
    // sees.
    final shadow = tester
        .widget<SurfaceContainer>(_surface)
        .decoration
        .boxShadow!
        .single;
    expect(shadow.color, const Color(0x66000000));
    expect(
      [shadow.blurRadius, shadow.spreadRadius, shadow.offset.dy],
      [8, 1, 2],
    );
  });

  testWidgets(
    "a transform paints state driven values without moving the hit region",
    (tester) async {
      var taps = 0;
      final root = presentationNode(
        "transform",
        skir.PresentationElement.createTransform(
          child: label,
          origin: skir.PresentationAlignment.centerStart,
          perspective: 0.002,
          scale: skir.PresentationNumber.createStates(
            rules: [
              skir.PresentationStateNumberRule(
                match: hovered,
                value: numberLiteral(2),
              ),
            ],
            fallback: numberLiteral(1),
          ),
          rotateX: null,
          rotateY: stateNumber(0, match: selected, value: 0.05),
          rotateZ: null,
          translateX: skir.PresentationNumber.createStates(
            rules: [
              skir.PresentationStateNumberRule(
                match: hovered,
                value: numberLiteral(500),
              ),
            ],
            fallback: numberLiteral(0),
          ),
          translateY: null,
          transition: selectMotion,
        ),
      );
      var interaction = const PresentationInteraction();
      late StateSetter update;
      await tester.showComponent(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: PresentationInteractionScope(
                  value: interaction,
                  child: PortablePresentationNodeRenderer(
                    node: root,
                    scope: scope,
                  ),
                ),
              );
            },
          ),
        ),
      );
      Matrix4 matrix() => tester.widget<Transform>(coverTransform).transform;
      expect(matrix().getMaxScaleOnAxis(), closeTo(1, 0.0001));
      final bounds = tester.getRect(find.byType(GestureDetector).last);

      update(() => interaction = const PresentationInteraction(hovered: true));
      await tester.pump();
      // A quarter of the way through hoverIn, before its overshoot.
      await tester.pump(tester.tokenTime(MotionToken.hoverIn) ~/ 4);
      final halfway = matrix().getMaxScaleOnAxis();
      expect(halfway, greaterThan(1));
      expect(halfway, lessThan(2));
      await tester.pumpAndSettle();
      expect(matrix().getMaxScaleOnAxis(), closeTo(2, 0.0001));
      expect(matrix().getTranslation().x, closeTo(500, 0.0001));
      expect(
        tester.widget<Transform>(coverTransform).transformHitTests,
        isFalse,
      );
      expect(tester.getRect(find.byType(GestureDetector).last), bounds);
      await tester.tapAt(bounds.center);
      expect(taps, 1);

      update(() => interaction = const PresentationInteraction(selected: true));
      await tester.pumpAndSettle();
      expect(matrix().getMaxScaleOnAxis(), greaterThan(0.99));
      expect(matrix().entry(3, 2), closeTo(0.002, 0.0001));
      expect(tester.takeException(), isNull);
    },
  );

  group("paint colors", () {
    final accent = skir.PresentationColor.wrapValue(
      const Color(0xff3f51b5).portableExpression,
    );
    final light = PresentationValueEnvironment(
      theme: ThemeData(brightness: Brightness.light),
      appearance: SurfaceAppearance(
        color: Colors.black,
        foreground: Colors.white,
        secondaryForeground: Colors.grey,
      ),
      interaction: const PresentationInteraction(),
    );
    final dark = PresentationValueEnvironment(
      theme: ThemeData(brightness: Brightness.dark),
      appearance: SurfaceAppearance(
        color: Colors.black,
        foreground: Colors.white,
        secondaryForeground: Colors.grey,
      ),
      interaction: const PresentationInteraction(),
    );

    test("adjusted colors move lightness and chroma in OkLch", () {
      final colors = light;
      double lightness(Color color) => color.toOkLch().l;
      double chroma(Color color) => color.toOkLch().c;
      final source = colors.resolve(accent, scope);
      final lighter = colors.resolve(
        skir.PresentationColor.createAdjusted(
          source: accent,
          lightness: 0.5,
          chroma: 0,
        ),
        scope,
      );
      final darker = colors.resolve(
        skir.PresentationColor.createAdjusted(
          source: accent,
          lightness: -0.5,
          chroma: -0.5,
        ),
        scope,
      );
      expect(lightness(lighter), greaterThan(lightness(source)));
      expect(lightness(darker), lessThan(lightness(source)));
      expect(chroma(darker), lessThan(chroma(source)));
      expect(
        () => colors.resolve(
          skir.PresentationColor.createAdjusted(
            source: accent,
            lightness: 2,
            chroma: 0,
          ),
          scope,
        ),
        throwsA(isA<PresentationValueFailure>()),
      );
    });

    test("brightness colors follow the editor theme", () {
      final color = skir.PresentationColor.createBrightness(
        light: skir.PresentationColor.wrapValue(
          Colors.white.portableExpression,
        ),
        dark: skir.PresentationColor.wrapValue(Colors.black.portableExpression),
      );
      expect(light.resolve(color, scope).toARGB32(), Colors.white.toARGB32());
      expect(dark.resolve(color, scope).toARGB32(), Colors.black.toARGB32());
    });

    test("numbers use the first matching state rule", () {
      final idle = light;
      final picked = idle.copyWith(
        interaction: const PresentationInteraction(selected: true),
      );
      final value = stateNumber(1, match: selected, value: 0.9);
      expect(idle.number(value, scope), 1);
      expect(picked.number(value, scope), 0.9);
      expect(
        () => idle.number(
          skir.PresentationNumber.wrapValue(textLiteral("wide")),
          scope,
        ),
        throwsA(isA<PresentationValueFailure>()),
      );
    });

    test("a selection override reads as the spring the service sent", () {
      expect(
        selectMotion.reading,
        const MotionReading.read(
          MoveOverrides(
            selected: MotionOverride(
              curve: MotionShape.spring(stiffness: 280, damping: 17),
            ),
          ),
        ),
      );
    });
  });

  group("service motion", () {
    testWidgets(
      "hovering a selected card plays hoverIn as tuned, not the selection override",
      (tester) async {
        final (:interact, :scale, :riser) = await tester.stateTransform(
          policy: transitionOverrides(
            selected: skir.PresentationTransition.wrapSpring(
              skir.PresentationSpring(stiffness: 60, damping: 4),
            ),
          ),
          hovered: 1.05,
          withPanelRiser: true,
        );
        interact(const PresentationInteraction(selected: true));
        await tester.pumpAndSettle();
        interact(const PresentationInteraction(selected: true, hovered: true));
        riser.hover();
        for (var frame = 0; frame < 12; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect((scale() - 1) / 0.05, closeTo(riser.progress(), 0.01));
        }
      },
    );

    testWidgets(
      "a hovered presentation with no motion code rises in step with the panel's own hover",
      (tester) async {
        final (:interact, :scale, :riser) = await tester.stateTransform(
          policy: null,
          hovered: 1.05,
          withPanelRiser: true,
        );
        interact(const PresentationInteraction(hovered: true));
        riser.hover();
        for (var frame = 0; frame < 12; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          // Same progress along the same token, though the travel differs.
          expect((scale() - 1) / 0.05, closeTo(riser.progress(), 0.01));
        }
      },
    );

    testWidgets(
      "a duration the service sends for hover is the one that plays",
      (tester) async {
        final (:interact, :scale, riser: _) = await tester.stateTransform(
          policy: transitionOverrides(
            hovered: timedTransition(milliseconds: 750),
          ),
          hovered: 1.05,
        );
        final own = tester.tokenTime(MotionToken.hoverIn);
        interact(const PresentationInteraction(hovered: true));
        await tester.pump();
        await tester.pump(own + const Duration(milliseconds: 20));
        // The panel's own hoverIn has landed by now; the sent 750 ms has not.
        expect(tester.hasRunningAnimations, isTrue);
        await tester.pump(const Duration(milliseconds: 750) - own);
        expect(scale(), closeTo(1.05, 0.0005));
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets(
      "reduced motion lands at once even with a sent duration and curve",
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final (:interact, :scale, riser: _) = await tester.stateTransform(
          policy: transitionOverrides(
            hovered: timedTransition(
              milliseconds: 750,
              curve: skir.PresentationTimedCurve.wrapStrike(0.2),
            ),
          ),
          hovered: 1.05,
        );
        interact(const PresentationInteraction(hovered: true));
        await tester.pump();
        expect(scale(), 1.05);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets("a sent spring settles by itself", (tester) async {
      final (:interact, :scale, riser: _) = await tester.stateTransform(
        policy: transitionOverrides(
          hovered: skir.PresentationTransition.wrapSpring(
            skir.PresentationSpring(stiffness: 120, damping: 8),
          ),
        ),
        hovered: 1.05,
      );
      interact(const PresentationInteraction(hovered: true));
      await tester.pump();
      await tester.pump(tester.tokenTime(MotionToken.hoverIn));
      // Still settling after the panel's own hover would have landed.
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(scale(), closeTo(1.05, 0.0005));
    });

    testWidgets(
      "a press given only a duration settles then with the same bounce",
      (tester) async {
        Future<(double peak, Duration settled)> run(int? milliseconds) async {
          final (:interact, :scale, riser: _) = await tester.stateTransform(
            policy: milliseconds == null
                ? null
                : transitionOverrides(
                    pressed: timedTransition(milliseconds: milliseconds),
                  ),
            pressed: 0.93,
          );
          interact(const PresentationInteraction(pressed: true));
          return tester.peakAndSettle(scale, target: 0.93);
        }

        final own = await run(null);
        final slow = await run(1200);
        final tuned = tester.tokenTime(MotionToken.press);
        // Overshoot is a fraction of the travel, so the same damping ratio
        // gives the same peak.
        expect(slow.$1, lessThan(0.93));
        expect(slow.$1, closeTo(own.$1, 0.0005));
        // The sent time stretches the whole settle by the same factor.
        expect(slow.$2, greaterThan(own.$2));
        expect(
          slow.$2.inMicroseconds / own.$2.inMicroseconds,
          closeTo(1200 / tuned.inMilliseconds, 0.03),
        );
      },
    );

    testWidgets(
      "a new state mid move continues from where the paint is, with its speed",
      (tester) async {
        final (:interact, :scale, riser: _) = await tester.stateTransform(
          policy: null,
          hovered: 1.05,
          focused: 1.1,
        );
        interact(const PresentationInteraction(hovered: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final before = scale();
        await tester.pump(const Duration(milliseconds: 16));
        final step = scale() - before;
        interact(const PresentationInteraction(hovered: true, focused: true));
        await tester.pump();
        final retargeted = scale();
        await tester.pump(const Duration(milliseconds: 16));
        // No jump back, and no restart from rest: the next frame moves at
        // least as far.
        expect(retargeted, closeTo(before + step, 0.0005));
        expect(scale() - retargeted, greaterThanOrEqualTo(step));
      },
    );

    testWidgets("a value changed by new data, not by the user, lands at once", (
      tester,
    ) async {
      final (:scale, :setIdleScale) = await tester.stateTransformWithData(
        idle: 1,
      );
      setIdleScale(1.2);
      await tester.pump();
      expect(scale(), 1.2);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("a malformed override shows the presentation diagnostic", (
      tester,
    ) async {
      await tester.stateTransform(
        policy: transitionOverrides(focused: timedTransition(milliseconds: -1)),
        hovered: 1.05,
      );
      expect(
        find.text("Presentation duration cannot be negative"),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
