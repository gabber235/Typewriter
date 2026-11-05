import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  late PortablePresentationScope scope;
  setUp(() {
    scope = unboundPresentationScope();
  });
  final appearance = SurfaceAppearance(
    color: Colors.black,
    foreground: Colors.white,
    secondaryForeground: Colors.grey,
  );

  testWidgets(
    "authored surfaces center content and share interaction colors across icon and text",
    (tester) async {
      const accent = Color(0xff3366cc);
      const canvas = Color(0xff171c22);
      final ambient = skir.PresentationColor.wrapAmbient(
        skir.PresentationAmbientColor.background,
      );
      final fill = skir.PresentationColor.createStates(
        rules: [
          skir.PresentationStateColorRule(
            match: skir.PresentationStateMatch(
              required_: [
                skir.PresentationInteractionState.selected,
                skir.PresentationInteractionState.hovered,
              ],
              excluded: const [],
            ),
            color: skir.PresentationColor.createAlpha(
              source: presentationColor(accent),
              alpha: 0.7,
            ),
          ),
          stateColorRule([skir.PresentationInteractionState.selected], accent),
          skir.PresentationStateColorRule(
            match: skir.PresentationStateMatch(
              required_: [skir.PresentationInteractionState.hovered],
              excluded: const [],
            ),
            color: skir.PresentationColor.createAlpha(
              source: presentationColor(accent),
              alpha: 0.5,
            ),
          ),
        ],
        fallback: skir.PresentationColor.createAlpha(
          source: presentationColor(accent),
          alpha: 0.2,
        ),
      );
      final foreground = skir.PresentationColor.createStates(
        rules: [
          skir.PresentationStateColorRule(
            match: skir.PresentationStateMatch(
              required_: [skir.PresentationInteractionState.hovered],
              excluded: const [],
            ),
            color: skir.PresentationColor.createContrast(
              source: ambient,
              mode: skir.PresentationContrastMode.monochrome,
            ),
          ),
          skir.PresentationStateColorRule(
            match: skir.PresentationStateMatch(
              required_: [skir.PresentationInteractionState.selected],
              excluded: const [],
            ),
            color: skir.PresentationColor.createContrast(
              source: ambient,
              mode: skir.PresentationContrastMode.tonal,
            ),
          ),
        ],
        fallback: presentationColor(accent),
      );
      final label = presentationNode(
        "label",
        skir.PresentationElement.wrapText(
          (skir.TextContent.mutable()..value = "Adventure".portableExpression)
              .toFrozen(),
        ),
      );
      final icon = presentationNode(
        "icon",
        skir.PresentationElement.createIcon(
          name: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>'
              .portableExpression,
          color: null,
          size: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(24)),
          semanticLabel: null,
        ),
      );
      final row = presentationNode(
        "row",
        skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createRow(
            layout: skir.AxisChildrenLayout(
              clipOverflow: false,

              spacing: 12,
              mainAxisAlignment: skir.MainAxisAlignment.center,
              crossAxisAlignment: skir.CrossAxisAlignment.center,
            ),
            children: [
              skir.AxisChild.wrapFixed(icon),
              skir.AxisChild.wrapFixed(label),
            ],
          ),
        ),
      );
      final root = presentationColumn("root", [
        presentationNode(
          "surface",
          skir.PresentationElement.createContainer(
            backgroundColor: fill,
            foregroundColor: foreground,
            transition: skir.PresentationTransitionPolicy(
              rules: const [],
              fallback: skir.PresentationTransition(
                milliseconds: 100,
                curve: skir.PresentationCurve.linear,
              ),
            ),
            shadows: const [],
            border: null,
            radius: skir.PresentationRadius.large,
            child: presentationColumn("body", [
              presentationNode(
                "alignment",
                skir.PresentationElement.createAlign(
                  alignment: skir.PresentationAlignment.center,
                  child: row,
                ),
              ),
            ], layout: _stretch),
          ),
        ),
      ], layout: _stretch);
      final interact = await tester.showInteractiveNode(
        root,
        scope: scope,
        size: const Size(400, 100),
        surface: canvas,
      );
      final text = find.text("Adventure");
      final surface = find.byType(SurfaceContainer);
      expect(tester.getSize(surface), const Size(400, 100));
      expect(
        tester.getCenter(text).dy,
        closeTo(tester.getCenter(surface).dy, 0.01),
      );
      expect(
        tester.widget<Text>(text).style?.color?.toARGB32(),
        accent.toARGB32(),
      );
      for (final (state, opacity) in [
        (const PresentationInteraction(hovered: true), 0.5),
        (const PresentationInteraction(selected: true), 1.0),
        (const PresentationInteraction(selected: true, hovered: true), 0.7),
      ]) {
        interact(state);
        await tester.pumpAndSettle();
        final element = tester.element(text);
        final shown = Surface.appearanceOf(element);
        final expected = Color.alphaBlend(
          accent.withValues(alpha: opacity),
          canvas,
        );
        expect(shown.color, expected);
        expect(tester.widget<Text>(text).style?.color, shown.foreground);
        expect(
          IconTheme.of(tester.element(find.byType(Icones))).color,
          shown.foreground,
        );
        if (state.hovered) {
          expect(
            shown.foreground,
            ThemeData.estimateBrightnessForColor(expected) == Brightness.dark
                ? Colors.white
                : Colors.black,
          );
        } else {
          expect(shown.foreground, expected.on(element));
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("foreground only presentation containers preserve the canvas", (
    tester,
  ) async {
    const canvas = Color(0xff112233);
    final root = presentationNode(
      "surface",
      skir.PresentationElement.createContainer(
        child: presentationNode(
          "label",
          skir.PresentationElement.wrapText(
            (skir.TextContent.mutable()
                  ..value = "Foreground".portableExpression)
                .toFrozen(),
          ),
        ),
        backgroundColor: null,
        foregroundColor: presentationColor(Colors.orange),
        transition: null,
        shadows: const [],
        border: null,
        radius: skir.PresentationRadius.none,
      ),
    );
    await tester.showComponent(
      Surface(
        color: canvas,
        child: PortablePresentationNodeRenderer(node: root, scope: scope),
      ),
    );
    final element = tester.element(find.text("Foreground"));
    expect(Surface.colorOf(element), canvas);
    expect(Surface.foregroundOf(element).toARGB32(), Colors.orange.toARGB32());
  });
  final colors = PresentationValueEnvironment(
    theme: ThemeData.dark(),
    appearance: appearance,
    interaction: const PresentationInteraction(),
  );

  test("color operations preserve authored transparency and use the actual surface", () {
    final transparent = skir.PresentationColor.createAlpha(
      source: presentationColor(const Color(0x00000000)),
      alpha: 0.7,
    );
    expect(colors.resolve(transparent, scope), const Color(0x00000000));
    final alpha = skir.PresentationColor.createAlpha(
      source: presentationColor(const Color(0x803366ff)),
      alpha: 0.5,
    );
    expect(colors.resolve(alpha, scope).a, closeTo(0.25, 0.003));
    final onSurface = skir.PresentationColor.createContrast(
      source: skir.PresentationColor.wrapAmbient(
        skir.PresentationAmbientColor.background,
      ),
      mode: skir.PresentationContrastMode.tonal,
    );
    expect(
      colors.resolve(onSurface, scope),
      Colors.black.onBrightness(Brightness.dark),
    );
    final overlay = const Color(0x803366ff);
    final onOverlay = skir.PresentationColor.createContrast(
      source: presentationColor(overlay),
      mode: skir.PresentationContrastMode.tonal,
    );
    expect(
      colors.resolve(onOverlay, scope),
      Color.alphaBlend(overlay, appearance.color).onBrightness(Brightness.dark),
    );
  });

  test(
    "state rules use first match, required and excluded states, and fallback",
    () {
      final color = skir.PresentationColor.createStates(
        rules: [
          stateColorRule([
            skir.PresentationInteractionState.selected,
            skir.PresentationInteractionState.hovered,
          ], Colors.yellow),
          stateColorRule(
            [skir.PresentationInteractionState.selected],
            Colors.red,
            excluded: [skir.PresentationInteractionState.disabled],
          ),
          stateColorRule([
            skir.PresentationInteractionState.hovered,
          ], Colors.blue),
          stateColorRule([
            skir.PresentationInteractionState.focused,
          ], Colors.green),
          stateColorRule([
            skir.PresentationInteractionState.pressed,
          ], Colors.orange),
        ],
        fallback: presentationColor(Colors.grey),
      );
      for (final (interaction, expected) in [
        (
          const PresentationInteraction(selected: true, hovered: true),
          Colors.yellow,
        ),
        (const PresentationInteraction(selected: true), Colors.red),
        (
          const PresentationInteraction(selected: true, disabled: true),
          Colors.grey,
        ),
        (const PresentationInteraction(hovered: true), Colors.blue),
        (const PresentationInteraction(focused: true), Colors.green),
        (const PresentationInteraction(pressed: true), Colors.orange),
        (const PresentationInteraction(), Colors.grey),
      ]) {
        expect(
          PresentationValueEnvironment(
            theme: ThemeData.dark(),
            appearance: appearance,
            interaction: interaction,
          ).resolve(color, scope).toARGB32(),
          expected.toARGB32(),
        );
      }
    },
  );

  test("malformed and excessive policies fail visibly", () {
    for (final alpha in [double.nan, double.infinity, -0.1, 1.1]) {
      expect(
        () => colors.resolve(
          skir.PresentationColor.createAlpha(
            source: presentationColor(Colors.red),
            alpha: alpha,
          ),
          scope,
        ),
        throwsA(isA<PresentationValueFailure>()),
      );
    }
    expect(
      () => colors.resolve(skir.PresentationColor.unknown, scope),
      throwsA(isA<PresentationValueFailure>()),
    );
    expect(
      () => colors.resolve(
        skir.PresentationColor.createStates(
          rules: [
            stateColorRule(
              [skir.PresentationInteractionState.selected],
              Colors.red,
              excluded: [skir.PresentationInteractionState.selected],
            ),
          ],
          fallback: presentationColor(Colors.black),
        ),
        scope,
      ),
      throwsA(isA<PresentationValueFailure>()),
    );
    var recursive = presentationColor(Colors.red);
    for (var i = 0; i < 65; i++) {
      recursive = skir.PresentationColor.createAlpha(
        source: recursive,
        alpha: 1,
      );
    }
    expect(
      () => colors.resolve(recursive, scope),
      throwsA(isA<PresentationValueFailure>()),
    );
    final limited = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 1, maxCollectionItems: 1),
    );
    expect(
      () => colors.resolve(
        skir.PresentationColor.createAlpha(
          source: presentationColor(Colors.red),
          alpha: 1,
        ),
        limited,
      ),
      throwsA(isA<PresentationValueFailure>()),
    );
  });

  test("disabled rules include presentation enablement", () {
    final policy = skir.PresentationColor.createStates(
      rules: [
        stateColorRule([
          skir.PresentationInteractionState.disabled,
        ], Colors.grey),
      ],
      fallback: presentationColor(Colors.red),
    );
    expect(
      colors.resolve(policy, scope.withEnabled(false)).toARGB32(),
      Colors.grey.toARGB32(),
    );
  });
  testWidgets("nested interaction owners replace parent selection", (
    tester,
  ) async {
    late PresentationInteraction observed;
    await tester.showComponent(
      const PresentationInteractionScope(
        value: PresentationInteraction(selected: true, hovered: true),
        child: PresentationInteractionScope(
          value: PresentationInteraction(),
          child: Text("Independent"),
        ),
      ),
    );
    final element = tester.element(find.text("Independent"));
    observed = PresentationInteractionScope.of(element);
    expect(observed.selected, isFalse);
    expect(observed.hovered, isFalse);
  });
}

final _stretch = skir.AxisChildrenLayout(
  clipOverflow: false,
  spacing: 0,
  mainAxisAlignment: skir.MainAxisAlignment.start,
  crossAxisAlignment: skir.CrossAxisAlignment.stretch,
);
