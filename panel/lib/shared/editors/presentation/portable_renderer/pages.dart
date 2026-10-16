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
      final PortablePageHost value => value,
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
    final appearance = element.appearance;
    final cellSize = appearance?.cellSize == null
        ? 50.0
        : _number(childScope, appearance!.cellSize);
    if (cellSize == null || !cellSize.isFinite || cellSize <= 0) {
      return _diagnostic("Graph cell size must be finite and positive");
    }
    final edgeColor =
        _color(context, childScope, appearance?.edgeColor) ??
        Theme.of(context).colorScheme.outline;
    final cardPadding = appearance?.cardPadding == null
        ? null
        : _presentationInsets(appearance!.cardPadding);
    final edges = [
      for (final edge in projection.edges)
        GraphEdge(
          id: edge.id,
          source: GraphIdentifier(edge.source.value),
          target: GraphIdentifier(edge.target.value),
          color: edgeColor,
          sourceSide: sides.$1,
          targetSide: sides.$2,
        ),
    ];
    final interactions = PortablePageInteractionScope.maybeOf(context);
    final graph = Graph(
      data: GraphData(
        cellSize: cellSize,
        elements: [
          for (final entry in projection.entries)
            GraphElement(
              id: GraphIdentifier(entry.resource.value),
              x: entry.graph?.x ?? 0,
              y: entry.graph?.y ?? projection.entries.indexOf(entry) * 2,
              width: entry.graph?.width ?? 4,
              height: entry.graph?.height ?? 1,
              builder: (context) {
                final presentation = _pageGraphNode(context, entry, childScope);
                final child = cardPadding == null
                    ? presentation
                    : Padding(padding: cardPadding, child: presentation);
                if (interactions != null) {
                  return interactions.nodeBuilder(
                    context,
                    entry,
                    childScope,
                    child,
                  );
                }
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: childScope.openResource == null
                      ? null
                      : () => childScope.openResource!(entry.resource),
                  child: child,
                );
              },
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
    return interactions?.graphBuilder(
          context,
          projection.entries,
          childScope,
          graph,
        ) ??
        graph;
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
      final PortablePageHost value => value,
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
          header: (_) => _pageTimelineHeader(entry, childScope),
          elements: cues,
        ),
      );
    }
    return Timeline(
      data: TimelineData(tracks: tracks),
      style: element.appearance == null
          ? null
          : _pageTimelineStyle(context, childScope, element.appearance!),
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

  Widget _pageTimelineHeader(
    PortablePageEntryProjection entry,
    PortablePresentationScope childScope,
  ) {
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
            Expanded(
              child: Text(
                entry.resourceProjection.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<_PageResourceAction>(
              enabled: editable,
              onSelected: (action) {
                final pageHost = switch (childScope.host) {
                  final PortablePageHost value => value,
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

  Widget _pageGraphNode(
    BuildContext context,
    PortablePageEntryProjection entry,
    PortablePresentationScope parent,
  ) {
    final projected = entry.resourceProjection;
    final selected = parent.catalog?.selectPresentation(
      projected.configuration,
      skir.PresentationRole.graphNode,
    );
    final content = switch (selected) {
      SelectedEditorPresentation() => PortablePresentationNodeRenderer(
        node: selected.material.layout,
        scope: parent.forResourcePresentation(projected, selected),
        fillAvailableSpace: true,
      ),
      ConflictingEditorPresentation(:final candidates) => _diagnostic(
        "The graph node has ${candidates.length} conflicting presentations",
      ),
      UnavailableEditorPresentation(:final presentation) => _diagnostic(
        "Presentation ${presentation.namespace}:${presentation.name} is unavailable",
      ),
      _ => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: context.shapes.mediumBorderRadius,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(projected.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    };
    return PortableDiagnosticSource(
      diagnostics: projected.diagnostics,
      diagnosticFallback: projected.diagnosticFallback,
      observations: [
        PortableDiagnosticObservation(
          target: PortableDiagnosticTarget.value(
            skir.ValueLocation(resource: entry.resource, path: editorRootPath),
          ),
          value: projected.value,
        ),
      ],
      child: content,
    );
  }
}

enum _PageResourceAction { disconnect, delete }

void _reportPageWrite(
  PortablePresentationScope scope,
  PortablePresentationWriteResult result,
) {
  unawaited(
    scope.operations.run(
      key: const PortableOperationKey.status(),
      operation: () => result,
    ),
  );
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

TimelineStyle _pageTimelineStyle(
  BuildContext context,
  PortablePresentationScope scope,
  skir.PageTimelineAppearance appearance,
) {
  final base = TimelineStyle.fallback(Theme.of(context));
  double dimension(double? value, double fallback, {bool positive = false}) {
    if (value == null) return fallback;
    if (!value.isFinite || (positive ? value <= 0 : value < 0)) {
      throw const PresentationColorFailure(
        "Timeline dimensions must be finite and within their allowed range",
      );
    }
    return value;
  }

  Color color(skir.PresentationColor? value, Color fallback) =>
      _color(context, scope, value) ?? fallback;
  final palette = base.palette;
  return TimelineStyle(
    rulerHeight: dimension(
      appearance.rulerHeight,
      base.rulerHeight,
      positive: true,
    ),
    trackPadding: dimension(appearance.trackPadding, base.trackPadding),
    laneHeight: dimension(
      appearance.laneHeight,
      base.laneHeight,
      positive: true,
    ),
    laneGap: dimension(appearance.laneGap, base.laneGap),
    headerPadding: dimension(appearance.headerPadding, base.headerPadding),
    minHeaderWidth: base.minHeaderWidth,
    maxHeaderWidth: base.maxHeaderWidth,
    minPixelsPerFrame: base.minPixelsPerFrame,
    maxPixelsPerFrame: base.maxPixelsPerFrame,
    gridMinorMinSpacing: base.gridMinorMinSpacing,
    gridMajorMinSpacing: base.gridMajorMinSpacing,
    gridTickSteps: base.gridTickSteps,
    trailingFrames: base.trailingFrames,
    minSegmentWidth: base.minSegmentWidth,
    keyframeWidth: base.keyframeWidth,
    keyframeSize: base.keyframeSize,
    edgeHandleWidth: base.edgeHandleWidth,
    palette: TimelinePalette(
      headerBackground: color(appearance.headerColor, palette.headerBackground),
      rulerBackground: color(appearance.rulerColor, palette.rulerBackground),
      trackBackground: color(appearance.trackColor, palette.trackBackground),
      trackAltBackground: color(
        appearance.alternateTrackColor,
        palette.trackAltBackground,
      ),
      gridMinor: color(appearance.gridMinorColor, palette.gridMinor),
      gridMajor: color(appearance.gridMajorColor, palette.gridMajor),
      headerDivider: palette.headerDivider,
      textMuted: color(appearance.textMutedColor, palette.textMuted),
    ),
  );
}
