import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "a nested explicit heading call reserves its inherited position",
    (tester) async {
      final fixture = _scenario(childCallsOuter: true);
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);

      expect(find.text("Entry heading"), findsOneWidget);
      expect(
        find.textContaining("Replace or exclude the whole part"),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "an inherited atomic part cannot repeat a locally placed heading",
    (tester) async {
      final fixture = _scenario(childCallsOuter: false);
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);

      expect(
        find.textContaining("Replace or exclude the whole part"),
        findsWidgets,
      );
      expect(find.text("Entry heading"), findsOneWidget);
      expect(find.text("Outer content"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

InheritedInspectorLayoutScenario _scenario({required bool childCallsOuter}) =>
    InheritedInspectorLayoutScenario(
      childLayout: inheritedFieldColumn([
        inspectorLayoutPart(
          "child.part",
          childCallsOuter ? inspectorDetailsPart : inspectorHeadingPart,
        ),
        inspectorLayoutRemainder("child.remaining"),
      ], id: "child"),
      childInheritableNodes: ["child", "child.part", "child.remaining"],
      familyLayout: inheritedFieldColumn([
        inspectorLayoutPart(
          "family.outer",
          inspectorDetailsPart,
          body: inheritedFieldColumn([
            inspectorLayoutPart("family.outer.heading", inspectorHeadingPart),
            presentationNode(
              "family.outer.content",
              skir.PresentationElement.wrapText(
                (skir.TextContent.mutable()
                      ..value = textLiteral("Outer content"))
                    .toFrozen(),
              ),
            ),
          ], id: "family.outer.body"),
        ),
        if (childCallsOuter)
          inspectorLayoutPart("family.heading", inspectorHeadingPart),
        inspectorLayoutRemainder("family.remaining"),
      ], id: "family"),
      familyInheritableNodes: [
        "family",
        "family.outer",
        if (childCallsOuter) "family.heading",
        "family.remaining",
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  InheritedInspectorLayoutScenario fixture,
) => tester.pumpTestApp(
  child: Scaffold(
    body: SingleChildScrollView(
      child: PortablePresentationRenderer(host: fixture.host),
    ),
  ),
);
