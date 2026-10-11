import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the shared working tags. Each graph gesture stages one atomic group.
class TagGraph extends HookConsumerWidget {
  const TagGraph({this.onViewportCenterChanged, super.key});

  final ValueChanged<Offset?>? onViewportCenterChanged;

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
    final tags = ref.watch(workingTagsProvider);
    final scope = ref.watch(selectedAuthoringScopeProvider);

    return tags(
      name: "tags",
      builder: (tagList) {
        if (tagList.isEmpty) {
          final template =
              (ref
                      .read(selectedWorkingAuthoringDocumentProvider)
                      .value
                      ?.catalog)
                  .resourceCreationTemplate(coreTagResourceDefinition.value);
          return EmptyTagsPage(
            onCreateTag: template == null || scope == null
                ? null
                : () async {
                    final created = await ref
                        .read(resourceCreationProvider(scope))
                        .create(
                          context: context,
                          request: ResourceCreationRequest(
                            definition: template.definition,
                            configuration: template.configuration,
                          ),
                        );
                    if (created == null) return;
                    ref
                        .read(selectionProvider.notifier)
                        .select(
                          AuthoringResourceIdentifier.inScope(
                            created.scope,
                            created.id,
                          ),
                        );
                  },
          );
        }

        final from = ref
            .read(selectedWorkingAuthoringDocumentProvider)
            .requireValue;
        final tagIds = {for (final tag in tagList) tag.tagId.id: tag.tagId};
        return Graph(
          data: _graphFromTags(context, tagList),
          onViewportCenterChanged: onViewportCenterChanged,
          onElementsMoved: (changes) {
            ref
                .readAuthoringWorkspace()
                .edit(
                  label: "Move tags",
                  from: from,
                  apply: (edit) {
                    for (final change in changes) {
                      final resource = tagIds[change.id.id];
                      if (resource == null) {
                        throw StateError("The moved tag is unavailable");
                      }
                      edit
                        ..setFieldPayload(
                          resource: resource,
                          fields: ["placement", "x"],
                          payload: skir.DataValue.wrapInteger(
                            change.x.toString(),
                          ),
                        )
                        ..setFieldPayload(
                          resource: resource,
                          fields: ["placement", "y"],
                          payload: skir.DataValue.wrapInteger(
                            change.y.toString(),
                          ),
                        );
                    }
                  },
                )
                .report(context);
          },
          onElementsResized: (changes) {
            ref
                .readAuthoringWorkspace()
                .edit(
                  label: "Resize tags",
                  from: from,
                  apply: (edit) {
                    for (final change in changes) {
                      final resource = tagIds[change.id.id];
                      if (resource == null) {
                        throw StateError("The resized tag is unavailable");
                      }
                      edit
                        ..setFieldPayload(
                          resource: resource,
                          fields: ["placement", "width"],
                          payload: skir.DataValue.wrapInteger(
                            change.width.toString(),
                          ),
                        )
                        ..setFieldPayload(
                          resource: resource,
                          fields: ["placement", "height"],
                          payload: skir.DataValue.wrapInteger(
                            change.height.toString(),
                          ),
                        );
                    }
                  },
                )
                .report(context);
          },
        );
      },
    );
  }
}

/// Empty state used when the projected Realm contains no tags.
class EmptyTagsPage extends StatelessWidget {
  const EmptyTagsPage({required this.onCreateTag, super.key});

  final VoidCallback? onCreateTag;

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
