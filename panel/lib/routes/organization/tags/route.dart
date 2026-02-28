import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/graph/tag_graph.dart";
import "package:typewriter_panel/widgets/app/components/inspector/inspector.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/page_heading.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";

@RoutePage()
class TagsPage extends HookConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Inspector(
      margin: EdgeInsets.only(top: 8, right: 8),
      child: Pane(
        id: "tags",
        borderRadius: BorderRadius.circular(12),
        margin: EdgeInsets.only(
          top: 8,
          left: 8,
          right: context.isMobile ? 8 : 0,
        ),
        child: Section(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                title: "Tags",
                subtext:
                    "Manage and organize your tags. View the hierarchy and parent relationships between tags.",
              ),
              Expanded(child: TagGraph()),
            ],
          ),
        ),
      ),
    );
  }
}
