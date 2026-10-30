import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/authoring_conflict.stories.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/retained_rename.dart";

import "support/stories.dart";

void main() {
  /// The story once every save elsewhere arrived.
  Future<PanelDriver> pump(
    WidgetTester tester,
    WidgetBuilder story,
    Map<String, String> knobs,
  ) async {
    final panel = await tester.pumpStory(story, knobs: knobs);
    await tester.runStory();
    return panel!;
  }

  Future<PanelDriver> comparison(WidgetTester tester, String saved) =>
      pump(tester, authoringConflictComparisonUseCase, {"Saved Realm": saved});

  skir.DataValue? workingName(PanelDriver panel) =>
      panel.working.resource(questTag.tagId)?.authoredField("name");

  final choices = {"Keep mine": "Main quest", "Use saved": "Side quest"};
  for (final MapEntry(key: choice, value: name) in choices.entries) {
    testWidgets("$choice from the keyboard leaves the quest named $name", (
      tester,
    ) async {
      final panel = await comparison(tester, "Renamed elsewhere");
      expect(panel.shows("Main quest"), isTrue);
      expect(panel.shows("Side quest"), isTrue);

      Focus.of(tester.element(find.text(choice))).requestFocus();
      await panel.settle();
      await panel.press(LogicalKeyboardKey.enter);

      expect(panel.shows(choice), isFalse);
      expect(workingName(panel), skir.DataValue.wrapStringValue(name));
    });
  }

  testWidgets("a second save elsewhere refuses a stale Keep mine", (
    tester,
  ) async {
    final panel = await comparison(tester, "Renamed twice elsewhere");

    await panel.tapOn(find.text("Keep mine"));

    expect(
      panel.shows("These changes changed again. Review the current values"),
      isTrue,
    );
    expect(workingName(panel), skir.DataValue.wrapStringValue("Main quest"));
    expect(panel.world.requireRealm.saves, isEmpty);
  });

  testWidgets("a quest removed elsewhere can only take the saved state", (
    tester,
  ) async {
    final panel = await comparison(tester, "Removed elsewhere");
    expect(
      find.semantics.byLabel("Keep mine").evaluate().single.isEnabled,
      isFalse,
    );

    await panel.tapOn(find.text("Use saved"));

    expect(panel.shows("Use saved"), isFalse);
    expect(panel.working.resource(questTag.tagId), isNull);
  });

  testWidgets("a name cleared elsewhere compares as Unfilled", (tester) async {
    final panel = await comparison(tester, "Name cleared elsewhere");

    expect(panel.shows("Unfilled"), isTrue);
    expect(panel.shows("Main quest"), isTrue);
  });

  testWidgets("unreadable saved values keep the retained edits", (
    tester,
  ) async {
    final panel = await pump(tester, authoringConflictNoticeUseCase, {
      "Saved Realm": "Renamed elsewhere",
      "Saved values": "Unreadable",
    });

    await panel.tapOn(find.text("Review changes"));

    expect(
      panel.shows(
        "Current saved values are unavailable. Your edits are retained.",
      ),
      isTrue,
    );
    expect(panel.shows("Keep mine"), isFalse);
  });
}
