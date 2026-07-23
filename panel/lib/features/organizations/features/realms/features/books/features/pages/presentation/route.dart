import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/typewriter_panel.dart";

@RoutePage()
class PagePage extends HookConsumerWidget {
  const PagePage({@PathParam("pageId") required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pagesProvider(pageId));
    return Inspector(
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        right: context.spacing.space2,
      ),
      child: Pane(
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
