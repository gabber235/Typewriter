import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class PagePage extends ConsumerWidget {
  const PagePage({@PathParam("pageId") required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    Widget child;
    if (organizationId == null || realmId == null) {
      child = const Center(child: Text("Select a Realm to edit this page"));
    } else {
      final scope = AuthoringScope(
        organizationId: organizationId,
        realmId: realmId,
      );
      final source = ref.watch(workingAuthoringDocumentProvider(scope));
      final resource = skir.ResourceId(value: pageId);
      final document = source.value;
      if (source.error case final failure?) {
        child = Center(child: Text("Page authoring is unavailable: $failure"));
      } else if (document == null) {
        child = const Center(child: CircularProgressIndicator());
      } else if (document.resource(resource) == null) {
        child = const Center(child: Text("This page is no longer available"));
      } else {
        child = AuthoredResourceInspection(
          key: ValueKey((resource, skir.PresentationRole.editor)),
          resource: resource,
          workspace: ref.watch(authoringWorkspaceProvider(scope)),
          commands: ref.watch(authoredResourceCommandsProvider(scope)),
          role: skir.PresentationRole.editor,
          openResource: (selected) {
            ref
                .read(selectionProvider.notifier)
                .select(
                  AuthoringResourceIdentifier(
                    organizationId: organizationId,
                    realmId: realmId,
                    resourceId: selected,
                  ),
                );
          },
        );
      }
    }
    return Pane(
      id: "pagepage",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.all(context.spacing.space2),
      child: Material(child: child),
    );
  }
}
