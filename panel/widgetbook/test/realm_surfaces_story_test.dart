import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/resource_breadcrumbs.stories.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/resource_navigator.stories.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/resource_route.stories.dart";

import "support/stories.dart";

void main() {
  for (final (routed, resource, title) in [
    ("Page", "page:arrival", "Arrival"),
    ("Book", "book:the_lost_village", "The Lost Village"),
    ("Library", "library:library", "library"),
    ("Tags", "library:taxonomy", "taxonomy"),
  ]) {
    testWidgets("the routed $routed opens at its own route under its title", (
      tester,
    ) async {
      final panel = await tester.pumpStory(
        resourceSurfaceUseCase,
        knobs: {"Routed resource": routed},
      );

      expect(panel.path, endsWith("/resource/$resource"));
      expect(panel.shows(title), isTrue);
      await tester.runStory();
    });
  }

  testWidgets("a resource removed elsewhere says it is gone", (tester) async {
    final panel = await tester.pumpStory(
      resourceSurfaceUseCase,
      knobs: {"Routed resource": "Removed elsewhere"},
    );

    expect(panel.shows("This resource is no longer available"), isTrue);
    await tester.runStory();
  });

  testWidgets("the breadcrumbs follow the owner chain of the page", (
    tester,
  ) async {
    await tester.pumpStory(resourceBreadcrumbsUseCase);

    final crumbs = [
      "library",
      "The Lost Village",
      "Arrival",
    ].map((crumb) => tester.getTopLeft(find.text(crumb).first).dx).toList();
    expect(crumbs, orderedEquals([...crumbs]..sort()));
    await tester.runStory();
  });

  testWidgets("choosing a section in the navigator opens it", (tester) async {
    final panel = await tester.pumpStory(realmSectionsNavigatorUseCase);

    await tester.tap(find.text("taxonomy"));

    await tester.eventually(
      () => expect(panel.path, endsWith("/resource/library:taxonomy")),
    );
    await tester.runStory();
  });

  testWidgets("choosing a page of the book opens it", (tester) async {
    final panel = await tester.pumpStory(resourceSurfaceUseCase);

    await tester.tap(find.text("Market"));

    await tester.eventually(
      () => expect(panel.path, endsWith("/resource/page:market")),
    );
    await tester.runStory();
  });
}
