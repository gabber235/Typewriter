import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const tagGraphCellSize = 50.0;

class TagGraph extends HookConsumerWidget {
  const TagGraph({super.key});

  GraphElement _elementFromTag(Tag tag) {
    return GraphElement(
      id: GraphIdentifier(tag.tagId.id),
      x: tag.placement.x,
      y: tag.placement.y,
      width: tag.placement.width,
      height: tag.placement.height,
      builder: (context) => SizedBox.expand(child: TagNode(tagId: tag.tagId)),
    );
  }

  List<GraphEdge> _edgesFromTags(BuildContext context, List<Tag> tags) {
    final edges = <GraphEdge>[];
    final tagMap = {for (final tag in tags) tag.tagId: tag};

    for (final tag in tags) {
      for (final parentId in tag.parentIds) {
        final parentTag = tagMap[parentId];
        if (parentTag == null) continue;

        edges.add(
          GraphEdge(
            id: "${parentId.id}:${tag.tagId.id}",
            source: GraphIdentifier(parentId.id),
            target: GraphIdentifier(tag.tagId.id),
            color: parentTag.color.toARGB32() != 0
                ? parentTag.color
                : context.colors.contentDisabled,
            sourceSide: EdgeSide.bottom,
            targetSide: EdgeSide.top,
          ),
        );
      }
    }

    return edges;
  }

  GraphData _graphFromTags(BuildContext context, List<Tag> tags) {
    final elements = tags.map(_elementFromTag).toList();
    final edges = _edgesFromTags(context, tags);

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

        final tagIds = {for (final tag in tagList) tag.tagId.id: tag.tagId};

        return Graph(
          data: _graphFromTags(context, tagList),
          onElementsDragged: (changes) {
            for (final (element, x, y) in changes) {
              final tagId = tagIds[element.id];
              if (tagId == null) continue;
              ref.read(tagsProvider.notifier).moveTag(tagId, x, y);
            }
          },
          onElementsResize: (changes) {
            for (final (element, width, height) in changes) {
              final tagId = tagIds[element.id];
              if (tagId == null) continue;
              ref.read(tagsProvider.notifier).resizeTag(tagId, width, height);
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
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
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
