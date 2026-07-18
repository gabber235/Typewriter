import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shell/panes.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/application/pages.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/domain/page_type_extensions.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/entry_graph.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/inspector.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/scene/presentation/scene.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/shared/ui/components/section.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

@RoutePage()
class PagePage extends HookConsumerWidget {
  const PagePage({@PathParam("pageId") required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pagesProvider(pageId));
    return Inspector(
      margin: EdgeInsets.only(top: 8, right: 8),
      child: Pane(
        id: "pagepage",
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.only(
          top: 8,
          left: 8,
          right: context.isMobile ? 8 : 0,
        ),
        child: Section(
          margin: EdgeInsets.zero,
          child: page(
            name: "page",
            builder: (page) {
              return switch (page.type) {
                PageType.PAGE_TYPE_STATIC ||
                PageType.PAGE_TYPE_SEQUENCE ||
                PageType.PAGE_TYPE_MANIFEST => EntryGraph(
                  pageId: pageId,
                  graphDirection: page.type.direction!,
                ),
                PageType.PAGE_TYPE_SCENE => EntryScene(pageId: pageId),
                _ => Text("Unknown page type"),
              };
            },
          ),
        ),
      ),
    );
  }
}
