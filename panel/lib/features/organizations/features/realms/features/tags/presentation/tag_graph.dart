import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders projected tags as an editable graph.
///
/// Node placement and direct parent IDs become graph elements and edges. Move
/// and resize callbacks submit guarded updates through [CanonicalTags], using
/// the projected tag as the expected observation. Missing parent records are
/// omitted from edges, so malformed references do not block the rest of the
/// graph.
class TagGraph extends HookConsumerWidget {
  const TagGraph({this.onViewportCenterChanged, super.key});

  final ValueChanged<Offset?>? onViewportCenterChanged;

  GraphElement _elementFromTag(
    Tag tag,
    AsyncValue<AuthoringSubjectProjection>? subjects,
  ) {
    return GraphElement(
      id: GraphIdentifier(tag.tagId.id),
      x: tag.placement.x,
      y: tag.placement.y,
      width: tag.placement.width,
      height: tag.placement.height,
      builder: (context) => SizedBox.expand(
        child: TagNode(tagId: tag.tagId, subjects: subjects),
      ),
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

  GraphData _graphFromTags(
    BuildContext context,
    List<Tag> tags,
    AsyncValue<AuthoringSubjectProjection>? subjects,
  ) {
    final elements = tags.map((tag) => _elementFromTag(tag, subjects)).toList();
    final edges = _edgesFromTags(context, tags);

    return GraphData(
      cellSize: tagGraphCellSize,
      elements: elements,
      edges: edges,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(projectedTagsProvider);

    return tags(
      name: "tags",
      builder: (tagList) {
        if (tagList.isEmpty) {
          return EmptyTagsPage(
            onCreateTag: () => ref
                .read(resourceCreationProvider)
                .create(
                  context: context,
                  request: ResourceCreationRequest(
                    kind: skir.ResourceKind.tag,
                    title: "Create Tag",
                    partial: tagCreationPartial(tagList),
                  ),
                ),
          );
        }

        final tagIds = {for (final tag in tagList) tag.tagId.id: tag.tagId};
        final organizationId = ref.watch(organizationIdProvider);
        final realmId = ref.watch(realmIdProvider);
        final subjects = organizationId == null || realmId == null
            ? null
            : ref.watch(
                authoringSubjectsProvider(
                  AuthoringSubjectScope(
                    organizationId: organizationId,
                    realmId: realmId,
                    resources: {
                      for (final tag in tagList)
                        tag.tagId: referenceResourceTypes.tag,
                    },
                  ),
                ),
              );

        return Graph(
          data: _graphFromTags(context, tagList, subjects),
          onViewportCenterChanged: onViewportCenterChanged,
          onElementsMoved: (changes) {
            final tagsById = {for (final tag in tagList) tag.tagId: tag};
            for (final change in changes) {
              final tagId = tagIds[change.id.id];
              final tag = tagsById[tagId];
              if (tag == null) continue;
              ref
                  .read(canonicalTagsProvider.notifier)
                  .updateTag(
                    tag.copyWith(
                      placement: tag.placement.copyWith(
                        x: change.x,
                        y: change.y,
                      ),
                    ),
                  );
            }
          },
          onElementsResized: (changes) {
            final tagsById = {for (final tag in tagList) tag.tagId: tag};
            for (final change in changes) {
              final tagId = tagIds[change.id.id];
              final tag = tagsById[tagId];
              if (tag == null) continue;
              ref
                  .read(canonicalTagsProvider.notifier)
                  .updateTag(
                    tag.copyWith(
                      placement: tag.placement.copyWith(
                        width: change.width,
                        height: change.height,
                      ),
                    ),
                  );
            }
          },
        );
      },
    );
  }
}

/// Empty state used when the projected Realm contains no tags.
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
