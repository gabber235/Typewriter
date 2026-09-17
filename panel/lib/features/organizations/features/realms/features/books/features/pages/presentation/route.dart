import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Displays one page using the editor selected by its catalog definition.
///
/// The route observes projected metadata so unsaved names and chapters remain
/// visible, then consults the active realm catalog for the page kind. A missing
/// definition is rendered as read only because choosing an editor without its
/// contract would risk interpreting page content incorrectly.
@RoutePage()
class PagePage extends HookConsumerWidget {
  const PagePage({@PathParam("pageId") required this.pageId, super.key});

  final String pageId;

  /// Builds a page surface or a safe read only fallback when its kind is absent.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(projectedPageProvider(recordId("page:$pageId")));
    return Pane(
      id: "pagepage",
      primary: true,
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: page(
          name: "page",
          builder: (page) {
            final definition = ref
                .watch(realmEditorCatalogProvider)
                .value
                ?.snapshot
                ?.pageCatalog
                .definitions[page.kind];
            if (definition == null) {
              return const ErrorScreen(
                title: "Page Kind Unavailable",
                message: "This page kind is unavailable. Likely because the extension which provides it failed to load or was removed.",
              );
            }
            return switch (definition.editor) {
              RealmGraphPageEditor(:final direction) => EntryGraph(
                pageId: pageId,
                graphDirection: direction,
              ),
              RealmTimelinePageEditor() => EntryTimelineEditor(pageId: pageId),
            };
          },
        ),
      ),
    );
  }
}
