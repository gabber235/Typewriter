import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/authored_type_argument_editor.stories.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/realm_editing_review.stories.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/resource_drop_target.stories.dart";

void main() {
  Future<void> choose(WidgetTester tester, String label) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(QueryBar),
        matching: find.byType(EditableText),
      ),
      label,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SearchResultCard),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("type arguments are reviewed before they are staged", (
    tester,
  ) async {
    await tester.pumpWidget(const AuthoredTypeArgumentEditorStory());
    await tester.pumpAndSettle();
    expect(find.textContaining("independent fields remain editable"), findsOne);

    await tester.tap(find.text("Choose a type"));
    await tester.pumpAndSettle();
    await choose(tester, "Coins");
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();
    expect(find.text("Values cleared: 1"), findsOne);

    await tester.tap(find.widgetWithText(FilledButton, "Apply type change"));
    await tester.pumpAndSettle();
    expect(find.text("Type arguments staged"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("rejected type previews stay visible in the editor", (
    tester,
  ) async {
    await tester.pumpWidget(
      const AuthoredTypeArgumentEditorStory(
        chosen: true,
        twoArguments: true,
        outcome: TypePreviewOutcome.rejected,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Clear Reward"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Review type change"));
    await tester.pumpAndSettle();
    expect(find.text("reward_amount_in_use"), findsOneWidget);
    expect(find.text("No type change staged"), findsOneWidget);
  });

  testWidgets("disabled type argument editor explains why", (tester) async {
    await tester.pumpWidget(
      const AuthoredTypeArgumentEditorStory(enabled: false),
    );
    await tester.pumpAndSettle();
    expect(
      find.text("Connect to the Realm to change type arguments"),
      findsOneWidget,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, "Choose a type"),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets("unsaved review compares before, working and saved values", (
    tester,
  ) async {
    await tester.pumpWidget(const RealmEditingReviewStory());
    await tester.pumpAndSettle();
    expect(find.text("Before changes"), findsOneWidget);
    expect(find.text("Working"), findsOneWidget);
    expect(find.text("Saved"), findsOneWidget);
    expect(find.text("Main quest"), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a saved rename elsewhere is resolved from the review", (
    tester,
  ) async {
    await tester.pumpWidget(
      const RealmEditingReviewStory(state: RealmReviewState.savedChanged),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AuthoringConflictComparison), findsOneWidget);
    expect(find.text("Side quest"), findsWidgets);

    await tester.tap(find.text("Use saved"));
    await tester.pumpAndSettle();
    expect(find.text("Changes are settled"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a resource removed elsewhere only offers the saved state", (
    tester,
  ) async {
    await tester.pumpWidget(
      const RealmEditingReviewStory(state: RealmReviewState.removedElsewhere),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text("Use saved"));
    await tester.pumpAndSettle();
    expect(find.text("Changes are settled"), findsOneWidget);
  });

  testWidgets("a disabled page drop target ignores dragged entries", (
    tester,
  ) async {
    await tester.pumpWidget(resourceDropTargetExample(dropEnabled: false));
    await tester.pumpAndSettle();
    final source = tester.getCenter(find.byType(AuthoredGraphItem).first);
    final pageTarget = find.ancestor(
      of: find.byKey(const ValueKey("story.destination")),
      matching: find.byType(ResourceDropHighlight),
    );
    final container = ProviderScope.containerOf(tester.element(pageTarget));
    final scope = container.read(selectedAuthoringScopeProvider)!;
    final workspace = container.read(realmEditingProvider(scope));

    final gesture = await tester.startGesture(source);
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(pageTarget));
    await tester.pumpAndSettle();
    final frame = find.descendant(
      of: pageTarget,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.position == DecorationPosition.foreground,
      ),
    );
    expect(
      (tester.widget<DecoratedBox>(frame).decoration as BoxDecoration).border,
      isNot(
        Border.all(
          width: 2,
          color: Theme.of(tester.element(pageTarget)).colorScheme.primary,
        ),
      ),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      workspace.document.relations.children[compiledEntryDestinationId] ??
          const {},
      isNot(contains(compiledEntryFirstId)),
    );
    expect(tester.takeException(), isNull);
  });
}
