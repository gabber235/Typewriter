import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("reference picker completes with Enter and cancels with Escape", (
    tester,
  ) async {
    String? result;
    var completed = false;
    await tester.pumpTestApp(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            result = await showReferencePicker<String>(
              context,
              candidates: const [
                ReferencePickerCandidate(
                  id: "welcome",
                  value: "selected",
                  label: "Welcome",
                ),
              ],
            );
            completed = true;
          },
          child: const Text("Choose"),
        ),
      ),
    );
    await tester.tap(find.text("Choose"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, "selected");

    completed = false;
    await tester.tap(find.text("Choose"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets("unavailable reference remains explained and cannot activate", (
    tester,
  ) async {
    var completed = false;
    await tester.pumpTestApp(
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            await showReferencePicker<String>(
              context,
              candidates: const [
                ReferencePickerCandidate(
                  id: "locked",
                  value: "locked",
                  label: "Locked",
                  disabledReason: "The opposite endpoint rejects this type",
                ),
              ],
            );
            completed = true;
          },
          child: const Text("Choose"),
        ),
      ),
    );
    await tester.tap(find.text("Choose"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(completed, isFalse);
    expect(find.text("The opposite endpoint rejects this type"), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
}
