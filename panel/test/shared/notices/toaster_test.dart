import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const publishFailed = "Publish failed";
  const saveFailed = "Save failed";

  testWidgets("a failed press toasts its reason without taking the focus", (
    tester,
  ) async {
    final panel = await tester.showFailingActions();

    await tester.tapKey(LogicalKeyboardKey.enter);
    await tester.pump(tester.settleTimeOf(MotionToken.surfaceIn));

    expect(panel.shows(publishFailed), isTrue);
    expect(panel.shows(FailingActionsPage.publishFailure), isTrue);
    expect(panel.focused, "Publish");
  });

  testWidgets("a toast left alone drains into Activity, which counts it "
      "until Activity opens", (tester) async {
    final panel = await tester.showFailingActions();

    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.shows(FailingActionsPage.publishFailure), isFalse);
    expect(panel.shows("1 failed"), isTrue);

    await panel.activity.open("1 failed");
    expect(panel.shows(publishFailed), isTrue);
    expect(panel.shows(FailingActionsPage.publishFailure), isTrue);
    await panel.activity.close();
    expect(
      panel.container.read(noticesProvider).any((notice) => notice.unread),
      isFalse,
    );
  });

  testWidgets("T moves the focus to the newest toast, which holds its time "
      "while focused", (tester) async {
    final panel = await tester.showFailingActions();

    await tester.failIntoToast();
    await tester.pump(testDrain * 2);

    expect(panel.focused, startsWith(publishFailed));
    expect(panel.shows(FailingActionsPage.publishFailure), isTrue);
  });

  testWidgets("R on a focused toast retries; a retry that works shows done, "
      "leaves, and keeps nothing in Activity", (tester) async {
    final panel = await tester.showFailingActions();
    await panel.press(LogicalKeyboardKey.arrowRight);
    await tester.failIntoToast();

    await tester.tapKey(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(find.bySemanticsLabel("Done. $saveFailed"), findsOneWidget);

    await panel.settle();
    expect(panel.shows(saveFailed), isFalse);
    expect(panel.container.read(noticesProvider), isEmpty);
    expect(panel.focused, "Save");
  });

  testWidgets("a retry that fails again keeps the toast with the new reason", (
    tester,
  ) async {
    final panel = await tester.showFailingActions();
    await tester.failIntoToast();

    await tester.tapKey(LogicalKeyboardKey.keyR);
    await tester.pump(tester.settleTimeOf(MotionToken.jam));

    expect(panel.shows(publishFailed), isTrue);
    expect(panel.container.read(noticesProvider).single.attempts, 1);
  });

  testWidgets("Escape dismisses the focused toast, gives the focus back, and "
      "keeps the failure in Activity as read", (tester) async {
    final panel = await tester.showFailingActions();
    await tester.failIntoToast();

    await panel.press(LogicalKeyboardKey.escape);

    expect(panel.shows(FailingActionsPage.publishFailure), isFalse);
    expect(panel.focused, "Publish");
    final kept = panel.container.read(noticesProvider).single;
    expect((kept.toasting, kept.read), (false, true));
    expect(panel.shows("1 failed"), isTrue);
  });

  testWidgets("a toast is heard as soon as it shows", (tester) async {
    await tester.showFailingActions();

    await tester.tapKey(LogicalKeyboardKey.enter);

    final toast = tester
        .getSemantics(find.bySemanticsLabel(RegExp("^$publishFailed")))
        .getSemanticsData();
    expect(toast.flagsCollection.isLiveRegion, isTrue);
  });
}
