import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/features/members/join_codes/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/features/members/join_requests/presentation/route.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("generating a join code in the story adds it to the page", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      joinCodesPageUseCase,
      knobs: {"Join codes": "None"},
    );
    expect(panel.shows("No active join codes"), isTrue);

    await tester.tap(find.text("Generate Join Code"));

    await tester.eventually(
      () => expect(panel.shows("No active join codes"), isFalse),
    );
    await tester.runStory();
  });

  testWidgets("a failing membership service shows the join codes failure", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      joinCodesPageUseCase,
      knobs: {"Join codes": "Failing"},
    );

    expect(panel.shows("No active join codes"), isFalse);
    expect(
      panel.shows(
        "Something went wrong, please report this to the Typewriter discord.",
      ),
      isTrue,
    );
  });

  testWidgets("declining a join request in the story removes it", (
    tester,
  ) async {
    const name = "Bartholomew Montgomery Fitzgerald Worthington the Third";
    final panel = await tester.pumpStory(
      joinRequestsPageUseCase,
      knobs: {"Join requests": "Few"},
    );
    expect(panel.shows(name), isTrue);

    final requests = find.text("Decline").evaluate().length;
    await panel.holdButton("Decline $name");

    await tester.eventually(
      () => expect(find.text("Decline"), findsNWidgets(requests - 1)),
    );
    expect(panel.shows(name), isFalse);
    await tester.runStory();
  });
}
