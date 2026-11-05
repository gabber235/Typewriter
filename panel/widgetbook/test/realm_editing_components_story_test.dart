import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/authored_type_argument_editor.stories.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/realm_editing_review.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a type argument change is reviewed before it is staged", (
    tester,
  ) async {
    final panel = await tester.pumpStory(authoredTypeArgumentEditorUseCase);

    await panel.tapOn(find.text("Choose a type"));
    await panel.field("Choose Reward").enter("Coins");
    await panel.tapOn(find.text("Coins").last);
    await panel.tapOn(find.text("Review type change"));
    expect(panel.shows("Values cleared: 1"), isTrue);
    await panel.tapOn(find.text("Apply type change"));

    expect(panel.shows("Type arguments staged"), isTrue);
  });

  testWidgets("a preview the Realm rejects names the problem and stages "
      "nothing", (tester) async {
    final panel = await tester.pumpStory(
      authoredTypeArgumentEditorUseCase,
      knobs: {
        "Second argument": "true",
        "First argument chosen": "true",
        "Realm preview": "Rejected",
      },
    );

    await panel.tapOn(find.tooltip("Clear Reward"));
    await panel.tapOn(find.text("Review type change"));

    expect(panel.shows("reward_amount_in_use"), isTrue);
    expect(panel.shows("No type change staged"), isTrue);
  });

  testWidgets("without the Realm the editor explains why it is disabled", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      authoredTypeArgumentEditorUseCase,
      knobs: {"Realm connected": "false"},
    );

    expect(
      panel.shows("Connect to the Realm to change type arguments"),
      isTrue,
    );
    expect(
      find.semantics.byLabel("Choose a type").evaluate().single.isEnabled,
      isFalse,
    );
  });

  testWidgets("a retained rename compares before, working and saved values", (
    tester,
  ) async {
    final panel = await tester.pumpStory(realmEditingReviewUseCase);

    for (final column in ["Before changes", "Working", "Saved"]) {
      expect(panel.shows(column), isTrue, reason: column);
    }
    expect(panel.shows("Main quest"), isTrue);
    expect(panel.shows("Quest"), isTrue);
  });
}
