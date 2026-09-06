import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class PagePage extends HookConsumerWidget {
  const PagePage({@PathParam("pageId") required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pagesProvider(recordId("page:$pageId")));
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
              return const Center(
                child: Text(
                  "This page kind is unavailable. The page is read only.",
                ),
              );
            }
            return switch (definition.editor) {
              RealmGraphPageEditor(:final direction) => EntryGraph(
                pageId: pageId,
                graphDirection: direction,
              ),
              RealmTimelinePageEditor() => EntryScene(pageId: pageId),
            };
          },
        ),
      ),
    );
  }
}
