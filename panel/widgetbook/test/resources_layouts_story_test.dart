import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/resource_route.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("the Library lays out every Book of the Realm", (tester) async {
    final panel = await tester.pumpStory(
      resourceSurfaceUseCase,
      knobs: {"Routed resource": "Library"},
    );

    expect(panel.shows("The Lost Village"), isTrue);
    expect(panel.shows("Atlas of Echoes"), isTrue);
  });

  testWidgets("a routed page lists the pages of its Book", (tester) async {
    final panel = await tester.pumpStory(
      resourceSurfaceUseCase,
      knobs: {"Routed resource": "Page"},
    );

    for (final page in ["Prologue", "Arrival", "Market", "Finale"]) {
      expect(panel.shows(page), isTrue, reason: page);
    }
  });

  testWidgets("a Book of the Library is selected when clicked", (tester) async {
    final panel = await tester.pumpStory(
      resourceSurfaceUseCase,
      knobs: {"Routed resource": "Library"},
    );
    await panel.tapOn(find.text("The Lost Village").first);

    expect(panel.resources.selected, [showcaseBook.bookId]);
  });

  testWidgets("a Book of the Library is reached with Tab and selected with "
      "Enter", (tester) async {
    final panel = await tester.pumpStory(
      resourceSurfaceUseCase,
      knobs: {"Routed resource": "Library"},
    );

    await panel.tabTo("The Lost Village", limit: 30);
    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.resources.selected, [showcaseBook.bookId]);
  });
}
