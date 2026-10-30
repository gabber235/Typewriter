import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/dropdown.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("the dropdown opens, filters and selects from the keyboard, "
      "then gives editing back", (tester) async {
    final panel = (await tester.pumpStory(dropdownUseCase))!;
    InteractionMode mode() =>
        panel.container.read(currentInteractionModeProvider);

    await panel.press(LogicalKeyboardKey.tab);
    await panel.press(LogicalKeyboardKey.enter);
    expect(mode(), isA<InsertMode>());
    await tester.enterText(find.byType(EditableText).first, "Fab");
    await panel.settle();
    await panel.press(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await panel.settle();

    expect(find.text("Fabric"), findsOneWidget);
    expect(mode(), isA<NormalMode>());

    await panel.press(LogicalKeyboardKey.enter);
    await panel.press(LogicalKeyboardKey.escape);
    expect(find.text("Fabric"), findsOneWidget);
    expect(mode(), isA<NormalMode>());
  });
}
