part of "authored_presentation_host.dart";

/// Resource projections for graph, timeline and page surfaces and their edits.
extension _AuthoredPresentationResources on AuthoredPresentationHost {
  PortableResourceProjection? _projectResource(
    skir.ResourceId resource, {
    required PortableInvocationContext context,
  }) {
    final observation = context.queries?.authored;
    final catalog = context.queries?.catalog;
    if (observation == null ||
        catalog == null ||
        context.catalogGeneration != observation.generation) {
      return null;
    }
    final record = observation.resource(resource);
    if (record == null) return null;
    return PortableResourceProjection(
      resource: resource,
      configuration: record.configuration,
      appearance: catalog.appearanceOf(record),
      value: _resourceRow(record),
      diagnosticFallback: PortableDiagnosticFallback.resource,
      diagnostics: context.resourceDiagnostics(resource),
    );
  }

  PortableResourcesProjection _projectResources(
    skir.BindingRef source, {
    required PortableInvocationContext context,
  }) {
    final location = this.location(source, context: context);
    if (location == null) {
      return PortableResourcesProjection(
        members: [],
        edges: [],
        timeline: {},
        problem: "The resources binding is unavailable",
      );
    }
    final relations = {
      for (final relation in authored.catalog.snapshot.relations)
        relation.id: relation,
    };
    final items = switch (authored
        .resource(location.resource)
        ?.readAt(location.path)) {
      PortablePathValue(:final value) => value.authoredItems,
      _ => null,
    };
    final positions = {
      for (final (index, item) in (items ?? const <skir.ListItem>[]).indexed)
        item.id: index,
    };
    int position(skir.ValuePath path) =>
        switch (path.segments.elementAtOrNull(location.path.segments.length)) {
          skir.PathSegment_itemWrapper(:final value) =>
            positions[value.id] ?? positions.length,
          _ => positions.length,
        };
    final members = <(int, PortableResourceMember)>[];
    for (final link in authored.links) {
      final first =
          link.first == location.resource &&
          (link.firstLocation?.isAtOrBelow(location.path) ?? false);
      final second =
          link.second == location.resource &&
          (link.secondLocation?.isAtOrBelow(location.path) ?? false);
      if (!first && !second) continue;
      final relation = relations[link.contract];
      final endpoint = first ? relation?.first.id : relation?.second.id;
      final relative = first ? link.firstLocation : link.secondLocation;
      final opposite = first ? link.secondLocation : link.firstLocation;
      if (endpoint == null || relative == null) continue;
      final target = first ? link.second : link.first;
      final resource = projectResource(target, context: context);
      final record = authored.resource(target);
      if (resource == null || record == null) continue;
      final linkTarget = skir.LinkTarget(resource: target, opposite: opposite);
      final value = switch (authored
          .resource(location.resource)
          ?.readAt(relative)) {
        PortablePathValue(:final value) when value.authoredLink != null =>
          value,
        _ => skir.DataValue.createLink(endpoint: endpoint, target: linkTarget),
      };
      members.add((
        position(relative),
        PortableResourceMember(
          resource: target,
          occurrence: skir.LinkOccurrence(
            id: skir.LinkOccurrenceId(
              endpoint: endpoint,
              location: skir.ValueLocation(
                resource: location.resource,
                path: relative,
              ),
            ),
            source: location.resource,
            target: linkTarget,
          ),
          link: value,
          resourceProjection: resource,
          graph: _graphPlacement(record),
        ),
      ));
    }
    final ordered = members.indexed.toList()
      ..sort((left, right) {
        final compared = left.$2.$1.compareTo(right.$2.$1);
        return compared != 0 ? compared : left.$1.compareTo(right.$1);
      });
    final memberList = [for (final (_, (_, member)) in ordered) member];
    final ids = memberList.map((member) => member.resource).toSet();
    final edges = <PortableResourceEdge>[];
    for (final link in authored.links) {
      if (!ids.contains(link.first) || !ids.contains(link.second)) continue;
      edges.add(
        PortableResourceEdge(
          id: _linkOccurrenceKey(link, relations[link.contract]),
          source: link.first,
          target: link.second,
        ),
      );
    }
    final ownership = authored.relations;
    final timeline = <skir.ResourceId, List<PortableTimelineCueProjection>>{};
    for (final member in memberList) {
      final visited = <skir.ResourceId>{member.resource};
      timeline[member.resource] = [
        for (final target in _ownedTimelineTargets(member.resource, ownership))
          ?_timelineCue(target, ids, visited, ownership),
      ];
    }
    return PortableResourcesProjection(
      members: memberList,
      edges: edges,
      timeline: timeline,
      problem: switch ({
        for (final resource in {location.resource, ...ids})
          ...(ownership.resourceProblems[resource] ?? const <String>[]),
      }) {
        final problems when problems.isNotEmpty => problems.join("\n"),
        _ => null,
      },
    );
  }

  PortablePresentationWriteResult _moveGraphNodes(
    List<PortableGraphPositionChange> changes, {
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Move graph nodes", (operation) {
    for (final change in changes) {
      operation.moveGraphPlacement(change.resource, change.x, change.y);
    }
  });

  PortablePresentationWriteResult _resizeGraphNodes(
    List<PortableGraphSizeChange> changes, {
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Resize graph nodes", (operation) {
    for (final change in changes) {
      operation.resizeGraphPlacement(
        change.resource,
        change.width,
        change.height,
      );
    }
  });

  PortablePresentationWriteResult _moveTimelineElements(
    List<PortableTimelineChange> changes, {
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Move timeline elements", (operation) {
    for (final change in changes) {
      operation.moveTimelinePlacement(
        change.resource,
        change.startFrame,
        change.endFrame,
      );
    }
  });

  PortablePresentationWriteResult _removeMember(
    PortableResourceMember member, {
    required bool delete,
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Change resources", (operation) {
    if (delete) {
      operation.delete(member.resource);
    } else {
      operation.disconnect(member.occurrence);
    }
  });

  PortablePresentationWriteResult _pageEdit(
    PortableInvocationContext context,
    String label,
    void Function(AuthoringEdit operation) apply,
  ) {
    if (context.catalogGeneration != authored.generation) {
      return _reject("The editor catalog changed");
    }
    return _stage(label, apply, independent: true);
  }

  PortableGraphPlacement? _graphPlacement(skir.AuthoringRecord record) =>
      switch (record.placement(authored.catalog)) {
        ReadyPlacement(placement: final GraphPlacement value) =>
          PortableGraphPlacement(
            x: value.x,
            y: value.y,
            width: value.width,
            height: value.height,
          ),
        _ => null,
      };

  /// Resources owned by [source] that the timeline places: any owned resource
  /// with a timeline placement.
  Iterable<skir.ResourceId> _ownedTimelineTargets(
    skir.ResourceId source,
    AuthoringRelationIndex relations,
  ) sync* {
    if (authored.resource(source) == null) return;
    for (final target in relations.ownedBy(source)) {
      if (authored.resource(target) case final record?
          when _timelinePlacement(record) != null) {
        yield target;
      }
    }
  }

  PortableTimelinePlacement? _timelinePlacement(skir.AuthoringRecord record) =>
      switch (record.placement(authored.catalog)) {
        ReadyPlacement(placement: TimelineKeyframePlacement(:final frame)) =>
          PortableTimelineKeyframe(frame),
        ReadyPlacement(
          placement: TimelineSegmentPlacement(
            :final startFrame,
            :final endFrame,
          ),
        ) =>
          PortableTimelineSegment(startFrame, endFrame),
        _ => null,
      };

  PortableTimelineCueProjection? _timelineCue(
    skir.ResourceId resource,
    Set<skir.ResourceId> direct,
    Set<skir.ResourceId> visited,
    AuthoringRelationIndex relations,
  ) {
    if (direct.contains(resource) || !visited.add(resource)) return null;
    final record = authored.resource(resource);
    if (record == null) return null;
    final placement = _timelinePlacement(record);
    if (placement == null) return null;
    final children = <PortableTimelineCueProjection>[];
    for (final target in _ownedTimelineTargets(resource, relations)) {
      final child = _timelineCue(target, direct, visited, relations);
      if (child != null) children.add(child);
    }
    return PortableTimelineCueProjection(
      resource: resource,
      label: authored.catalog.appearanceOf(record).label,
      placement: placement,
      children: children,
    );
  }

  skir.DataValue _resourceRow(skir.AuthoringRecord record) {
    final payload = skir.DataValue.createRecord(fields: record.fields);
    return switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
  }
}
