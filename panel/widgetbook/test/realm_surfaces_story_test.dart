import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/realm_showcase_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_resources_layouts.stories.dart";

import "support/network_images.dart";

void main() {
  for (final (name, routed) in [
    ("page", fixtureShowcasePage),
    ("Book", fixtureShowcaseBook),
    ("Library", fixtureLibraryId),
    ("tags", fixtureTaxonomyId),
  ]) {
    testWidgetsWithNetworkImages("the $name route story renders its surface", (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        RealmShowcaseStory(
          routed: routed,
          child: Scaffold(
            body: ResourceSurface(scope: realmShowcaseScope, resource: routed),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResourceHeading), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgetsWithNetworkImages("the sidebar and breadcrumb stories render", (
    tester,
  ) async {
    await tester.pumpWidget(
      RealmShowcaseStory(
        routed: fixtureShowcasePage,
        child: Scaffold(
          body: Column(
            children: [
              const ResourceBreadcrumbs(),
              SizedBox(
                width: 260,
                child: RealmSectionsNavigator(scope: realmShowcaseScope),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResourceCrumbSelector), findsNWidgets(3));
    expect(find.byType(ResourceItemChrome), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  for (final (layout, resource, role) in [
    ("grid", fixtureLibraryId, skir.PresentationRole.workspace),
    ("list", fixtureRealmRootId, skir.PresentationRole.navigator),
    ("tree", fixtureShowcaseBook, skir.PresentationRole.navigator),
  ]) {
    testWidgetsWithNetworkImages("the $layout layout story renders members", (
      tester,
    ) async {
      await tester.pumpWidget(
        ResourcesLayoutStory(resource: resource, role: role),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResourceItemChrome), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
