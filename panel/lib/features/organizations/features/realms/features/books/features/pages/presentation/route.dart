import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_theme_access.dart";
import "package:typewriter_panel/features/organizations/application/application.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authoring_selectable_resource.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authoring_session.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/realm.dart";
import "package:typewriter_panel/features/organizations/features/realms/presentation/authored_resource_inspection.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/shared/selectables/selectables.dart";

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
      final resource = types.ResourceId(value: pageId);
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
          key: ValueKey((resource, catalog_wire.PresentationRole.editor)),
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
          role: catalog_wire.PresentationRole.editor,
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
