part of "../portable_presentation_renderer.dart";

extension _PortablePageRendering on PortablePresentationNodeRenderer {
  Widget _renderPageGraph(
    BuildContext context,
    skir.PageGraphElement element,
    PortablePresentationScope childScope,
  ) {
    final page = _pageProjection(element.control, childScope);
    if (page case _PageProjectionFailure(:final message)) {
      return _diagnostic(message);
    }
    final projection = page as _PageProjectionValue;
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
    final ids = projection.entries.map((entry) => entry.resource).toSet();
    final relations = {
      for (final relation
          in childScope.catalog?.snapshot.relations ??
              const <skir.RelationContract>[])
        relation.id: relation,
    };
    final edges = <GraphEdge>[];
    for (final link in projection.draft.links) {
      if (!ids.contains(link.first) || !ids.contains(link.second)) continue;
      edges.add(
        GraphEdge(
          id: _linkOccurrenceKey(link, relations[link.contract]),
          source: GraphIdentifier(link.first.value),
          target: GraphIdentifier(link.second.value),
          color: Theme.of(context).colorScheme.outline,
          sourceSide: sides.$1,
          targetSide: sides.$2,
        ),
      );
    }
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
              childScope.stage("Move graph nodes", (operation) {
                for (final change in changes) {
                  _writePageInteger(
                    operation,
                    skir.ResourceId(value: change.id.id),
                    "x",
                    change.x,
                  );
                  _writePageInteger(
                    operation,
                    skir.ResourceId(value: change.id.id),
                    "y",
                    change.y,
                  );
                }
              }, independent: true);
            }
          : null,
      onElementsResized: childScope.enabled && !childScope.readOnly
          ? (changes) {
              childScope.stage("Resize graph nodes", (operation) {
                for (final change in changes) {
                  _writePageInteger(
                    operation,
                    skir.ResourceId(value: change.id.id),
                    "width",
                    change.width,
                  );
                  _writePageInteger(
                    operation,
                    skir.ResourceId(value: change.id.id),
                    "height",
                    change.height,
                  );
                }
              }, independent: true);
            }
          : null,
    );
  }

  Widget _renderPageTimeline(
    BuildContext context,
    skir.PageTimelineElement element,
    PortablePresentationScope childScope,
  ) {
    final page = _pageProjection(element.control, childScope);
    if (page case _PageProjectionFailure(:final message)) {
      return _diagnostic(message);
    }
    final projection = page as _PageProjectionValue;
    final catalog = childScope.catalog;
    if (catalog == null) {
      return _diagnostic("The page timeline catalog is unavailable");
    }
    final byId = {
      for (final entry in projection.entries) entry.resource: entry,
    };
    final tracks = <TimelineTrack>[];
    for (final entry in projection.entries) {
      final visited = <skir.ResourceId>{entry.resource};
      final cues = <TimelineElement>[];
      for (final neighbor in _ownedTimelineTargets(
        projection.draft,
        catalog,
        entry.resource,
      )) {
        final cue = _timelineElement(
          context,
          projection.draft,
          catalog,
          neighbor,
          byId,
          childScope,
          visited,
          null,
        );
        if (cue != null) cues.add(cue);
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
              childScope.stage("Move timeline elements", (operation) {
                for (final change in changes) {
                  final id = skir.ResourceId(value: change.id.id);
                  final record = operation.resource(id);
                  final placement = record?.authoredField("placement");
                  if (placement?.authoredField("frame") != null) {
                    _writePageInteger(
                      operation,
                      id,
                      "frame",
                      change.startFrame,
                    );
                  } else {
                    _writePageInteger(
                      operation,
                      id,
                      "startFrame",
                      change.startFrame,
                    );
                    _writePageInteger(
                      operation,
                      id,
                      "endFrame",
                      change.endFrame,
                    );
                  }
                }
              }, independent: true);
            }
          : null,
    );
  }

  Widget _pageResourceCard(
    _PageEntry entry,
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
                childScope.stage("Change page resource", (operation) {
                  switch (action) {
                    case _PageResourceAction.disconnect:
                      operation.disconnect(entry.occurrence);
                    case _PageResourceAction.delete:
                      operation.delete(entry.resource);
                  }
                }, independent: true);
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
    final draft = parent.authoring;
    final catalog = parent.catalog;
    final record = draft?.resource(resource);
    if (draft == null || catalog == null || record == null) {
      return Text(resource.value);
    }
    final selected = catalog.selectPresentation(record.configuration, role);
    if (selected is! SelectedEditorPresentation) {
      return Text(
        record.authoredField("name")?.authoredString ?? resource.value,
      );
    }
    return PortablePresentationNodeRenderer(
      node: selected.material.layout,
      scope: PortablePresentationScope(
        bindings: {
          _configuredValueBindingId: PortableExpressionBinding(
            value: skir.DataValue.createRecord(fields: record.fields),
            location: skir.ValueLocation(
              resource: resource,
              path: skir.ValuePath(segments: const []),
            ),
          ),
        },
        budget: parent.budget,
        setBinding: (reference, value) {
          if (reference.bindingId != _configuredValueBindingId) return;
          parent.stage("Edit resource value", (operation) {
            operation.set(
              skir.ValueLocation(resource: resource, path: reference.path),
              value,
            );
          });
        },
        readOnly: parent.readOnly,
        enabled: parent.enabled,
        invokeCommand: parent.invokeCommand,
        watchSearch: parent.watchSearch,
        reload: parent.reload,
        reportStatus: parent.reportStatus,
        commit: parent.commit,
        authoring: draft,
        catalog: catalog,
        resource: resource,
        role: selected.resolvedRole,
        material: selected.material,
        activePresentations: {selected.material.provider},
        edit: parent.edit,
        openResource: parent.openResource,
        prepareCreation: parent.prepareCreation,
        host: parent.host,
      ),
    );
  }
}

enum _PageResourceAction { disconnect, delete }

sealed class _PageProjection {
  const _PageProjection();
}

final class _PageProjectionValue extends _PageProjection {
  const _PageProjectionValue({required this.draft, required this.entries});

  final PortableAuthoringView draft;
  final List<_PageEntry> entries;
}

final class _PageProjectionFailure extends _PageProjection {
  const _PageProjectionFailure(this.message);

  final String message;
}

final class _PageEntry {
  const _PageEntry({
    required this.resource,
    required this.draft,
    required this.occurrence,
    required this.graph,
  });

  final skir.ResourceId resource;
  final PortableAuthoringView draft;
  final skir.LinkOccurrence occurrence;
  final _PageGraphPlacement? graph;
}

final class _PageGraphPlacement {
  const _PageGraphPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

_PageProjection _pageProjection(
  skir.BoundControl control,
  PortablePresentationScope scope,
) {
  final draft = scope.authoring;
  final source = scope.location(control.binding);
  if (draft == null || source == null) {
    return const _PageProjectionFailure(
      "The page elements binding is unavailable",
    );
  }
  final relations = {
    for (final relation
        in scope.catalog?.snapshot.relations ?? const <skir.RelationContract>[])
      relation.id: relation,
  };
  final entries = <_PageEntry>[];
  for (final link in draft.links) {
    final first =
        link.first == source.resource &&
        _pathIsAtOrBelow(link.firstLocation, source.path);
    final second =
        link.second == source.resource &&
        _pathIsAtOrBelow(link.secondLocation, source.path);
    if (!first && !second) continue;
    final relation = relations[link.contract];
    final endpoint = first ? relation?.first.id : relation?.second.id;
    final location = first ? link.firstLocation : link.secondLocation;
    final opposite = first ? link.secondLocation : link.firstLocation;
    if (endpoint == null || location == null) continue;
    final target = first ? link.second : link.first;
    final record = draft.resource(target);
    if (record == null) continue;
    entries.add(
      _PageEntry(
        resource: target,
        draft: draft,
        occurrence: skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: endpoint,
            location: skir.ValueLocation(
              resource: source.resource,
              path: location,
            ),
          ),
          source: source.resource,
          target: skir.LinkTarget(resource: target, opposite: opposite),
        ),
        graph: _graphPlacement(record.authoredField("placement")),
      ),
    );
  }
  return _PageProjectionValue(draft: draft, entries: entries);
}

bool _pathIsAtOrBelow(skir.ValuePath? candidate, skir.ValuePath parent) {
  if (candidate == null) return false;
  final child = candidate.segments.toList(growable: false);
  final root = parent.segments.toList(growable: false);
  if (child.length < root.length) return false;
  for (var index = 0; index < root.length; index++) {
    if (child[index] != root[index]) return false;
  }
  return true;
}

_PageGraphPlacement? _graphPlacement(skir.DataValue? value) {
  final x = value?.authoredField("x")?.authoredInteger?.toInt();
  final y = value?.authoredField("y")?.authoredInteger?.toInt();
  final width = value?.authoredField("width")?.authoredInteger?.toInt();
  final height = value?.authoredField("height")?.authoredInteger?.toInt();
  if (x == null || y == null || width == null || height == null) return null;
  if (width <= 0 || height <= 0) return null;
  return _PageGraphPlacement(x: x, y: y, width: width, height: height);
}

String _linkOccurrenceKey(
  skir.LinkProjection link,
  skir.RelationContract? relation,
) {
  final location = link.firstLocation ?? link.secondLocation;
  final first = link.firstLocation != null;
  final endpoint = first ? relation?.first.id : relation?.second.id;
  final containing = first ? link.first : link.second;
  return _framed([
    endpoint?.value ?? link.contract.value,
    containing.value,
    _pathKey(location),
  ]);
}

String _pathKey(skir.ValuePath? path) {
  if (path == null) return "n";
  return _framed([
    for (final segment in path.segments)
      switch (segment) {
        skir.PathSegment_fieldWrapper(:final value) => "f:${value.name}",
        skir.PathSegment_itemWrapper(:final value) => "i:${value.id.value}",
        skir.PathSegment.mapKey => "k",
        skir.PathSegment.mapValue => "v",
        skir.PathSegment_unknown() => "u",
      },
  ]);
}

String _framed(Iterable<String> values) =>
    values.map((value) => "${value.length}:$value").join();

enum _TimelinePlacementKind { segment, keyframe }

_TimelinePlacementKind? _timelinePlacementKind(
  CheckedEditorCatalog catalog,
  skir.AuthoringRecord record,
) {
  final placement = catalog
      .fields(record.configuration)
      .where((field) => field.template.key == "placement")
      .firstOrNull
      ?.type;
  if (placement == null) return null;
  if (catalog.isReadableAs(placement, _timelineKeyframePlacement)) {
    return _TimelinePlacementKind.keyframe;
  }
  if (catalog.isReadableAs(placement, _timelineSegmentPlacement)) {
    return _TimelinePlacementKind.segment;
  }
  return null;
}

final _timelineSegmentPlacement = _declaredType(
  "54e38e56871243d2ae747ed6c0083381",
);
final _timelineKeyframePlacement = _declaredType(
  "e0369811aac94bf6a291f65d1c719e1b",
);

skir.TypeUse _declaredType(String id) => skir.TypeUse.createNamed(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(value: id),
    revision: 1,
  ),
  arguments: const [],
);

void _writePageInteger(
  AuthoringEdit draft,
  skir.ResourceId resource,
  String field,
  int value,
) {
  final location = skir.ValueLocation(
    resource: resource,
    path: skir.ValuePath(
      segments: [
        skir.PathSegment.createField(name: "placement"),
        skir.PathSegment.createField(name: field),
      ],
    ),
  );
  final current = draft.read(location);
  if (current is! PortablePathValue<skir.DataValue>) {
    throw StateError("The resource placement is unavailable");
  }
  final replacement = current.value.withAuthoredPayload(
    skir.DataValue.wrapInteger(value.toString()),
  );
  draft.set(location, replacement);
}

Iterable<skir.ResourceId> _ownedTimelineTargets(
  PortableAuthoringView draft,
  CheckedEditorCatalog catalog,
  skir.ResourceId source,
) sync* {
  final record = draft.resource(source);
  if (record == null) return;
  final relations = {
    for (final relation in catalog.snapshot.relations) relation.id: relation,
  };
  for (final link in draft.links) {
    final sourceIsFirst = link.first == source;
    final sourceIsSecond = link.second == source;
    if (!sourceIsFirst && !sourceIsSecond) continue;
    final relation = relations[link.contract];
    if (relation == null ||
        !relation.families.any(
          (family) => family.value == "resource.ownership",
        )) {
      continue;
    }
    final sourceEndpoint = sourceIsFirst ? relation.first : relation.second;
    final targetEndpoint = sourceIsFirst ? relation.second : relation.first;
    if (sourceEndpoint.cardinality != skir.EndpointCardinality.one ||
        targetEndpoint.cardinality != skir.EndpointCardinality.many) {
      continue;
    }
    final target = sourceIsFirst ? link.second : link.first;
    final targetRecord = draft.resource(target);
    if (targetRecord == null ||
        !catalog.isResourceDefinition(
          targetRecord.configuration,
          _timelineCueResource,
        ) ||
        _timelinePlacementKind(catalog, targetRecord) == null) {
      continue;
    }
    yield target;
  }
}

final _timelineCueResource = skir.ResourceDefinitionId(value: "typewriter.cue");

TimelineElement? _timelineElement(
  BuildContext context,
  PortableAuthoringView draft,
  CheckedEditorCatalog catalog,
  skir.ResourceId resource,
  Map<skir.ResourceId, _PageEntry> direct,
  PortablePresentationScope scope,
  Set<skir.ResourceId> visited,
  TimelineIdentifier? parent,
) {
  if (direct.containsKey(resource) || !visited.add(resource)) return null;
  final record = draft.resource(resource);
  final placement = record?.authoredField("placement");
  if (record == null || placement == null) return null;
  final kind = _timelinePlacementKind(catalog, record);
  if (kind == null) return null;
  final label = record.authoredField("name")?.authoredString ?? resource.value;
  final id = TimelineIdentifier(resource.value);
  final color = Theme.of(context).colorScheme.primary;
  final frame = placement.authoredField("frame")?.authoredInteger?.toInt();
  if (kind == _TimelinePlacementKind.keyframe && frame != null && frame >= 0) {
    return TimelineKeyframe(
      id: id,
      frame: frame,
      parentId: parent,
      color: color,
      builder: (_, _) => GestureDetector(
        onTap: scope.openResource == null
            ? null
            : () => scope.openResource!(resource),
        child: Semantics(label: label, child: const Icon(Icons.circle)),
      ),
    );
  }
  final start = placement.authoredField("startFrame")?.authoredInteger?.toInt();
  final end = placement.authoredField("endFrame")?.authoredInteger?.toInt();
  if (start == null || end == null || start < 0 || end < start) return null;
  final children = <TimelineElement>[];
  for (final neighbor in _ownedTimelineTargets(draft, catalog, resource)) {
    final child = _timelineElement(
      context,
      draft,
      catalog,
      neighbor,
      direct,
      scope,
      visited,
      id,
    );
    if (child != null && child.endFrame <= end - start) children.add(child);
  }
  return TimelineSegment(
    id: id,
    startFrame: start,
    endFrame: end,
    parentId: parent,
    color: color,
    children: children,
    builder: (_, _) => GestureDetector(
      onTap: scope.openResource == null
          ? null
          : () => scope.openResource!(resource),
      child: Text(label, overflow: TextOverflow.ellipsis),
    ),
  );
}
