import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/main.directories.g.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/realm_work_toolbar.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/realm_work_toolbar_story_fixture.dart";

void main() {
  test(
    "catalog exposes all publication variants under Realm toolbar ownership",
    () {
      final cases = directories
          .expand((node) => node.leaves)
          .where(
            (node) => node.nodesPath.any(
              (ancestor) => ancestor.name == "RealmWorkToolbar",
            ),
          )
          .toList();
      expect(
        cases.map((node) => node.name),
        unorderedEquals([
          "Idle with saved Page status",
          "Active publication",
          "Blocked with findings",
          "Interrupted publication",
          "Pending draft and saved publication",
        ]),
      );
      for (final node in cases) {
        expect(node.nodesPath.map((ancestor) => ancestor.name).toList(), [
          "features",
          "organizations",
          "features",
          "realms",
          "presentation",
          "RealmWorkToolbar",
          node.name,
        ]);
      }
    },
  );

  for (final scenario in RealmWorkToolbarScenario.values) {
    testWidgets(
      "publication story renders ${scenario.name} and saved root membership",
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1100, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixture = RealmWorkToolbarStoryFixture(scenario);
        addTearDown(fixture.dispose);
        await tester.pumpWidget(
          RealmWorkToolbarStory(scenario: scenario, fixture: fixture),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RealmWorkToolbar), findsOneWidget);
        final publish = tester.widget<TextButton>(
          find.widgetWithText(TextButton, "Publish saved content"),
        );
        expect(
          publish.onPressed != null,
          scenario != RealmWorkToolbarScenario.active,
        );
        final phase = switch (scenario) {
          RealmWorkToolbarScenario.active => "Compiling saved content",
          RealmWorkToolbarScenario.blocked => "Blocked",
          RealmWorkToolbarScenario.interrupted => "Interrupted",
          _ => "Published",
        };
        expect(find.text(phase), findsOneWidget);
        await tester.tap(find.text("Saved Page publication status (2 Pages)"));
        await tester.pumpAndSettle();
        expect(
          find.text("Welcome: Last published in publication:town"),
          findsOneWidget,
        );
        expect(
          find.text("Market: Not in the selected publication"),
          findsOneWidget,
        );
        if (scenario == RealmWorkToolbarScenario.blocked) {
          await tester.tap(find.text("Publication findings (1)"));
          await tester.pumpAndSettle();
          expect(
            find.text("Market needs a dialogue target before publication"),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    "pending draft story publishes the saved name and applies the rename separately",
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = RealmWorkToolbarStoryFixture(
        RealmWorkToolbarScenario.pendingDraft,
      );
      addTearDown(fixture.dispose);
      await tester.pumpWidget(
        RealmWorkToolbarStory(scenario: fixture.scenario, fixture: fixture),
      );
      await tester.pumpAndSettle();
      expect(find.text("Saved Page name: Welcome"), findsOneWidget);
      expect(
        find.text("Working Page name: Welcome to the town"),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, "Apply"), findsOneWidget);
      await tester.tap(find.text("Publish saved content"));
      await tester.pumpAndSettle();
      expect(fixture.repository.publishedNames, ["Welcome"]);
      expect(fixture.transport.requests, isEmpty);
      expect(fixture.workspace.state.groups, hasLength(1));
      expect(fixture.workingName, "Welcome to the town");
      await tester.tap(find.widgetWithText(TextButton, "Apply"));
      await tester.pumpAndSettle();
      expect(fixture.transport.requests, hasLength(1));
      expect(fixture.savedName, "Welcome to the town");
      expect(fixture.workspace.state.groups, isEmpty);
      expect(fixture.repository.publishedNames, ["Welcome"]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
