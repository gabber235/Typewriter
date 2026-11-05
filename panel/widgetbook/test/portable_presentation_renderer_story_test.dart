import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_presentation_renderer.stories.dart";

import "support/stories.dart";

void main() {
  const layouts = {
    "Child controls order": (heading: true, details: true),
    "Excluded heading": (heading: false, details: true),
    "Replaced details": (heading: true, details: false),
  };
  for (final MapEntry(key: layout, value: shown) in layouts.entries) {
    testWidgets("the $layout inspector keeps its order and trims a written "
        "greeting", (tester) async {
      final panel = await tester.pumpStory(
        inheritedInspectorLayoutUseCase,
        knobs: {"Inspector layout": layout},
      );

      expect(visibleFieldValues(), [
        "Welcome",
        "Hello player",
        "Cooldown",
        if (shown.details) "10, 20",
      ]);
      expect(panel.shows("Entry heading"), shown.heading);
      expect(panel.shows("Details replaced"), !shown.details);

      await panel.fieldAt(0).enter("  Next  ");
      expect(panel.fieldAt(0).value, "Next");
    });
  }

  const names = {
    "Inherited trim": (label: "Name", written: "Next quest"),
    "Local label with inherited trim": (
      label: "Action name",
      written: "Next quest",
    ),
    "Explicit control": (label: "Exact name", written: "  Next quest  "),
  };
  for (final MapEntry(key: presentation, value: name) in names.entries) {
    testWidgets("the $presentation name writes ${name.written.trim()} under "
        "${name.label}", (tester) async {
      final panel = await tester.pumpStory(
        inheritedFieldPresentationUseCase,
        knobs: {"Name presentation": presentation},
      );

      await panel.field(name.label).enter("  Next quest  ");

      expect(panel.field(name.label).value, name.written);
    });
  }

  testWidgets("a disabled name cannot be edited", (tester) async {
    final panel = await tester.pumpStory(
      inheritedFieldPresentationUseCase,
      knobs: {"Name presentation": "Disabled"},
    );

    expect(panel.field("Name").isReadOnly, isTrue);
  });
}
