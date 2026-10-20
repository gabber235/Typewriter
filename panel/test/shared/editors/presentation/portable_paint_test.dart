import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

/// The stack around the authored cover text, not one the test app adds.
final coverStack = find
    .ancestor(of: find.text("Cover"), matching: find.byType(Stack))
    .first;

/// The nearest transform above the authored cover text.
final coverTransform = find
    .ancestor(of: find.text("Cover"), matching: find.byType(Transform))
    .first;

void main() {
  late PortablePresentationScope scope;
  setUp(() {
    scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );
  });

  final selected = skir.PresentationStateMatch(
    required_: [skir.PresentationInteractionState.selected],
    excluded: const [],
  );
  final hovered = skir.PresentationStateMatch(
    required_: [skir.PresentationInteractionState.hovered],
    excluded: const [],
  );
  final selectMotion = skir.PresentationTransitionPolicy(
    rules: [
      skir.PresentationStateTransitionRule(
        match: selected,
        transition: skir.PresentationTransition(
          milliseconds: 750,
          curve: skir.PresentationCurve.wrapElasticOut(0.9),
        ),
      ),
    ],
    fallback: skir.PresentationTransition(
      milliseconds: 300,
      curve: skir.PresentationCurve.emphasized,
    ),
  );
  skir.PresentationNumber number(double value) =>
      skir.PresentationNumber.wrapValue(numberLiteral(value));
  skir.PresentationNumber whenSelected(double rest, double raised) =>
      skir.PresentationNumber.createStates(
        rules: [
          skir.PresentationStateNumberRule(
            match: selected,
            value: numberLiteral(raised),
          ),
        ],
        fallback: numberLiteral(rest),
      );
  final label = presentationText("label", textLiteral("Cover"));

  /// Pumps [root] under an interaction owner that [update] changes.
  Future<void Function(PresentationInteraction)> pumpInteractive(
    WidgetTester tester,
    skir.PresentationNode root, {
    Size size = const Size(200, 260),
  }) async {
    var interaction = const PresentationInteraction();
    late StateSetter update;
    await tester.pumpTestApp(
      child: Center(
        child: SizedBox.fromSize(
          size: size,
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return PresentationInteractionScope(
                value: interaction,
                child: PortablePresentationNodeRenderer(
                  node: root,
                  scope: scope,
                  fillAvailableSpace: true,
                ),
              );
            },
          ),
        ),
      ),
    );
    return (next) => update(() => interaction = next);
  }

  testWidgets(
    "positioned stack children follow state and animate with the entered state's transition",
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
                top: whenSelected(10, 15),
                start: null,
                end: whenSelected(0, 14),
                bottom: whenSelected(10, 15),
                width: number(30),
                height: null,
                transition: selectMotion,
              ),
            ],
          ),
        ),
      );
      final interact = await pumpInteractive(tester, root);
      AnimatedPositionedDirectional positioned() =>
          tester.widget(find.byType(AnimatedPositionedDirectional));

      expect(
        tester.widget<Stack>(coverStack).alignment,
        AlignmentDirectional.center,
      );
      expect(
        [positioned().top, positioned().end, positioned().width],
        [10, 0, 30],
      );
      expect(positioned().duration, const Duration(milliseconds: 300));

      interact(const PresentationInteraction(selected: true));
      await tester.pump();
      expect([positioned().top, positioned().end], [15, 14]);
      expect(positioned().duration, const Duration(milliseconds: 750));
      expect(positioned().curve, isA<ElasticOutCurve>());
      await tester.pumpAndSettle();
      final spine = tester.getRect(find.text("Spine"));
      final stack = tester.getRect(coverStack);
      expect(stack.right - spine.right, closeTo(14, 0.01));
      expect(spine.top - stack.top, closeTo(15, 0.01));

      interact(const PresentationInteraction());
      await tester.pump();
      expect(positioned().duration, const Duration(milliseconds: 300));
      expect(positioned().curve, Curves.fastEaseInToSlowEaseOut);
      await tester.pumpAndSettle();
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
              start: number(0),
              end: number(0),
              bottom: null,
              width: number(10),
              height: null,
              transition: null,
            ),
          ],
        ),
      ),
    );
    await pumpInteractive(tester, root);
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
    await pumpInteractive(tester, root, size: const Size(240, 333));
    final surface = find.byType(SurfaceContainer);
    expect(tester.getSize(surface), const Size(175, 230));
    final shadow = tester
        .widget<SurfaceContainer>(surface)
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
          rotateY: whenSelected(0, 0.05),
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
      await tester.pumpTestApp(
        child: Center(
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
      await tester.pump(const Duration(milliseconds: 150));
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
    PresentationValueEnvironment environment(Brightness brightness) =>
        PresentationValueEnvironment(
          theme: ThemeData(brightness: brightness),
          appearance: SurfaceAppearance(
            color: Colors.black,
            foreground: Colors.white,
            secondaryForeground: Colors.grey,
          ),
          interaction: const PresentationInteraction(),
        );

    test("adjusted colors move lightness and chroma in OkLch", () {
      final colors = environment(Brightness.light);
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
        throwsA(isA<PresentationColorFailure>()),
      );
    });

    test("brightness colors follow the editor theme", () {
      final color = skir.PresentationColor.createBrightness(
        light: skir.PresentationColor.wrapValue(
          Colors.white.portableExpression,
        ),
        dark: skir.PresentationColor.wrapValue(Colors.black.portableExpression),
      );
      expect(
        environment(Brightness.light).resolve(color, scope).toARGB32(),
        Colors.white.toARGB32(),
      );
      expect(
        environment(Brightness.dark).resolve(color, scope).toARGB32(),
        Colors.black.toARGB32(),
      );
    });

    test("numbers and motions use the first matching state rule", () {
      final idle = environment(Brightness.light);
      final picked = idle.copyWith(
        interaction: const PresentationInteraction(selected: true),
      );
      final value = whenSelected(1, 0.9);
      expect(idle.number(value, scope), 1);
      expect(picked.number(value, scope), 0.9);
      expect(
        idle.motion(selectMotion, scope).duration,
        const Duration(milliseconds: 300),
      );
      expect(
        picked.motion(selectMotion, scope).duration,
        const Duration(milliseconds: 750),
      );
      expect(idle.motion(null, scope), PresentationMotion.immediate);
      expect(
        () => idle.number(
          skir.PresentationNumber.wrapValue(textLiteral("wide")),
          scope,
        ),
        throwsA(isA<PresentationColorFailure>()),
      );
    });
  });
}
