import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/dropdown.stories.dart";

void main() {
  testWidgets("dropdown story supports keyboard entry selection and exit", (
    tester,
  ) async {
    await tester.pumpWidget(const DropdownInteractionStory());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text("INSERT"), findsOneWidget);
    final input = find.descendant(
      of: find.byType(Dropdown<String>),
      matching: find.byType(TextField),
    );
    await tester.enterText(input, "Fab");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text("Selected: fabric"), findsOneWidget);
    expect(find.text("NORMAL"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("Selected: fabric"), findsOneWidget);
    expect(find.text("NORMAL"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
