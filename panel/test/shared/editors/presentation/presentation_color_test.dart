import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  final scope = PortablePresentationScope(
    bindings: const {},
    budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
  );
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
      var interaction = const PresentationInteraction();
      late StateSetter update;
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
              source: _color(accent),
              alpha: 0.7,
            ),
          ),
          _rule([skir.PresentationInteractionState.selected], accent),
          skir.PresentationStateColorRule(
            match: skir.PresentationStateMatch(
              required_: [skir.PresentationInteractionState.hovered],
              excluded: const [],
            ),
            color: skir.PresentationColor.createAlpha(
              source: _color(accent),
              alpha: 0.5,
            ),
          ),
        ],
        fallback: skir.PresentationColor.createAlpha(
          source: _color(accent),
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
        fallback: _color(accent),
      );
      final label = _node(
        "label",
        skir.PresentationElement.wrapText(
          (skir.TextContent.mutable()..value = "Adventure".portableExpression)
              .toFrozen(),
        ),
      );
      final icon = _node(
        "icon",
        skir.PresentationElement.createIcon(
          name: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>'
              .portableExpression,
          color: null,
          size: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(24)),
          semanticLabel: null,
        ),
      );
      final row = _node(
        "row",
        skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createRow(
            layout: skir.AxisChildrenLayout(
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
      final root = _column(
        "root",
        _node(
          "surface",
          skir.PresentationElement.createContainer(
            backgroundColor: fill,
            foregroundColor: foreground,
            transitionMilliseconds: 100,
            border: null,
            radius: skir.PresentationRadius.large,
            child: _column(
              "body",
              _node(
                "alignment",
                skir.PresentationElement.createAlign(
                  alignment: skir.PresentationAlignment.center,
                  child: row,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpTestApp(
        child: Surface(
          color: canvas,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 100,
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
        ),
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
        update(() => interaction = state);
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
    final root = _node(
      "surface",
      skir.PresentationElement.createContainer(
        child: _node(
          "label",
          skir.PresentationElement.wrapText(
            (skir.TextContent.mutable()
                  ..value = "Foreground".portableExpression)
                .toFrozen(),
          ),
        ),
        backgroundColor: null,
        foregroundColor: _color(Colors.orange),
        transitionMilliseconds: 0,
        border: null,
        radius: skir.PresentationRadius.none,
      ),
    );
    await tester.pumpTestApp(
      child: Surface(
        color: canvas,
        child: PortablePresentationNodeRenderer(node: root, scope: scope),
      ),
    );
    final element = tester.element(find.text("Foreground"));
    expect(Surface.colorOf(element), canvas);
    expect(Surface.foregroundOf(element).toARGB32(), Colors.orange.toARGB32());
  });
  PresentationColorEnvironment environment({
    PresentationInteraction interaction = const PresentationInteraction(),
  }) => PresentationColorEnvironment(
    theme: ThemeData.dark(),
    appearance: appearance,
    interaction: interaction,
  );

  test("color operations preserve authored transparency and use the actual surface", () {
    final colors = environment();
    final transparent = skir.PresentationColor.createAlpha(
      source: _color(const Color(0x00000000)),
      alpha: 0.7,
    );
    expect(colors.resolve(transparent, scope), const Color(0x00000000));
    final alpha = skir.PresentationColor.createAlpha(
      source: _color(const Color(0x803366ff)),
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
      source: _color(overlay),
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
          _rule([
            skir.PresentationInteractionState.selected,
            skir.PresentationInteractionState.hovered,
          ], Colors.yellow),
          _rule(
            [skir.PresentationInteractionState.selected],
            Colors.red,
            excluded: [skir.PresentationInteractionState.disabled],
          ),
          _rule([skir.PresentationInteractionState.hovered], Colors.blue),
          _rule([skir.PresentationInteractionState.focused], Colors.green),
          _rule([skir.PresentationInteractionState.pressed], Colors.orange),
        ],
        fallback: _color(Colors.grey),
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
          environment(interaction: interaction)
              .resolve(color, scope)
              .toARGB32(),
          expected.toARGB32(),
        );
      }
    },
  );

  test("malformed and excessive policies fail visibly", () {
    final colors = environment();
    for (final alpha in [double.nan, double.infinity, -0.1, 1.1]) {
      expect(
        () => colors.resolve(
          skir.PresentationColor.createAlpha(
            source: _color(Colors.red),
            alpha: alpha,
          ),
          scope,
        ),
        throwsA(isA<PresentationColorFailure>()),
      );
    }
    expect(
      () => colors.resolve(skir.PresentationColor.unknown, scope),
      throwsA(isA<PresentationColorFailure>()),
    );
    expect(
      () => colors.resolve(
        skir.PresentationColor.createStates(
          rules: [
            _rule(
              [skir.PresentationInteractionState.selected],
              Colors.red,
              excluded: [skir.PresentationInteractionState.selected],
            ),
          ],
          fallback: _color(Colors.black),
        ),
        scope,
      ),
      throwsA(isA<PresentationColorFailure>()),
    );
    var recursive = _color(Colors.red);
    for (var i = 0; i < 65; i++) {
      recursive = skir.PresentationColor.createAlpha(
        source: recursive,
        alpha: 1,
      );
    }
    expect(
      () => colors.resolve(recursive, scope),
      throwsA(isA<PresentationColorFailure>()),
    );
    final limited = PortablePresentationScope(
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 1, maxCollectionItems: 1),
    );
    expect(
      () => colors.resolve(
        skir.PresentationColor.createAlpha(
          source: _color(Colors.red),
          alpha: 1,
        ),
        limited,
      ),
      throwsA(isA<PresentationColorFailure>()),
    );
  });

  test("disabled rules include presentation enablement", () {
    final policy = skir.PresentationColor.createStates(
      rules: [
        _rule([skir.PresentationInteractionState.disabled], Colors.grey),
      ],
      fallback: _color(Colors.red),
    );
    expect(
      environment().resolve(policy, scope.withEnabled(false)).toARGB32(),
      Colors.grey.toARGB32(),
    );
  });
  testWidgets("nested interaction owners replace parent selection", (
    tester,
  ) async {
    late PresentationInteraction observed;
    await tester.pumpTestApp(
      child: const PresentationInteractionScope(
        value: PresentationInteraction(selected: true, hovered: true),
        child: _InteractionOwnerProbe(),
      ),
    );
    final element = tester.element(find.text("Independent"));
    observed = PresentationInteractionScope.of(element);
    expect(observed.selected, isFalse);
    expect(observed.hovered, isFalse);
  });
}

skir.PresentationNode _node(String id, skir.PresentationElement element) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: element,
    );
skir.PresentationNode _column(String id, skir.PresentationNode child) => _node(
  id,
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      layout: skir.AxisChildrenLayout(
        spacing: 0,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.stretch,
      ),
      children: [skir.AxisChild.wrapFixed(child)],
    ),
  ),
);

skir.PresentationColor _color(Color color) =>
    skir.PresentationColor.wrapValue(color.portableExpression);
skir.PresentationStateColorRule _rule(
  List<skir.PresentationInteractionState> required,
  Color color, {
  List<skir.PresentationInteractionState> excluded = const [],
}) => skir.PresentationStateColorRule(
  match: skir.PresentationStateMatch(required_: required, excluded: excluded),
  color: _color(color),
);

class _InteractionOwnerProbe extends StatelessWidget {
  const _InteractionOwnerProbe();
  @override
  Widget build(BuildContext context) => const PresentationInteractionScope(
    value: PresentationInteraction(),
    child: Text("Independent"),
  );
}
