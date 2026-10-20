import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Grid layout", type: PortableResourcesHost)
Widget resourcesGridUseCase(BuildContext context) => ResourcesLayoutStory(
  resource: fixtureLibraryId,
  role: skir.PresentationRole.workspace,
  routed: context.knobs.boolean(label: "Atlas is routed")
      ? skir.ResourceId(value: "book:showcase:atlas")
      : null,
);

@widgetbook.UseCase(name: "List layout", type: PortableResourcesHost)
Widget resourcesListUseCase(BuildContext context) => ResourcesLayoutStory(
  resource: fixtureRealmRootId,
  role: skir.PresentationRole.navigator,
  routed: context.knobs.boolean(label: "Library is routed", initialValue: true)
      ? fixtureLibraryId
      : null,
);

@widgetbook.UseCase(name: "Tree layout", type: PortableResourcesHost)
Widget resourcesTreeUseCase(BuildContext context) => ResourcesLayoutStory(
  resource: fixtureShowcaseBook,
  role: skir.PresentationRole.navigator,
  routed: context.knobs.boolean(label: "Arrival is routed", initialValue: true)
      ? fixtureShowcasePage
      : null,
);

/// Renders the [role] presentation of [resource] from the showcase realm.
class ResourcesLayoutStory extends StatelessWidget {
  const ResourcesLayoutStory({
    required this.resource,
    required this.role,
    this.routed,
    super.key,
  });

  final skir.ResourceId resource;
  final skir.PresentationRole role;
  final skir.ResourceId? routed;

  @override
  Widget build(BuildContext context) => AuthoringFixtureApp(
    createDocument: fixtureRealmShowcase,
    child: Scaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final scope = ref.watch(selectedAuthoringScopeProvider)!;
          final document = ref.watch(realmEditingProvider(scope)).document;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AuthoredResourceEditor(
              resource: resource,
              document: document,
              role: role,
              routedResource: routed,
              budget: skir.EvaluationBudget(
                maxSteps: 10000,
                maxCollectionItems: 1000,
              ),
              fillAvailableSpace: role == skir.PresentationRole.workspace,
            ),
          );
        },
      ),
    ),
  );
}
