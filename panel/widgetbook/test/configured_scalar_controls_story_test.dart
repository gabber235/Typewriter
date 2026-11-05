import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/configured_scalar_controls.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a placement offset completes to the nearest half", (
    tester,
  ) async {
    final panel = await tester.pumpStory(configuredScalarControlsUseCase);
    final offset = panel.field("Placement offset");
    expect(offset.value, "12.25");

    await offset.type("12.26");
    await panel.press(LogicalKeyboardKey.escape);

    expect(offset.value, "12.5");
  });

  testWidgets("removing icons starts the text at the field edge and keeps it "
      "readable", (tester) async {
    await tester.pumpStory(configuredScalarControlsUseCase);
    final withIcon = tester.getTopLeft(find.text("Quest checkpoint")).dx;

    final panel = await tester.pumpStory(
      configuredScalarControlsUseCase,
      knobs: {"Scalar remove icons": "true", "Scalar read only": "true"},
    );

    expect(panel.field("Checkpoint name").value, "Quest checkpoint");
    expect(panel.field("Checkpoint name").isReadOnly, isTrue);
    expect(
      tester.getTopLeft(find.text("Quest checkpoint")).dx,
      lessThan(withIcon),
    );
  });
}
