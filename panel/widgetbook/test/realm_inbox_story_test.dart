import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_inbox.stories.dart";

import "support/stories.dart";

void main() {
  for (final (review, publishes) in [
    ("Ready", true),
    ("Warnings", true),
    ("Blocked", false),
    ("Everything published", false),
    ("Unavailable", false),
  ]) {
    testWidgets(
      "a $review review ${publishes ? "offers" : "withholds"} Publish",
      (tester) async {
        final panel = await tester.pumpStory(
          realmInboxContentUseCase,
          knobs: {"Review": review},
        );

        expect(panel.labeled("Publish"), publishes ? findsOne : findsNothing);
        await tester.runStory();
      },
    );
  }

  testWidgets("a large review offers Publish below its changes", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      realmInboxContentUseCase,
      knobs: {"Review": "Large review"},
    );

    await tester.scrollUntilVisible(
      find.text("Publish"),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.runStory();

    expect(panel.labeled("Publish"), findsOne);
  });

  testWidgets("a blocked review names the blocker", (tester) async {
    final panel = await tester.pumpStory(
      realmInboxContentUseCase,
      knobs: {"Review": "Blocked"},
    );

    expect(panel.shows("Publish blocked"), isTrue);
    expect(panel.shows("Dialogue points to a missing page"), isTrue);
    await tester.runStory();
  });

  testWidgets("publishing a ready review publishes everything", (tester) async {
    final panel = await tester.pumpStory(realmInboxContentUseCase);

    await tester.tap(panel.labeled("Publish"));

    await tester.eventually(
      () => expect(panel.shows("Everything is published"), isTrue),
    );
    await tester.runStory();
  });

  testWidgets("the app bar inbox opens by keyboard and publishes nothing "
      "once dismissed", (tester) async {
    final panel = await tester.pumpStory(realmInboxButtonUseCase);

    await tester.pressInStory(LogicalKeyboardKey.keyP, shift: true);
    // The open inbox offers Publish twice: in its review and as its chip in
    // the action row.
    expect(semanticsButtons("Publish"), hasLength(2));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.runStory();
    expect(semanticsButtons("Publish"), isEmpty);

    await tester.pressInStory(LogicalKeyboardKey.enter, primary: true);
    await tester.pressInStory(LogicalKeyboardKey.keyP, shift: true);
    expect(panel.shows("Everything is published"), isFalse);
    expect(semanticsButtons("Publish"), hasLength(2));
  });

  testWidgets("outside a Realm the app bar has no Realm inbox", (tester) async {
    final panel = await tester.pumpStory(
      realmInboxButtonUseCase,
      knobs: {"Review": "No realm open"},
    );

    await tester.pressInStory(LogicalKeyboardKey.keyP, shift: true);

    expect(panel.shows("Realm inbox"), isFalse);
    expect(panel.labeled("Publish"), findsNothing);
  });
}
