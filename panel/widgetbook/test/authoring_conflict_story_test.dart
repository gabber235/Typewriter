import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authoring_conflict.stories.dart";

void main() {
  for (final keepMine in [false, true]) {
    testWidgets("whole group recovery keeps mine $keepMine", (tester) async {
      await tester.pumpWidget(
        authoringConflictStory(comparison: true, width: 360),
      );
      await tester.pumpAndSettle();
      expect(find.text("Quest"), findsWidgets);
      expect(find.text("Main quest"), findsWidgets);
      expect(find.text("Side quest"), findsWidgets);
      final action = find.text(keepMine ? "Keep mine" : "Use saved");
      await tester.ensureVisible(action);
      Focus.of(tester.element(action)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(AuthoringConflictComparison), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets("changed saved facts reject stale confirmation", (tester) async {
    await tester.pumpWidget(
      authoringConflictStory(comparison: true, stale: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Keep mine"));
    await tester.pumpAndSettle();
    expect(
      find.text("These changes changed again. Review the current values"),
      findsOneWidget,
    );
    expect(find.text("Main quest"), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets("missing resource blocks Keep mine and permits Use saved", (
    tester,
  ) async {
    await tester.pumpWidget(
      authoringConflictStory(comparison: true, removed: true),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text("Use saved"));
    await tester.pumpAndSettle();
    expect(find.text("Changes are settled"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets("failed observation retains the review notice", (tester) async {
    await tester.pumpWidget(
      authoringConflictStory(comparison: false, unavailable: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Review changes"));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Current saved values are unavailable. Your edits are retained.",
      ),
      findsWidgets,
    );
    expect(find.byType(AuthoringConflictComparison), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final relations in [false, true]) {
    testWidgets("comparison renders Unfilled and relations $relations", (
      tester,
    ) async {
      await tester.pumpWidget(
        authoringConflictStory(
          comparison: true,
          unfilled: true,
          connections: relations,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Unfilled"), findsWidgets);
      if (relations) {
        expect(find.textContaining("tag:location"), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
