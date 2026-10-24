part of "realm_edit_model.dart";

/// Resource deletion and link staging: connect, disconnect and the counterpart
/// values each link change stages.
extension _AuthoringLinkStaging on AuthoringEdit {
  void _delete(skir.ResourceId id) {
    if (!_resources.containsKey(id)) throw StateError("The resource is absent");
    final contracts = {
      for (final relation
          in catalog?.snapshot.relations ?? <skir.RelationContract>[])
        relation.id: relation,
    };
    final deleting = <skir.ResourceId>{id};
    final pending = <skir.ResourceId>[id];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final link in _links.where(
        (link) => link.first == current || link.second == current,
      )) {
        final contract = contracts[link.contract];
        if (contract == null) {
          throw StateError("The relation contract is unavailable");
        }
        final endpoint = link.first == current
            ? contract.first
            : contract.second;
        if (endpoint.onDelete == skir.RelationDeletePolicy.cascade) {
          final related = link.first == current ? link.second : link.first;
          if (deleting.add(related)) pending.add(related);
        }
      }
    }
    _observeDeletionRelations(deleting);
    for (final link in _links.where(
      (link) => deleting.contains(link.first) != deleting.contains(link.second),
    )) {
      final contract = contracts[link.contract]!;
      final firstDeleted = deleting.contains(link.first);
      final endpoint = firstDeleted ? contract.first : contract.second;
      if (endpoint.onDelete != skir.RelationDeletePolicy.clear) {
        throw StateError("A relation prevents deletion of this resource");
      }
      final survivor = firstDeleted ? link.second : link.first;
      final path = firstDeleted ? link.secondLocation : link.firstLocation;
      if (path != null) {
        _stageLinkClear(skir.ValueLocation(resource: survivor, path: path));
      }
    }
    for (final resource in deleting) {
      _resources.remove(resource);
    }
    _links.removeWhere(
      (link) => deleting.contains(link.first) || deleting.contains(link.second),
    );
    _intents.add(skir.EditIntent.createDeleteResource(id: id));
  }

  void _connect(
    skir.LinkOccurrence source,
    skir.ResourceId target, {
    skir.CounterpartChoice? counterpart,
  }) {
    if (!_resources.containsKey(source.source) ||
        !_resources.containsKey(target) ||
        source.id.location.resource != source.source) {
      throw StateError("The relation resources are unavailable");
    }
    if (counterpart is skir.CounterpartChoice_unknown) {
      throw StateError("The counterpart choice is unavailable");
    }
    _observeRelationPath(source.id.location);
    _observe(_exists(resource: target));
    _observe(_configuration(at: _root(target)));
    _observeIncoming(source.source, null);
    _observeIncoming(target, null);
    _observeRelationsForEndpoint(source.id.endpoint, source.source, target);
    switch (counterpart) {
      case skir.CounterpartChoice_existingWrapper(:final value):
        _observeRelationPath(value.id.location);
      case skir.CounterpartChoice_newWrapper(:final value):
        _observePath(value.containing);
        _observe(_configuration(at: value.containing));
        _observe(_value(at: value.containing));
      case null:
      case skir.CounterpartChoice_unknown():
    }
    _insertMissingCollectionLinkItem(source.id.location);
    _stageConnection(source, target, counterpart);
    final wireSource = source.target.resource.value.isEmpty
        ? skir.LinkOccurrence(
            id: source.id,
            source: source.source,
            target: skir.LinkTarget(resource: target, opposite: null),
          )
        : source;
    _intents.add(
      skir.EditIntent.createConnectRelation(
        source: wireSource,
        target: target,
        counterpart: counterpart,
      ),
    );
  }

  void _insertMissingCollectionLinkItem(skir.ValueLocation location) {
    final record = _resources[location.resource];
    if (record == null || record.readAt(location.path) is PortablePathValue) {
      return;
    }
    final segments = location.path.segments.toList(growable: false);
    if (segments.isEmpty || segments.last is! skir.PathSegment_itemWrapper) {
      return;
    }
    final item = (segments.last as skir.PathSegment_itemWrapper).value.id;
    final containingPath = skir.ValuePath(
      segments: segments.take(segments.length - 1),
    );
    final containing = record.readAt(containingPath);
    final items = switch (containing) {
      PortablePathValue(value: final value) => value.authoredItems,
      PortablePathUnavailable() => null,
    };
    if (items == null) return;
    final result = _insert(
      skir.ValueLocation(resource: location.resource, path: containingPath),
      items.lastOrNull?.id,
      skir.ListItem(id: item, value: skir.DataValue.unfilled),
    );
    if (result case PortablePathUnavailable(:final message)) {
      throw StateError(message);
    }
  }

  void _disconnectOccurrence(skir.LinkOccurrence occurrence) {
    _disconnect(
      occurrence.id,
      source: occurrence.source,
      target: occurrence.target.resource,
    );
  }

  void _disconnect(
    skir.LinkOccurrenceId occurrence, {
    skir.ResourceId? source,
    skir.ResourceId? target,
  }) {
    _observeRelationPath(occurrence.location);
    final actualSource = source ?? occurrence.location.resource;
    final projected = _links.where((link) {
      final first =
          link.first == actualSource &&
          link.firstLocation == occurrence.location.path;
      final second =
          link.second == actualSource &&
          link.secondLocation == occurrence.location.path;
      return first || second;
    }).firstOrNull;
    final actualTarget = projected == null
        ? target
        : projected.first == actualSource
        ? projected.second
        : projected.first;
    _observeIncoming(actualSource, null);
    if (actualTarget != null) {
      _observeIncoming(actualTarget, null);
      _observeRelationsForEndpoint(
        occurrence.endpoint,
        actualSource,
        actualTarget,
      );
    }
    _stageLinkClear(occurrence.location);
    if (projected != null) {
      final oppositePath = projected.first == actualSource
          ? projected.secondLocation
          : projected.firstLocation;
      if (actualTarget != null && oppositePath != null) {
        final opposite = skir.ValueLocation(
          resource: actualTarget,
          path: oppositePath,
        );
        _observeRelationPath(opposite);
        _stageLinkClear(opposite);
      }
    }
    _links.removeWhere(
      (link) => _projectionContainsOccurrence(link, occurrence),
    );
    _intents.add(skir.EditIntent.wrapDisconnectRelation(occurrence));
  }

  void _stageConnection(
    skir.LinkOccurrence source,
    skir.ResourceId target,
    skir.CounterpartChoice? counterpart,
  ) {
    final relations = catalog?.snapshot.relations ?? const [];
    final relation = relations
        .where(
          (candidate) =>
              candidate.first.id == source.id.endpoint ||
              candidate.second.id == source.id.endpoint,
        )
        .firstOrNull;
    if (relation == null) throw StateError("The relation is unavailable");
    final oppositeEndpoint = relation.first.id == source.id.endpoint
        ? relation.second.id
        : relation.first.id;
    final oppositeOccurrence = switch (counterpart) {
      skir.CounterpartChoice_existingWrapper(:final value) => value,
      _ => null,
    };
    final newOpposite = switch (counterpart) {
      skir.CounterpartChoice_newWrapper(:final value) => _stageNewCounterpart(
        source: source,
        target: target,
        oppositeEndpoint: oppositeEndpoint,
        choice: value,
      ),
      _ => null,
    };
    if (counterpart is skir.CounterpartChoice_newWrapper &&
        newOpposite == null) {
      throw StateError("The new counterpart has no valid relation occurrence");
    }
    if (oppositeOccurrence != null &&
        (oppositeOccurrence.source != target ||
            oppositeOccurrence.id.location.resource != target ||
            oppositeOccurrence.id.endpoint != oppositeEndpoint ||
            !_resources.containsKey(target))) {
      throw StateError(
        "The counterpart does not belong to the target endpoint",
      );
    }
    final automaticOpposite = counterpart == null
        ? _automaticScalarCounterpart(target, oppositeEndpoint)
        : null;
    if (automaticOpposite != null) {
      _observeRelationPath(automaticOpposite);
    }
    final oppositePath =
        oppositeOccurrence?.id.location.path ??
        newOpposite?.path ??
        automaticOpposite?.path ??
        (target == source.target.resource ? source.target.opposite : null);
    final previous = _links
        .where((link) => _projectionContainsOccurrence(link, source.id))
        .firstOrNull;
    if (previous != null) {
      _observeRelationProjection(previous);
      final previousTarget = previous.first == source.source
          ? previous.second
          : previous.first;
      _observeIncoming(previousTarget, null);
      final previousOpposite = previous.first == source.source
          ? previous.secondLocation
          : previous.firstLocation;
      if ((previousTarget != target || previousOpposite != oppositePath) &&
          previousOpposite != null) {
        final previousLocation = skir.ValueLocation(
          resource: previousTarget,
          path: previousOpposite,
        );
        _observeRelationPath(previousLocation);
        _stageLinkClear(previousLocation);
      }
    }
    _stageLinkValue(
      source.id.location,
      source.id.endpoint,
      skir.LinkTarget(resource: target, opposite: oppositePath),
    );
    if (oppositeOccurrence != null) {
      _stageLinkValue(
        oppositeOccurrence.id.location,
        oppositeOccurrence.id.endpoint,
        skir.LinkTarget(
          resource: source.source,
          opposite: source.id.location.path,
        ),
      );
    }
    if (newOpposite != null) {
      _stageLinkValue(
        newOpposite,
        oppositeEndpoint,
        skir.LinkTarget(
          resource: source.source,
          opposite: source.id.location.path,
        ),
      );
    }
    if (automaticOpposite != null) {
      _stageLinkValue(
        automaticOpposite,
        oppositeEndpoint,
        skir.LinkTarget(
          resource: source.source,
          opposite: source.id.location.path,
        ),
      );
    }
    _links.removeWhere(
      (link) => _projectionContainsOccurrence(link, source.id),
    );
    final sourceIsFirst = relation.first.id == source.id.endpoint;
    _links.add(
      skir.LinkProjection(
        contract: relation.id,
        first: sourceIsFirst ? source.source : target,
        second: sourceIsFirst ? target : source.source,
        firstLocation: sourceIsFirst ? source.id.location.path : oppositePath,
        secondLocation: sourceIsFirst ? oppositePath : source.id.location.path,
      ),
    );
  }

  skir.ValueLocation? _automaticScalarCounterpart(
    skir.ResourceId resource,
    skir.EndpointId endpoint,
  ) {
    final record = _resources[resource];
    final checked = catalog;
    if (record == null || checked == null) return null;
    return switch (checked.resolveScalarCounterpart(
      configuration: record.configuration,
      resource: resource,
      endpoint: endpoint,
    )) {
      ResolvedResourceCounterpart(:final location) => location,
      ResourceCounterpartChoiceRequired() ||
      InvalidResourceCounterpart() => null,
    };
  }

  skir.ValueLocation? _stageNewCounterpart({
    required skir.LinkOccurrence source,
    required skir.ResourceId target,
    required skir.EndpointId oppositeEndpoint,
    required skir.NewCounterpartChoice choice,
  }) {
    if (choice.containing.resource != target) return null;
    final targetRecord = _resources[target];
    if (targetRecord == null) return null;
    final actual = switch (choice.prepared.recordContent.configuration) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (actual == null) return null;
    final materialized = skir.DataValue.createNamed(
      actualType: actual,
      payload: skir.DataValue.createRecord(
        fields: choice.prepared.recordContent.fields,
      ),
    );
    var embedded = choice.containing;
    final current = targetRecord.readAt(choice.containing.path);
    if (current case PortablePathValue(value: final value)
        when value.authoredItems != null) {
      final item = _nextStagedItem(choice.containing);
      embedded = skir.ValueLocation(
        resource: target,
        path: skir.ValuePath(
          segments: [
            ...choice.containing.path.segments,
            skir.PathSegment.createItem(id: item),
          ],
        ),
      );
      _appendDirectLinkItem(targetRecord, embedded, materialized);
    } else {
      final updated = targetRecord.replaceAt(
        choice.containing.path,
        materialized,
      );
      if (updated case PortablePathValue(value: final value)) {
        _resources[target] = value;
      } else {
        return null;
      }
    }
    final staged = _resources[target];
    if (staged == null) return null;
    final locations = <skir.ValueLocation>[];
    for (final binding
        in catalog
                ?.endpointBindings(staged.configuration)
                .where(
                  (binding) => binding.template.endpoint == oppositeEndpoint,
                ) ??
            const <AppliedEndpointBinding>[]) {
      for (final location
          in skir.DataValue.createRecord(fields: staged.fields).expandPattern(
            skir.ValueLocation(resource: target, path: editorRootPath),
            binding.template.relativePath,
          )) {
        if (location.path.isAtOrBelow(embedded.path)) locations.add(location);
      }
    }
    return locations.length == 1 ? locations.single : null;
  }

  skir.ItemId _nextStagedItem(skir.ValueLocation containing) {
    final prefix = "panel:new:${_intents.length}:";
    var index = 0;
    while (true) {
      final candidate = skir.ItemId(value: "$prefix$index");
      final location = skir.ValuePath(
        segments: [
          ...containing.path.segments,
          skir.PathSegment.createItem(id: candidate),
        ],
      );
      if (_resources[containing.resource]?.readAt(location)
          is PortablePathUnavailable<skir.DataValue>) {
        return candidate;
      }
      index++;
    }
  }

  void _stageLinkValue(
    skir.ValueLocation location,
    skir.EndpointId endpoint,
    skir.LinkTarget target,
  ) {
    final record = _resources[location.resource];
    if (record == null) throw StateError("The resource is absent");
    final current = record.readAt(location.path);
    final payload = skir.DataValue.createLink(
      endpoint: endpoint,
      target: target,
    );
    final actual = _concreteNamed(
      catalog?.valueTypeAt(
        record.configuration,
        location.path,
        value: skir.DataValue.createRecord(fields: record.fields),
      ),
    );
    final replacement = switch (current) {
      PortablePathValue(value: final skir.DataValue_namedWrapper value) =>
        value.withAuthoredPayload(payload),
      _ when actual != null => skir.DataValue.createNamed(
        actualType: actual,
        payload: payload,
      ),
      _ => throw StateError("The relation location has no usable link type"),
    };
    final updated = record.replaceAt(location.path, replacement);
    if (updated case PortablePathValue(value: final staged)) {
      _resources[location.resource] = staged;
      return;
    }
    _appendDirectLinkItem(record, location, replacement);
  }

  void _appendDirectLinkItem(
    skir.AuthoringRecord record,
    skir.ValueLocation location,
    skir.DataValue replacement,
  ) {
    final segments = location.path.segments.toList(growable: false);
    if (segments.isEmpty || segments.last is! skir.PathSegment_itemWrapper) {
      throw StateError("The link location is unavailable");
    }
    final item = (segments.last as skir.PathSegment_itemWrapper).value.id;
    final parent = skir.ValuePath(segments: segments.take(segments.length - 1));
    final parentLocation = skir.ValueLocation(
      resource: location.resource,
      path: parent,
    );
    final value = record.readAt(parent);
    if (value is! PortablePathValue<skir.DataValue>) {
      throw StateError("The containing collection is unavailable");
    }
    final collection = _replaceCollectionItems(
      _collectionValue(parentLocation, value.value),
      (items) => items.any((candidate) => candidate.id == item)
          ? null
          : [...items, skir.ListItem(id: item, value: replacement)],
    );
    if (collection == null) {
      throw StateError("The link item cannot be inserted");
    }
    final appended = record.replaceAt(parent, collection);
    if (appended is! PortablePathValue<skir.AuthoringRecord>) {
      throw StateError("The containing collection is unavailable");
    }
    _resources[location.resource] = appended.value;
  }

  void _stageLinkClear(skir.ValueLocation location) {
    final record = _resources[location.resource];
    if (record == null) throw StateError("The resource is absent");
    final segments = location.path.segments.toList(growable: false);
    final item = segments.lastOrNull;
    final path = item is skir.PathSegment_itemWrapper
        ? skir.ValuePath(segments: segments.take(segments.length - 1))
        : location.path;
    late final skir.DataValue replacement;
    if (item is skir.PathSegment_itemWrapper) {
      final current = record.readAt(path);
      if (current is! PortablePathValue<skir.DataValue>) {
        throw StateError("The containing collection is unavailable");
      }
      final collection = _replaceCollectionItems(
        current.value,
        (items) =>
            items.where((candidate) => candidate.id != item.value.id).toList(),
      );
      if (collection == null) {
        throw StateError("The containing value is not a collection");
      }
      replacement = collection;
    } else {
      final expected = catalog?.valueTypeAt(
        record.configuration,
        path,
        value: skir.DataValue.createRecord(fields: record.fields),
      );
      replacement = expected is skir.TypeUse_nullableWrapper
          ? skir.DataValue.null_
          : skir.DataValue.unfilled;
    }
    final updated = record.replaceAt(path, replacement);
    if (updated is! PortablePathValue<skir.AuthoringRecord>) {
      throw StateError("The link location is unavailable");
    }
    _resources[location.resource] = updated.value;
  }

  bool _projectionContainsOccurrence(
    skir.LinkProjection link,
    skir.LinkOccurrenceId occurrence,
  ) {
    final relation = catalog?.snapshot.relations
        .where((candidate) => candidate.id == link.contract)
        .firstOrNull;
    if (relation == null) return false;
    return (relation.first.id == occurrence.endpoint &&
            link.first == occurrence.location.resource &&
            link.firstLocation == occurrence.location.path) ||
        (relation.second.id == occurrence.endpoint &&
            link.second == occurrence.location.resource &&
            link.secondLocation == occurrence.location.path);
  }
}
