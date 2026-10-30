import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "a nested explicit heading call reserves its inherited position",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario(
        childLayout: inheritedFieldColumn([
          inspectorLayoutPart("child.part", inspectorDetailsPart),
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
          inspectorLayoutPart("family.heading", inspectorHeadingPart),
          inspectorLayoutRemainder("family.remaining"),
        ], id: "family"),
        familyInheritableNodes: [
          "family",
          "family.outer",
          "family.heading",
          "family.remaining",
        ],
      );
      addTearDown(fixture.dispose);
      final panel = await tester.showPresentationHost(
        fixture.host,
        scrolls: true,
      );

      expect(panel.shows("Entry heading"), isTrue);
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
      final fixture = InheritedInspectorLayoutScenario(
        childLayout: inheritedFieldColumn([
          inspectorLayoutPart("child.part", inspectorHeadingPart),
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
          inspectorLayoutRemainder("family.remaining"),
        ], id: "family"),
        familyInheritableNodes: ["family", "family.outer", "family.remaining"],
      );
      addTearDown(fixture.dispose);
      final panel = await tester.showPresentationHost(
        fixture.host,
        scrolls: true,
      );

      expect(
        find.textContaining("Replace or exclude the whole part"),
        findsWidgets,
      );
      expect(panel.shows("Entry heading"), isTrue);
      expect(panel.shows("Outer content"), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
