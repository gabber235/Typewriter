import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

/// The scope of the showcase realm stories.
final realmShowcaseScope = AuthoringScope(
  organizationId: skir.recordId("organization:showcase"),
  realmId: skir.recordId("realm:showcase"),
);

@widgetbook.UseCase(name: "Routed resource", type: ResourceSurface)
Widget resourceSurfaceUseCase(BuildContext context) {
  final routed = context.knobs.object.dropdown<String>(
    label: "Routed resource",
    options: const ["Page", "Book", "Library", "Tags"],
    initialOption: "Page",
  );
  final resource = switch (routed) {
    "Book" => fixtureShowcaseBook,
    "Library" => fixtureLibraryId,
    "Tags" => fixtureTaxonomyId,
    _ => fixtureShowcasePage,
  };
  return RealmShowcaseStory(
    routed: resource,
    child: Scaffold(
      body: ResourceSurface(scope: realmShowcaseScope, resource: resource),
    ),
  );
}

@widgetbook.UseCase(name: "Realm sections", type: RealmSectionsNavigator)
Widget realmSectionsNavigatorUseCase(BuildContext context) {
  final routed = context.knobs.object.dropdown<String>(
    label: "Routed section",
    options: const ["Library", "Tags"],
    initialOption: "Library",
  );
  return RealmShowcaseStory(
    routed: routed == "Tags" ? fixtureTaxonomyId : fixtureLibraryId,
    child: Scaffold(
      body: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: RealmSectionsNavigator(scope: realmShowcaseScope),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Owner chain", type: ResourceBreadcrumbs)
Widget resourceBreadcrumbsUseCase(BuildContext context) => RealmShowcaseStory(
  routed: fixtureShowcasePage,
  child: const Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: EdgeInsets.all(16), child: ResourceBreadcrumbs()),
    ),
  ),
);

/// Opens the showcase realm with [routed] as the routed resource.
class RealmShowcaseStory extends StatelessWidget {
  const RealmShowcaseStory({
    required this.routed,
    required this.child,
    super.key,
  });

  final skir.ResourceId routed;
  final Widget child;

  @override
  Widget build(BuildContext context) => AuthoringFixtureApp(
    scenario: routed,
    createDocument: fixtureRealmShowcase,
    overrides: [
      organizationIdProvider.overrideWithValue(
        realmShowcaseScope.organizationId,
      ),
      realmIdProvider.overrideWithValue(realmShowcaseScope.realmId),
      routedResourceIdProvider.overrideWithValue(routed),
    ],
    child: child,
  );
}
