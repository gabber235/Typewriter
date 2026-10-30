import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/ui/input/input_field_container.stories.dart";
import "package:widgetbook_workspace/stories/shared/ui/input/validated_text_field.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a quest title enters editing with Enter and keeps its text "
      "after Escape", (tester) async {
    final panel = (await tester.pumpStory(inputFieldContainerUseCase))!;
    final title = panel.fieldAt(0);

    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.enter);
    expect(title.isFocused, isTrue);

    await title.type("The found lantern");
    await panel.press(LogicalKeyboardKey.escape);

    expect(title.value, "The found lantern");
  });

  testWidgets("a respawn delay explains invalid drafts and accepts a valid "
      "one", (tester) async {
    final panel = (await tester.pumpStory(validatedTextFieldUseCase))!;
    final delay = panel.fieldAt(0);
    expect(delay.value, "30");

    await delay.type("soon");
    expect(panel.shows("Enter whole seconds"), isTrue);

    await delay.type("7200");
    expect(panel.shows("Use at most 3600 seconds"), isTrue);

    await delay.type("45");
    expect(panel.shows("Enter whole seconds"), isFalse);
    expect(panel.shows("Use at most 3600 seconds"), isFalse);
    expect(delay.value, "45");
  });

  testWidgets("a mixed respawn delay takes the first valid edit", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(
      validatedTextFieldUseCase,
      knobs: {"Mixed selection": "true"},
    ))!;
    final delay = panel.fieldAt(0);
    expect(delay.value, isNot("30"));

    await delay.enter("12");

    expect(delay.value, "12");
  });
}
