import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const tagGraphCellSize = 50.0;

class TagGraph extends HookConsumerWidget {
  const TagGraph({super.key});

  GraphElement _elementFromTag(Tag tag) {
    return GraphElement(
      id: GraphIdentifier(tag.tagId),
      x: tag.placement.x,
      y: tag.placement.y,
      width: tag.placement.width,
      height: tag.placement.height,
      builder: (context) => SizedBox.expand(child: TagNode(tagId: tag.tagId)),
    );
  }

  List<GraphEdge> _edgesFromTags(List<Tag> tags) {
    final edges = <GraphEdge>[];
    final tagMap = {for (final tag in tags) tag.tagId: tag};

    for (final tag in tags) {
      for (final parentId in tag.parentIds) {
        final parentTag = tagMap[parentId];
        if (parentTag == null) continue;

        edges.add(
          GraphEdge(
            id: "$parentId-${tag.tagId}",
            source: GraphIdentifier(parentId),
            target: GraphIdentifier(tag.tagId),
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
