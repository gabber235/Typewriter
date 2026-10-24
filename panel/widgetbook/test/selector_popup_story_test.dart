import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/selector_popup.stories.dart";

void main() {
  for (final withSelection in [false, true]) {
    testWidgets(
      "selector searches sections and selects (tracked $withSelection)",
      (tester) async {
        await tester.pumpWidget(
          SelectorPopupStory(withSelection: withSelection),
        );
        await tester.pumpAndSettle();
        expect(find.text("Selected book: The lost lantern"), findsOneWidget);

        await tester.tap(find.text("The lost lantern"));
        await tester.pumpAndSettle();
        expect(find.text("MAIN STORY"), findsOneWidget);
        expect(find.text("SIDE QUESTS"), findsOneWidget);

        final query = find.descendant(
          of: find.byType(SelectorSearchField),
          matching: find.byType(TextField),
        );
        await tester.enterText(query, "merchant");
        await tester.pumpAndSettle();
        expect(find.text("MAIN STORY"), findsNothing);
        expect(find.text("Fishing contest"), findsNothing);

        await tester.tap(find.text("The wandering merchant"));
        await tester.pumpAndSettle();
        expect(find.byType(SelectorSearchField), findsNothing);
        expect(
          find.text("Selected book: The wandering merchant"),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets("selector opens from the keyboard", (tester) async {
    await tester.pumpWidget(const SelectorPopupStory());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(SelectorSearchField), findsOneWidget);
    expect(find.text("MAIN STORY"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("selector search reports no matches", (tester) async {
    await tester.pumpWidget(const SelectorPopupStory());
    await tester.pumpAndSettle();
    await tester.tap(find.text("The lost lantern"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(SelectorSearchField),
        matching: find.byType(TextField),
      ),
      "dragon",
    );
    await tester.pumpAndSettle();
    expect(find.text("No books match"), findsOneWidget);
  });

  testWidgets("selector keeps loading and failure at its boundary", (
    tester,
  ) async {
    await tester.pumpWidget(
      const SelectorPopupStory(state: SelectorStoryState.failed),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining("did not return its books"), findsOneWidget);
    expect(find.text("The lost lantern"), findsNothing);

    await tester.pumpWidget(
      const SelectorPopupStory(state: SelectorStoryState.loading),
    );
    await tester.pump();
    expect(find.text("The lost lantern"), findsNothing);
  });
}
