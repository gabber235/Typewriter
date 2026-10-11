part of "../portable_presentation_renderer.dart";

extension _PortablePageRendering on PortablePresentationNodeRenderer {
  Widget _renderPageGraph(
    BuildContext context,
    skir.PageGraphElement element,
    PortablePresentationScope childScope,
  ) {
    final host = childScope.host;
    if (host is! PortablePageHost) {
      return _diagnostic("The page elements binding is unavailable");
    }
    final pageHost = switch (host) {
      PortablePageHost value => value,
      _ => throw StateError("Page host checked before projection"),
    };
    final projection = pageHost.projectPage(
      element.control.binding,
      context: childScope.invocation,
    );
    if (projection.problem case final message?) return _diagnostic(message);
    final sides = switch (element.direction.kind) {
      skir.PageGraphDirection_kind.rightToLeftConst => (
        EdgeSide.left,
        EdgeSide.right,
      ),
      skir.PageGraphDirection_kind.topToBottomConst => (
        EdgeSide.bottom,
        EdgeSide.top,
      ),
      skir.PageGraphDirection_kind.bottomToTopConst => (
        EdgeSide.top,
        EdgeSide.bottom,
      ),
      _ => (EdgeSide.right, EdgeSide.left),
    };
    final edges = [
      for (final edge in projection.edges)
        GraphEdge(
          id: edge.id,
          source: GraphIdentifier(edge.source.value),
          target: GraphIdentifier(edge.target.value),
          color: Theme.of(context).colorScheme.outline,
          sourceSide: sides.$1,
          targetSide: sides.$2,
        ),
    ];
    return Graph(
      data: GraphData(
        cellSize: 50,
        elements: [
          for (final entry in projection.entries)
            GraphElement(
              id: GraphIdentifier(entry.resource.value),
              x: entry.graph?.x ?? 0,
              y: entry.graph?.y ?? projection.entries.indexOf(entry) * 2,
              width: entry.graph?.width ?? 4,
              height: entry.graph?.height ?? 1,
              builder: (_) => _pageResourceCard(entry, childScope),
            ),
        ],
        edges: edges,
      ),
      onElementsMoved: childScope.enabled && !childScope.readOnly
          ? (changes) {
              _reportPageWrite(
                childScope,
                pageHost.moveGraphNodes([
                  for (final change in changes)
                    PortableGraphPositionChange(
                      skir.ResourceId(value: change.id.id),
                      change.x,
                      change.y,
                    ),
                ], context: childScope.invocation),
              );
            }
          : null,
      onElementsResized: childScope.enabled && !childScope.readOnly
          ? (changes) {
              _reportPageWrite(
                childScope,
                pageHost.resizeGraphNodes([
                  for (final change in changes)
                    PortableGraphSizeChange(
                      skir.ResourceId(value: change.id.id),
                      change.width,
                      change.height,
                    ),
                ], context: childScope.invocation),
              );
            }
          : null,
    );
  }

  Widget _renderPageTimeline(
    BuildContext context,
    skir.PageTimelineElement element,
    PortablePresentationScope childScope,
  ) {
    final host = childScope.host;
    if (host is! PortablePageHost) {
      return _diagnostic("The page elements binding is unavailable");
    }
    final pageHost = switch (host) {
      PortablePageHost value => value,
      _ => throw StateError("Page host checked before projection"),
    };
    final projection = pageHost.projectPage(
      element.control.binding,
      context: childScope.invocation,
    );
    if (projection.problem case final message?) return _diagnostic(message);
    final tracks = <TimelineTrack>[];
    for (final entry in projection.entries) {
      final cues = <TimelineElement>[];
      for (final cue in projection.timeline[entry.resource] ?? const []) {
        final rendered = _timelineElement(context, cue, childScope, null);
        if (rendered != null) cues.add(rendered);
      }
      tracks.add(
        TimelineTrack(
          id: TimelineIdentifier(entry.resource.value),
          header: (_) => _pageResourceCard(entry, childScope),
          elements: cues,
        ),
      );
    }
    return Timeline(
      data: TimelineData(tracks: tracks),
      onElementsCommited: childScope.enabled && !childScope.readOnly
          ? (changes) async {
              _reportPageWrite(
                childScope,
                pageHost.moveTimelineElements([
                  for (final change in changes)
                    PortableTimelineChange(
                      skir.ResourceId(value: change.id.id),
                      change.startFrame,
                      change.endFrame,
                    ),
                ], context: childScope.invocation),
              );
            }
          : null,
    );
  }

  Widget _pageResourceCard(
    PortablePageEntryProjection entry,
    PortablePresentationScope childScope,
  ) {
    final content = _resourcePresentation(
      entry.resource,
      skir.PresentationRole.graphNode,
      childScope,
    );
    final editable = childScope.enabled && !childScope.readOnly;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: childScope.openResource == null
            ? null
            : () => childScope.openResource!(entry.resource),
        child: Row(
          children: [
            Expanded(child: content),
            PopupMenuButton<_PageResourceAction>(
              enabled: editable,
              onSelected: (action) {
                final pageHost = switch (childScope.host) {
                  PortablePageHost value => value,
                  _ => null,
                };
                if (pageHost == null) return;
                _reportPageWrite(
                  childScope,
                  pageHost.removePageResource(
                    entry,
                    delete: action == _PageResourceAction.delete,
                    context: childScope.invocation,
                  ),
                );
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _PageResourceAction.disconnect,
                  child: Text("Disconnect from page"),
                ),
                PopupMenuItem(
                  value: _PageResourceAction.delete,
                  child: Text("Delete resource"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourcePresentation(
    skir.ResourceId resource,
    skir.PresentationRole role,
    PortablePresentationScope parent,
  ) {
    final catalog = parent.catalog;
    final host = parent.host;
    final projectionHost = switch (host) {
      PortableCollectionProjectionHost value => value,
      _ => null,
    };
    final projected = projectionHost?.projectResource(
      resource,
      context: parent.invocation,
    );
    if (catalog == null || projected == null) {
      return Text(resource.value);
    }
    final selected = catalog.selectPresentation(projected.configuration, role);
    if (selected is! SelectedEditorPresentation) {
      return Text(projected.label);
    }
    return PortablePresentationNodeRenderer(
      node: selected.material.layout,
      scope: PortablePresentationScope(
        bindings: {
          _configuredValueBindingId: PortableExpressionBinding(
            value: projected.value,
            location: skir.ValueLocation(
              resource: resource,
              path: skir.ValuePath(segments: const []),
            ),
          ),
        },
        budget: parent.budget,
        readOnly: parent.readOnly,
        enabled: parent.enabled,
        watchSearch: parent.watchSearch,
        reportStatus: parent.reportStatus,
        commit: parent.commit,
        catalog: catalog,
        resource: resource,
        role: selected.resolvedRole,
        material: selected.material,
        activePresentations: {selected.material.provider},
        openResource: parent.openResource,
        host: parent.host,
      ),
    );
  }
}

enum _PageResourceAction { disconnect, delete }

void _reportPageWrite(
  PortablePresentationScope scope,
  PortablePresentationWriteResult result,
) {
  if (result case PortablePresentationWriteRejected(:final message)) {
    scope.reportStatus?.call(message);
  }
}

TimelineElement? _timelineElement(
  BuildContext context,
  PortableTimelineCueProjection cue,
  PortablePresentationScope scope,
  TimelineIdentifier? parent,
) {
  final id = TimelineIdentifier(cue.resource.value);
  final color = Theme.of(context).colorScheme.primary;
  return switch (cue.placement) {
    PortableTimelineKeyframe(:final frame) => TimelineKeyframe(
      id: id,
      frame: frame,
      parentId: parent,
      color: color,
      builder: (_, _) => GestureDetector(
        onTap: scope.openResource == null
            ? null
            : () => scope.openResource!(cue.resource),
        child: Semantics(label: cue.label, child: const Icon(Icons.circle)),
      ),
    ),
    PortableTimelineSegment(:final startFrame, :final endFrame) =>
      TimelineSegment(
        id: id,
        startFrame: startFrame,
        endFrame: endFrame,
        parentId: parent,
        color: color,
        children: [
          for (final child in cue.children)
            if (_timelineElement(context, child, scope, id) case final value?
                when value.endFrame <= endFrame - startFrame)
              value,
        ],
        builder: (_, _) => GestureDetector(
          onTap: scope.openResource == null
              ? null
              : () => scope.openResource!(cue.resource),
          child: Text(cue.label, overflow: TextOverflow.ellipsis),
        ),
      ),
  };
}
