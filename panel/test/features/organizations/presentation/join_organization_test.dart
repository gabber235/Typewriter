import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("one press on Cancel request cancels it with no dialog", (
    tester,
  ) async {
    final (:panel, :cancels) = await tester.pumpPendingJoinRequest();

    await panel.tapOn(find.bySemanticsLabel(RegExp("^Cancel request")).last);

    await panel.eventually(() => expect(cancels(), 1));
    expect(panel.shows("Awaiting approval"), isFalse);
    expect(panel.dialog.showing("Cancel join request?"), isFalse);
  });

  testWidgets("Delete on the focused request cancels it with no dialog", (
    tester,
  ) async {
    final (:panel, :cancels) = await tester.pumpPendingJoinRequest();
    await panel.tabTo("Cancel request", limit: 20);

    await panel.press(LogicalKeyboardKey.delete);

    await panel.eventually(() => expect(cancels(), 1));
    expect(panel.dialog.showing("Cancel join request?"), isFalse);
  });
}
