import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_presentation_renderer.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a text list shows its entries and adds and removes items", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      collectionPresentationUseCase,
      knobs: {"Collection width": "320"},
    );
    final entries = visibleFieldValues();
    expect(entries, hasLength(3));

    await panel.tapOn(find.tooltip("Add item"));
    expect(visibleFieldValues(), hasLength(4));

    await panel.tapOn(find.tooltip("Remove item").last);
    expect(visibleFieldValues(), entries);
  });

  testWidgets("an empty collection keeps Add in its header", (tester) async {
    final panel = await tester.pumpStory(
      collectionPresentationUseCase,
      knobs: {"Empty collection": "true"},
    );
    expect(visibleFieldValues(), isEmpty);

    await panel.tapOn(find.tooltip("Add item"));

    expect(visibleFieldValues(), hasLength(1));
  });

  testWidgets("a read only collection shows its entries but takes no "
      "edits", (tester) async {
    final panel = await tester.pumpStory(
      collectionPresentationUseCase,
      knobs: {"Collection read only": "true"},
    );
    final entries = visibleFieldValues();
    expect(entries, ["Arrival", "Discovery", "Return"]);
    bool offered(Finder control) => [
      for (final element in control.evaluate())
        tester
            .getSemantics(find.byElementPredicate((it) => it == element))
            .getSemanticsData()
            .flagsCollection
            .isEnabled,
    ].any((enabled) => enabled != Tristate.isFalse);

    expect(panel.fieldAt(0).isReadOnly, isTrue);
    expect(offered(find.tooltip("Add item")), isFalse);
    expect(offered(find.tooltip("Remove item")), isFalse);

    await panel.fieldAt(0).type("Changed");

    expect(visibleFieldValues(), entries);
  });

  const examples = [
    "Text set",
    "Scalar map",
    "Authored step headers",
    "Generated step headers",
    "Structured map values",
    "Nested lists",
    "Direct resource links",
  ];
  for (final example in examples) {
    testWidgets("the $example example shows valid quest entries in a narrow "
        "inspector", (tester) async {
      final panel = await tester.pumpStory(
        collectionPresentationUseCase,
        knobs: {"Collection example": example, "Collection width": "320"},
      );

      expect(panel.shows("Quest entries"), isTrue);
      expect(
        panel.shows("The authored value is structurally invalid."),
        isFalse,
      );
    });
  }
}
