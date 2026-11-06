import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/features/organizations/presentation/organization_selector.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/presentation/route.stories.dart";
import "package:widgetbook_workspace/stories/features/organizations/search/presentation/primary_search.stories.dart";
import "package:widgetbook_workspace/stories/features/services/presentation/route.stories.dart";

import "support/stories.dart";

const _guild = "The Very Long Named Interactive Storytelling Guild Of Westeros";

void main() {
  testWidgets("choosing an organization on the index page opens it", (
    tester,
  ) async {
    final panel = await tester.pumpStory(indexPageUseCase);

    await tester.tap(find.text("Acme"));

    await tester.eventually(
      () => expect(panel.path, startsWith("/organization/acme")),
    );
    await tester.runStory();
  });

  testWidgets("the organization selector switches to another organization", (
    tester,
  ) async {
    final panel = await tester.pumpStory(organizationSelectorUseCase);

    await tester.tap(find.text("Acme").first);
    await tester.runStory();
    await tester.tap(find.text(_guild).last);

    await tester.eventually(
      () => expect(
        panel.path,
        startsWith(
          "/organization/the_very_long_named_interactive_storytelling_guild_of_westeros",
        ),
      ),
    );
    await tester.runStory();
  });

  testWidgets("the primary search finds organizations and the create command", (
    tester,
  ) async {
    final panel = await tester.pumpStory(primarySearchButtonUseCase);

    await tester.tap(panel.labeled("Search"));
    await tester.runStory();

    await tester.enterText(find.byType(EditableText).last, "westeros");
    await tester.runStory();
    expect(panel.shows(_guild), isTrue);

    await tester.enterText(find.byType(EditableText).last, "create");
    await tester.runStory();
    expect(panel.shows("Create Organization"), isTrue);
  });

  testWidgets("a malformed registration token never reaches the backend", (
    tester,
  ) async {
    final panel = await tester.pumpStory(registrationTokenInputUseCase);

    await panel.field("Enter registration token").enter("short");
    await tester.tap(find.text("Connect"));
    await tester.runStory();

    expect(
      panel.shows("Token must be 10 uppercase alphanumeric characters"),
      isTrue,
    );
    expect(panel.shows("No services connected"), isTrue);
  });

  testWidgets("a valid registration token binds a new service", (tester) async {
    final panel = await tester.pumpStory(registrationTokenInputUseCase);
    expect(panel.shows("No services connected"), isTrue);

    await panel.field("Enter registration token").enter("ABCDE12345");
    await tester.tap(find.text("Connect"));

    await tester.eventually(
      () => expect(panel.shows("No services connected"), isFalse),
    );
    await tester.runStory();
  });

  testWidgets(
    "the organizations page keeps loading while its list has not arrived",
    (tester) async {
      final panel = await tester.pumpStory(
        indexPageUseCase,
        knobs: {"Organizations": "Loading"},
        run: const Duration(seconds: 11),
      );

      expect(panel.shows("Loading Organizations..."), isTrue);
      expect(panel.shows(ErrorScreen.defaultTitle), isFalse);
    },
  );
}
