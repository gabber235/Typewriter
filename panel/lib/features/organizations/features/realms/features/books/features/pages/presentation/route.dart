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
      final provider = authoringSessionProvider(organizationId, realmId);
      final state = ref.watch(provider);
      final resource = skir.ResourceId(value: pageId);
      final draft = state.draft;
      final catalog = state.catalog;
      if (state.failure case final failure?) {
        child = Center(child: Text("Page authoring is unavailable: $failure"));
      } else if (draft == null || catalog == null) {
        child = const Center(child: CircularProgressIndicator());
      } else if (draft.resource(resource) == null) {
        child = const Center(child: Text("This page is no longer available"));
      } else {
        child = AuthoredResourceInspection(
          key: ValueKey((resource, skir.PresentationRole.editor)),
          resource: resource,
          draft: draft,
          catalog: catalog,
          commands: AuthoredResourceCommands(
            commit: ref.read(provider.notifier).commit,
            previewTypeArguments: ref
                .read(provider.notifier)
                .previewTypeArguments,
            commitTypeArguments: ref
                .read(provider.notifier)
                .commitTypeArguments,
            prepareCreation: ref.read(provider.notifier).prepareCreation,
            invokeCommand: ref.read(provider.notifier).invokeCommand,
            watchSearch: ref.read(provider.notifier).watchPresentationSearch,
            reload: ref.read(provider.notifier).refresh,
            openAutosave: ref.read(provider.notifier).openAutosave,
          ),
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
