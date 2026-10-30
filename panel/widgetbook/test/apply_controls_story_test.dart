import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editing/apply_controls.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("Apply and Discard reconcile the field across repeated edits", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(applyControlsUseCase))!;
    final field = panel.fieldAt(0);
    expect(panel.applyControls.actions, isEmpty);

    await field.type("Draft");
    expect(panel.applyControls.actions, containsAll(["Apply", "Discard"]));
    await panel.applyControls.press("Discard");
    expect(field.value, "Saved value");
    expect(panel.applyControls.actions, isEmpty);

    await field.type("Accepted");
    await panel.applyControls.press("Apply");
    expect(field.value, "Accepted");
    expect(panel.applyControls.actions, isEmpty);

    await field.type("Later");
    await panel.applyControls.press("Discard");
    expect(field.value, "Accepted");
    expect(panel.applyControls.actions, isEmpty);
  });

  testWidgets("a lost save reply keeps the edit and offers only Refresh", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(
      applyControlsUseCase,
      knobs: {"Save reply": "Lost"},
    ))!;
    final field = panel.fieldAt(0);

    await field.type("Pending");
    await panel.applyControls.press("Apply");

    expect(field.value, "Pending");
    expect(panel.applyControls.isEnabled("Apply"), isFalse);
    expect(panel.applyControls.actions, isNot(contains("Retry")));
    expect(panel.applyControls.actions, isNot(contains("Discard")));
    expect(panel.applyControls.actions, contains("Refresh"));
  });
}
