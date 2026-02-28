import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/graph/edge_side.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_edge.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/app/components/tags/tag_node.dart";
import "package:typewriter_panel/widgets/generic/components/empty_screen.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";

const tagGraphCellSize = 50.0;

class TagGraph extends HookConsumerWidget {
  const TagGraph({super.key});

  GraphElement _elementFromTag(Tag tag) {
    return GraphElement(
      id: GraphIdentifier(tag.id),
      x: tag.placement.x,
      y: tag.placement.y,
      width: tag.placement.width.clamp(2, 20),
      height: tag.placement.height.clamp(1, 10),
      builder: (context) => SizedBox.expand(child: TagNode(tagId: tag.id)),
    );
  }

  List<GraphEdge> _edgesFromTags(List<Tag> tags) {
    final edges = <GraphEdge>[];
    final tagMap = {for (final tag in tags) tag.id: tag};

    for (final tag in tags) {
      for (final parent in tag.parents) {
        final parentTag = tagMap[parent.id];
        if (parentTag == null) continue;

        edges.add(
          GraphEdge(
            id: "${parent.id}-${tag.id}",
            source: GraphIdentifier(parent.id),
            target: GraphIdentifier(tag.id),
            color: parentTag.color.value != 0
                ? Color(parentTag.color.value)
                : Colors.grey,
            sourceSide: EdgeSide.bottom,
            targetSide: EdgeSide.top,
          ),
        );
      }
    }

    return edges;
  }

  GraphData _graphFromTags(List<Tag> tags) {
    final elements = tags.map(_elementFromTag).toList();
    final edges = _edgesFromTags(tags);

    return GraphData(
      cellSize: tagGraphCellSize,
      elements: elements,
      edges: edges,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);

    return tags(
      name: "tags",
      builder: (tagList) {
        if (tagList.isEmpty) {
          return EmptyTagsPage(
            onCreateTag: () =>
                ref.read(tagsProvider.notifier).createTag(name: "New Tag"),
          );
        }

        return Graph(
          data: _graphFromTags(tagList),
          onElementsDragged: (changes) {
            for (final (element, x, y) in changes) {
              ref.read(tagsProvider.notifier).moveTag(element.id, x, y);
            }
          },
          onElementsResize: (changes) {
            for (final (element, width, height) in changes) {
              ref
                  .read(tagsProvider.notifier)
                  .resizeTag(element.id, width, height);
            }
          },
        );
      },
      loading: (_) => ShimmerBox.rectangle(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class EmptyTagsPage extends StatelessWidget {
  const EmptyTagsPage({required this.onCreateTag, super.key});

  final VoidCallback onCreateTag;

  @override
  Widget build(BuildContext context) {
    return Pane(
      id: "empty_tags_page",
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.only(top: 8, left: 8, right: context.isMobile ? 8 : 0),
      child: Section(
        margin: EdgeInsets.zero,
        child: EmptyScreen(
          title: "No tags yet",
          buttonText: "Create Tag",
          onPressed: onCreateTag,
        ),
      ),
    );
  }
}
