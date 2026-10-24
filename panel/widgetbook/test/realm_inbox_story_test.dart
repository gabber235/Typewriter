import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_inbox.stories.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_inbox_story_fixture.dart";

void main() {
  for (final scenario in RealmInboxScenario.values) {
    testWidgets("realm inbox renders ${scenario.name}", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        RealmInboxStory(scenario: scenario, inline: true, reducedMotion: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RealmInboxView), findsOneWidget);
      if (scenario == RealmInboxScenario.largeReview) {
        await tester.scrollUntilVisible(
          find.text("Publish"),
          400,
          scrollable: find.descendant(
            of: find.byType(RealmInboxView),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(
        find.text("Publish"),
        scenario == RealmInboxScenario.ready ||
                scenario == RealmInboxScenario.warnings ||
                scenario == RealmInboxScenario.largeReview ||
                scenario == RealmInboxScenario.localDraft
            ? findsOneWidget
            : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets("a live blocker removes Publish and resolution restores it", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = RealmInboxStoryFixture(RealmInboxScenario.ready);
    addTearDown(fixture.dispose);
    await tester.pumpWidget(
      RealmInboxStory(fixture: fixture, inline: true, reducedMotion: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Introduce issue"));
    await tester.pumpAndSettle();
    expect(find.text("Publish"), findsNothing);
    expect(find.text("Publish blocked"), findsOneWidget);
    await tester.tap(find.text("Resolve issue"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Publish"));
    await tester.pumpAndSettle();
    expect(fixture.published, 1);
    expect(find.text("Everything is published"), findsOneWidget);
  });

  testWidgets(
    "the real app bar opens by keyboard and popup dismissal removes its Publish registration",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const RealmInboxStory(reducedMotion: true));
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text("Review changes"))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.byType(RealmInboxView), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(RealmInboxView)),
      );
      expect(
        container
            .read(actionShortcutsProvider)
            .containsKey("realm_inbox_publish"),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(RealmInboxView), findsNothing);
      expect(
        container
            .read(actionShortcutsProvider)
            .containsKey("realm_inbox_publish"),
        isFalse,
      );
    },
  );
}
