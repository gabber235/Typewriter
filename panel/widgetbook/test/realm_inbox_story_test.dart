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
        final panel = (await tester.pumpStory(
          realmInboxContentUseCase,
          knobs: {"Review": review},
        ))!;

        expect(panel.labeled("Publish"), publishes ? findsOne : findsNothing);
        await tester.runStory();
      },
    );
  }

  testWidgets("a large review offers Publish below its changes", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(
      realmInboxContentUseCase,
      knobs: {"Review": "Large review"},
    ))!;

    await tester.scrollUntilVisible(
      find.text("Publish"),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.runStory();

    expect(panel.labeled("Publish"), findsOne);
  });

  testWidgets("a blocked review names the blocker", (tester) async {
    final panel = (await tester.pumpStory(
      realmInboxContentUseCase,
      knobs: {"Review": "Blocked"},
    ))!;

    expect(panel.shows("Publish blocked"), isTrue);
    expect(panel.shows("Dialogue points to a missing page"), isTrue);
    await tester.runStory();
  });

  testWidgets("publishing a ready review publishes everything", (tester) async {
    final panel = (await tester.pumpStory(realmInboxContentUseCase))!;

    await tester.tap(panel.labeled("Publish"));

    await tester.eventually(
      () => expect(panel.shows("Everything is published"), isTrue),
    );
    await tester.runStory();
  });

  testWidgets("the app bar inbox opens by keyboard and publishes nothing "
      "once dismissed", (tester) async {
    final panel = (await tester.pumpStory(realmInboxButtonUseCase))!;

    await _shifted(tester, LogicalKeyboardKey.keyP);
    expect(panel.labeled("Publish"), findsOne);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.runStory();
    expect(panel.labeled("Publish"), findsNothing);

    await _primary(tester, LogicalKeyboardKey.enter);
    await _shifted(tester, LogicalKeyboardKey.keyP);
    expect(panel.shows("Everything is published"), isFalse);
    expect(panel.labeled("Publish"), findsOne);
  });

  testWidgets("outside a Realm the app bar has no Realm inbox", (tester) async {
    final panel = (await tester.pumpStory(
      realmInboxButtonUseCase,
      knobs: {"Review": "No realm open"},
    ))!;

    await _shifted(tester, LogicalKeyboardKey.keyP);

    expect(panel.shows("Realm inbox"), isFalse);
    expect(panel.labeled("Publish"), findsNothing);
  });
}

/// Presses [key] with Shift held and lets the story run; the driver's own
/// keys wait for animations a story never finishes.
Future<void> _shifted(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.runStory();
}

/// Presses [key] with the platform's primary modifier and lets the story run.
Future<void> _primary(WidgetTester tester, LogicalKeyboardKey key) async {
  final modifier = switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.iOS => LogicalKeyboardKey.metaLeft,
    _ => LogicalKeyboardKey.controlLeft,
  };
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.runStory();
}
