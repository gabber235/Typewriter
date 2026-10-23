import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Connects portable presentation behavior to one authored resource and its shared edit binding.
///
/// Display and collection projections read the current working document. Invocation
/// contexts retain the observation that produced an action, so expression reads can
/// become original expectations when the action stages a write. Preparation rechecks
/// availability after suspension and reports rejected writes as portable diagnostics.
///
/// The host owns view metadata and its disposed flag, while [RealmEditingBinding]
/// owns access to the shared edit group. Disposing this host prevents new presentation
/// work without saving, discarding, or closing that group.
final class AuthoredPresentationHost extends ChangeNotifier
    implements
        PortablePresentationHost,
        PortableCollectionMutationHost,
        PortableCollectionProjectionHost,
        PortableLinkHost,
        PortableResourcesHost {
  AuthoredPresentationHost({
    required this.resource,
    required this._source,
    required this.material,
    required this.role,
    required this.budget,
    required this.capabilities,
    this.available = true,
    this.readOnly = false,
    this.prepareValue,
    this.edit,
    this.issues,
  });

  final skir.ResourceId resource;
  AuthoringDocument _source;
  AuthoringDocument get authored => edit?.document ?? _source;
  final skir.PresentationMaterial material;
  final skir.PresentationRole role;
  final skir.EvaluationBudget budget;
  @override
  PortablePresentationCapabilities capabilities;
  bool available;
  @override
  bool readOnly;
  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?
  prepareValue;
  final RealmEditingBinding? edit;
  ResourceIssues? issues;
  var _disposed = false;

  /// Updates view metadata without replacing an active operation's host.
  void update({
    required AuthoringDocument source,
    required PortablePresentationCapabilities capabilities,
    required bool available,
    required bool readOnly,
    ResourceIssues? issues,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
    prepareValue,
  }) {
    _source = source;
    this.issues = issues;
    this.capabilities = capabilities;
    this.available = available;
    this.readOnly = readOnly;
    this.prepareValue = prepareValue;
  }

  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (!enabled ||
        readOnly ||
        context.catalogGeneration != authored.generation ||
        edit == null ||
        location(reference, context: context) == null) {
      return null;
    }
    return edit!.control;
  }

  @override
  bool get enabled => !_disposed && available;

  @override
  PortablePresentationDocument get document {
    final observation = authored;
    final record = observation.resource(resource);
    if (record == null) {
      throw StateError("The authored resource is absent");
    }
    final checked = observation.catalog;
    if (checked.snapshot.generation != observation.generation) {
      throw StateError("The authoring catalog is unavailable");
    }
    final payload = skir.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
    final schema = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        CompletePortablePresentationBinding(skir.TypeUse.wrapNamed(value)),
      skir.TypeSelection_pendingWrapper() => PartialPortablePresentationBinding(
        record.configuration,
      ),
      skir.TypeSelection_unknown() => null,
    };
    final observationIssues =
        issues ?? ResourceIssues.evaluate(document: observation);
    List<PortablePresentationDiagnostic> diagnosticsFor(skir.ResourceId id) =>
        observationIssues
            .currentFor(id)
            .map((issue) => issue.diagnostic)
            .toList();
    return PortablePresentationDocument(
      catalog: checked,
      queries: PortableExpressionQueries(
        catalog: checked,
        authored: observation,
      ),
      resourceDiagnostics: diagnosticsFor,
      root: material.layout,
      bindings: {
        presentationSubjectIdentifierBindingId: PortablePresentationBinding(
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapNamed(frameworkResourceIdUse),
          ),
          value: resource.toExpressionValue(),
        ),
        presentationSubjectAppearanceBindingId: PortablePresentationBinding(
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapNamed(canonicalReadModels.resourceAppearanceUse),
          ),
          value: checked.appearanceOf(record).toExpressionValue(),
        ),
        if (schema != null)
          configuredValueBindingId: PortablePresentationBinding(
            schema: schema,
            value: value,
            editable: true,
            location: skir.ValueLocation(
              resource: resource,
              path: skir.ValuePath(segments: const []),
            ),
          ),
      },
      budget: budget,
      diagnosticFallback: PortableDiagnosticFallback.resource,
      diagnostics: diagnosticsFor(resource),
      role: role,
      material: material,
      activePresentations: {material.provider},
    );
  }

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    return context.read(reference, authored.generation);
  }

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    return context.location(reference, authored.generation);
  }

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    final target = location(reference, context: context);
    final observation = context.queries?.authored ?? authored;
    final checked = context.queries?.catalog ?? authored.catalog;
    final record = target == null
        ? null
        : observation.resource(target.resource);
    return record == null
        ? null
        : checked.valueTypeAt(
            record.configuration,
            target!.path,
            value: _recordValue(record),
          );
  }

  skir.DataValue _recordValue(skir.AuthoringRecord record) {
    final payload = skir.DataValue.createRecord(fields: record.fields);
    return switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    if (!enabled || readOnly) {
      return _reject("This presentation is read only");
    }
    final target = location(reference, context: context);
    if (target == null) {
      return _reject("The presentation binding is unavailable", target: target);
    }
    final binding = edit;
    if (binding == null) {
      return _reject("This presentation is read only", target: target);
    }
    final currentRecord = authored.resource(target.resource);
    if (!context.isCurrent(
      reference,
      authored.generation,
      currentRecord == null
          ? null
          : _recordValue(currentRecord).editorValueAt(target.path),
    )) {
      return _reject(
        "The presentation value changed before this write",
        target: target,
      );
    }
    final result = await binding.prepare(
      label: "Edit value",
      from: _observation(context),
      apply: (operation) async {
        operation.observeExpressionReads(context.expressionReads);
        if (prepareValue case final prepare?) {
          await operation.setWithInitialization(target, value, prepare);
        } else {
          operation.set(target, value);
        }
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
      },
    );
    if (result case EditStageRejected(:final message)) {
      return _reject(message, target: target);
    }
    return const PortablePresentationWriteApplied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async {
    if (editorAction is skir.EditorAction_navigateWrapper ||
        editorAction is skir.EditorAction_authoringWrapper ||
        editorAction is skir.EditorAction_createWrapper) {
      if (!enabled ||
          context.catalogGeneration != authored.generation ||
          editorAction is! skir.EditorAction_navigateWrapper &&
              (readOnly || edit == null)) {
        return _reject("This resource action is unavailable");
      }
      final invoke = capabilities.resourceAction;
      return invoke == null
          ? _reject("Resource actions are unavailable")
          : await invoke(editorAction, context);
    }
    if (!enabled || readOnly || edit == null) {
      return _reject("This presentation is read only");
    }
    if (context.catalogGeneration != authored.generation) {
      return _reject("The editor catalog changed");
    }
    try {
      return switch (editorAction) {
        skir.EditorAction_localWrapper(:final value) => await _executeLocal(
          value,
          context,
        ),
        skir.EditorAction_realmWrapper(:final value) => await _executeRealm(
          value,
          context,
        ),
        skir.EditorAction_navigateWrapper() ||
        skir.EditorAction_authoringWrapper() ||
        skir.EditorAction_createWrapper() => _reject(
          "Resource actions are unavailable",
        ),
        skir.EditorAction_unknown() => _reject(
          "This editor action is unavailable",
        ),
      };
    } on Object catch (error) {
      return _reject("The editor action did not complete: $error");
    }
  }

  @override
  Future<PortablePresentationWriteResult> addCollectionItem(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) async {
    final target = location(reference, context: context);
    final current = read(reference, context: context);
    final items = switch (current) {
      final value when value == skir.DataValue.unfilled => <skir.ListItem>[],
      _ => current?.authoredItems?.toList(),
    };
    if (target == null || items == null || edit == null) {
      return _reject("The collection binding is unavailable", target: target);
    }
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    final itemReference = skir.BindingRef(
      bindingId: reference.bindingId,
      path: skir.ValuePath(
        segments: [
          ...reference.path.segments,
          skir.PathSegment.createItem(id: item),
        ],
      ),
    );
    final expected = expectedType(itemReference, context: context);
    var unwrapped = expected;
    while (unwrapped is skir.TypeUse_nullableWrapper) {
      unwrapped = unwrapped.value.value;
    }
    final named = switch (unwrapped) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    final representation = named == null
        ? null
        : authored.catalog
              .published(named.definition)
              ?.definition
              .representation;
    final requiresPreparation = switch (representation) {
      skir.RepresentationTemplate_recordWrapper(:final value) =>
        !value.abstract_,
      _ => false,
    };
    if (!requiresPreparation) {
      return _stage("Add collection item", (operation) {
        operation.insert(
          target,
          items.lastOrNull?.id,
          skir.ListItem(id: item, value: authored.defaultValue(expected)),
        );
      }, target: target);
    }
    final prepare = prepareValue;
    if (named == null || prepare == null) {
      return _reject("The collection item cannot be prepared", target: target);
    }
    final selection = skir.TypeSelection.wrapComplete(named);
    final request = skir.ValuePreparationRequest(
      catalog: authored.generation,
      target: skir.PreparationTarget.wrapRecord(selection),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
    );
    final result = await edit!.prepare(
      label: "Add collection item",
      from: authored,
      apply: (operation) async {
        operation.expect(target);
        final prepared = await prepare(request);
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        operation.insertPrepared(
          target,
          items.lastOrNull?.id,
          item,
          request,
          prepared,
        );
      },
    );
    if (result case EditStageRejected(:final message)) {
      return _reject(message, target: target);
    }
    return const PortablePresentationWriteApplied();
  }

  @override
  PortableCollectionProjection projectCollection(
    String sourceId, {
    required skir.PresentationMaterial material,
    required PortableInvocationContext context,
  }) {
    final definition = material.dependencies.collections
        .where((candidate) => candidate.sourceId == sourceId)
        .firstOrNull;
    final queries = context.queries;
    final observation = queries?.authored;
    final checked = queries?.catalog;
    if (definition == null ||
        observation == null ||
        checked == null ||
        context.catalogGeneration != observation.generation) {
      return PortableCollectionProjection(
        definition: definition,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );
    }
    final projected = definition.projection;
    if (projected == null) {
      return PortableCollectionProjection(
        definition: definition,
        rows: const [],
        problem: "The presentation collection source is invalid",
      );
    }
    final rows = <PortableCollectionRowProjection>[];
    final entries = observation.resources.entries.toList()
      ..sort((left, right) => left.key.value.compareTo(right.key.value));
    for (final entry in entries) {
      final record = entry.value;
      if (!checked.matchesNamedTemplate(record.configuration, projected.root)) {
        continue;
      }
      final row = _projectionRow(definition, projected, record, checked);
      if (row == null) {
        return PortableCollectionProjection(
          definition: definition,
          rows: const [],
          problem: "A presentation collection row could not be projected",
        );
      }
      final bindings = {
        ...context.bindings,
        definition.rowBinding.id: PortableExpressionBinding(value: row),
        projected.resourceBinding.id: entry.key.toExpressionBinding(),
      };
      final key = PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
        catalog: checked,
        queries: queries,
      ).evaluate(definition.key);
      final selectable = PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
        catalog: checked,
        queries: queries,
      ).evaluate(definition.selectability);
      if (key is! PortableExpressionAvailable) {
        return PortableCollectionProjection(
          definition: definition,
          rows: const [],
          problem: "A presentation collection key is unavailable",
        );
      }
      final selected = switch (selectable) {
        PortableExpressionAvailable(
          value: skir.DataValue_booleanWrapper(:final value),
        ) =>
          value,
        _ => false,
      };
      rows.add(
        PortableCollectionRowProjection(
          resource: entry.key,
          configuration: record.configuration,
          label: checked.appearanceOf(record).label,
          row: row,
          key: key.value,
          canonicalKey: canonicalAuthoredValue(key.value),
          selectable: selected,
        ),
      );
    }
    return PortableCollectionProjection(definition: definition, rows: rows);
  }

  @override
  PortableResourceProjection? projectResource(
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

  @override
  PortableLinkPlanResult planLink(
    skir.ValueLocation source, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != authored.generation) {
      return const PortableLinkPlanUnavailable("The editor catalog changed");
    }
    return authored.linkPlans(catalog: authored.catalog, source: source);
  }

  @override
  bool get canPrepareCounterpart => prepareValue != null;

  @override
  Future<PortablePresentationWriteResult> connectLink({
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    required PortableLinkCounterpartRequest counterpart,
    required PortableInvocationContext context,
  }) async {
    final binding = edit;
    if (!enabled || readOnly || binding == null) {
      return _reject("This presentation is read only");
    }
    if (context.catalogGeneration != authored.generation) {
      return _reject("The editor catalog changed");
    }
    final result = await binding.prepare(
      label: "Change link",
      from: authored,
      apply: (operation) async {
        operation.expect(plan.source.id.location);
        final choice = await preparePortableLinkCounterpart(
          generation: operation.generation,
          counterpart: counterpart,
          prepareValue: prepareValue,
        );
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        operation.applyResolvedReference(
          operation.resolveReference(
            catalog: authored.catalog,
            plan: plan,
            target: target,
            counterpart: choice,
            collection: switch (counterpart) {
              PortableCollectionCounterpart(:final containing) => containing,
              _ => null,
            },
          ),
        );
      },
    );
    return switch (result) {
      EditStageRejected(:final message) => _reject(message),
      _ => const PortablePresentationWriteApplied(),
    };
  }

  @override
  PortablePresentationWriteResult disconnectLink(
    skir.LinkOccurrence occurrence, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != authored.generation) {
      return _reject("The editor catalog changed");
    }
    return _stage("Clear link", (operation) {
      operation.disconnect(occurrence);
    });
  }

  /// Members of a resources binding: the link targets of the bound field, in
  /// link order. Links come from the document's link projections at or below
  /// the bound location, ordered by their item in the field's value.
  @override
  PortableResourcesProjection projectResources(
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

  @override
  PortablePresentationWriteResult moveGraphNodes(
    List<PortableGraphPositionChange> changes, {
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Move graph nodes", (operation) {
    for (final change in changes) {
      operation.moveGraphPlacement(change.resource, change.x, change.y);
    }
  });

  @override
  PortablePresentationWriteResult resizeGraphNodes(
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

  @override
  PortablePresentationWriteResult moveTimelineElements(
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

  @override
  PortablePresentationWriteResult removeMember(
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

  skir.DataValue? _projectionRow(
    skir.PresentationCollectionDefinition definition,
    skir.PresentationCollectionProjection projection,
    skir.AuthoringRecord record,
    CheckedEditorCatalog catalog,
  ) {
    skir.DataValue? row;
    for (final field in projection.fields) {
      final source = switch (field.source) {
        skir.PresentationCollectionProjectionValue_contentWrapper(
          :final value,
        ) =>
          switch (record.readAt(value)) {
            PortablePathValue(:final value) => value,
            PortablePathUnavailable() => skir.DataValue.unfilled,
          },
        skir.PresentationCollectionProjectionValue_literalWrapper(
          :final value,
        ) =>
          value,
        _ => null,
      };
      if (source == null) return null;
      if (field.target.segments.isEmpty) {
        if (row != null || projection.fields.length != 1) return null;
        row = source;
        continue;
      }
      row = _writeProjectionValue(
        row ?? skir.DataValue.createRecord(fields: const []),
        field.target.segments.toList(growable: false),
        source,
      );
      if (row == null) return null;
    }
    row ??= skir.DataValue.createRecord(fields: const []);
    if (row == skir.DataValue.unfilled) return row;
    final applied = catalog.applyTemplate(
      definition.rowBinding.type,
      record.configuration,
    );
    return applied == null
        ? row
        : _completeProjectedValue(row, applied, catalog);
  }

  skir.DataValue? _completeProjectedValue(
    skir.DataValue authoredValue,
    skir.TypeUse expected,
    CheckedEditorCatalog catalog,
  ) {
    if (authoredValue == skir.DataValue.unfilled) return authoredValue;
    return switch (expected) {
      skir.TypeUse_nullableWrapper(value: final nullable) =>
        authoredValue == skir.DataValue.null_
            ? authoredValue
            : _completeProjectedValue(authoredValue, nullable.value, catalog),
      skir.TypeUse_namedWrapper(value: final named) =>
        _completeProjectedNamedValue(authoredValue, named, catalog),
      _ => authoredValue,
    };
  }

  skir.DataValue? _completeProjectedNamedValue(
    skir.DataValue authoredValue,
    skir.NamedTypeUse expected,
    CheckedEditorCatalog catalog,
  ) {
    final payload = switch (authoredValue) {
      skir.DataValue_namedWrapper(:final value)
          when value.actualType == expected =>
        value.payload,
      skir.DataValue_namedWrapper() => null,
      _ => authoredValue,
    };
    if (payload == null) return null;
    final representation = catalog
        .published(expected.definition)
        ?.definition
        .representation;
    if (representation is! skir.RepresentationTemplate_recordWrapper) {
      return skir.DataValue.createNamed(actualType: expected, payload: payload);
    }
    final projected = payload.authoredRecord;
    if (projected == null) return null;
    final fields = catalog.fields(skir.TypeSelection.wrapComplete(expected));
    final expectedNames = {for (final field in fields) field.template.key};
    if (projected.fields.any((field) => !expectedNames.contains(field.name))) {
      return null;
    }
    final completed = <skir.FieldValue>[];
    for (final field in fields) {
      final existing = projected.fields
          .where((candidate) => candidate.name == field.template.key)
          .firstOrNull;
      final fieldValue = existing?.value ?? skir.DataValue.unfilled;
      final normalized = field.type == null
          ? fieldValue
          : _completeProjectedValue(fieldValue, field.type!, catalog);
      if (normalized == null) return null;
      completed.add(
        skir.FieldValue(name: field.template.key, value: normalized),
      );
    }
    return skir.DataValue.createNamed(
      actualType: expected,
      payload: skir.DataValue.createRecord(fields: completed),
    );
  }

  skir.DataValue? _writeProjectionValue(
    skir.DataValue current,
    List<skir.PathSegment> segments,
    skir.DataValue value,
  ) {
    if (segments.isEmpty) return value;
    final field = switch (segments.first) {
      skir.PathSegment_fieldWrapper(:final value) => value.name,
      _ => null,
    };
    if (field == null) return null;
    final record = current.authoredPayload.authoredRecord;
    if (record == null) return null;
    final fields = <skir.FieldValue>[...record.fields];
    final index = fields.indexWhere((candidate) => candidate.name == field);
    final nested = _writeProjectionValue(
      index < 0
          ? skir.DataValue.createRecord(fields: const [])
          : fields[index].value,
      segments.sublist(1),
      value,
    );
    if (nested == null) return null;
    final replacement = skir.FieldValue(name: field, value: nested);
    if (index < 0) {
      fields.add(replacement);
    } else {
      fields[index] = replacement;
    }
    return current.withAuthoredPayload(
      skir.DataValue.createRecord(fields: fields),
    );
  }

  @override
  Future<PortablePresentationWriteResult> addMapRow(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) async {
    final target = location(reference, context: context);
    final payload = read(reference, context: context)?.authoredPayload;
    final rows = switch (payload) {
      skir.DataValue_mapValueWrapper(:final value) => value.rows.toList(),
      final value when value == skir.DataValue.unfilled => <skir.MapRow>[],
      _ => null,
    };
    if (target == null || rows == null) {
      return _reject("The map binding is unavailable", target: target);
    }
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    skir.TypeUse? branchType(skir.PathSegment branch) => expectedType(
      skir.BindingRef(
        bindingId: reference.bindingId,
        path: skir.ValuePath(
          segments: [
            ...reference.path.segments,
            skir.PathSegment.createItem(id: item),
            branch,
          ],
        ),
      ),
      context: context,
    );
    final binding = edit;
    if (!enabled || readOnly || binding == null) {
      return _reject("This presentation is read only", target: target);
    }
    final keyType = branchType(skir.PathSegment.mapKey);
    final valueType = branchType(skir.PathSegment.mapValue);
    final observation = authored;
    Future<(skir.ValuePreparationRequest, skir.PreparedValue)?> prepareBranch(
      skir.TypeUse? type,
    ) async {
      // Nullable entries start at null, matching local shape initialization.
      if (type is! skir.TypeUse_namedWrapper) return null;
      final representation = observation.catalog
          .published(type.value.definition)
          ?.definition
          .representation;
      if (representation is! skir.RepresentationTemplate_recordWrapper ||
          representation.value.abstract_) {
        return null;
      }
      final prepare = prepareValue;
      if (prepare == null) {
        throw StateError("The map branch cannot be prepared");
      }
      final request = skir.ValuePreparationRequest(
        catalog: observation.generation,
        target: skir.PreparationTarget.wrapRecord(
          skir.TypeSelection.wrapComplete(type.value),
        ),
        suppliedValue: skir.DataValue.createRecord(fields: const []),
      );
      final prepared = await prepare(request);
      if (_disposed || !enabled || readOnly) {
        throw StateError("The presentation closed during preparation");
      }
      return (request, prepared);
    }

    final result = await binding.prepare(
      label: "Add map row",
      from: observation,
      apply: (operation) async {
        final current = operation.expect(target);
        if (current is! PortablePathValue<skir.DataValue> ||
            current.value.authoredPayload != payload) {
          throw StateError("The map changed before this edit");
        }
        final key = await prepareBranch(keyType);
        final value = await prepareBranch(valueType);
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        operation.replaceMap(target, [
          ...rows,
          skir.MapRow(
            id: item,
            key: observation.defaultValue(keyType),
            value: observation.defaultValue(valueType),
          ),
        ]);
        for (final (branch, prepared) in [
          (skir.PathSegment.mapKey, key),
          (skir.PathSegment.mapValue, value),
        ]) {
          if (prepared == null) continue;
          operation.applyPreparedRecord(
            skir.ValueLocation(
              resource: target.resource,
              path: skir.ValuePath(
                segments: [
                  ...target.path.segments,
                  skir.PathSegment.createItem(id: item),
                  branch,
                ],
              ),
            ),
            prepared.$1,
            prepared.$2,
          );
        }
      },
    );
    return switch (result) {
      EditStageRejected(:final message) => _reject(message, target: target),
      _ => const PortablePresentationWriteApplied(),
    };
  }

  Future<PortablePresentationWriteResult> _executeLocal(
    skir.LocalEditorAction local,
    PortableInvocationContext context,
  ) async {
    switch (local) {
      case skir.LocalEditorAction_setValueWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        return replacement == null
            ? _reject(
                "The action value is unavailable",
                target: location(value.target, context: context),
              )
            : _stage(
                "Edit value",
                (operation) {
                  final target = location(value.target, context: context);
                  if (target == null) {
                    throw StateError("The action target is unavailable");
                  }
                  operation
                    ..observeExpressionReads(replacement.reads)
                    ..set(target, replacement.value);
                },
                target: location(value.target, context: context),
                from: _observation(context),
              );
      case skir.LocalEditorAction_insertListItemWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        if (replacement == null) {
          return _reject(
            "The action value is unavailable",
            target: location(value.target, context: context),
          );
        }
        return _editList(
          value.target,
          context,
          reads: replacement.reads,
          apply: (target, operation) => operation.insert(
            target,
            value.after,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          ),
        );
      case skir.LocalEditorAction_appendListItemWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        final items = read(value.target, context: context)?.authoredItems;
        if (replacement == null || items == null) {
          return _reject(
            "The action target is not a collection",
            target: location(value.target, context: context),
          );
        }
        return _editList(
          value.target,
          context,
          reads: replacement.reads,
          apply: (target, operation) => operation.insert(
            target,
            items.lastOrNull?.id,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: replacement.value,
            ),
          ),
        );
      case skir.LocalEditorAction_removeListItemWrapper(:final value):
        return _editList(
          value.target,
          context,
          apply: (target, operation) => operation.remove(target, value.item),
        );
      case skir.LocalEditorAction_duplicateListItemWrapper(:final value):
        final target = location(value.target, context: context);
        final source = read(value.target, context: context)?.authoredItems
            ?.where((candidate) => candidate.id == value.item)
            .firstOrNull;
        if (target == null || source == null) {
          return _reject(
            "The collection item is no longer available",
            target: location(value.target, context: context),
          );
        }
        return _editList(
          value.target,
          context,
          reads: [
            skir.ValueLocation(
              resource: target.resource,
              path: skir.ValuePath(
                segments: [
                  ...target.path.segments,
                  skir.PathSegment.createItem(id: source.id),
                ],
              ),
            ),
          ],
          apply: (location, operation) => operation.insert(
            location,
            source.id,
            skir.ListItem(
              id: skir.ItemId(value: const Uuid().v4()),
              value: source.value,
            ),
          ),
        );
      case skir.LocalEditorAction_moveListItemWrapper(:final value):
        return _editList(
          value.target,
          context,
          apply: (target, operation) =>
              operation.move(target, value.item, value.after),
        );
      case skir.LocalEditorAction_insertMapRowWrapper(:final value):
        final key = _evaluate(value.key, context);
        final replacement = _evaluate(value.value, context);
        if (key == null || replacement == null) {
          return _reject(
            "The action value is unavailable",
            target: location(value.target, context: context),
          );
        }
        return _editMap(
          value.target,
          context,
          reads: [...key.reads, ...replacement.reads],
          update: (rows) => [
            ...rows,
            skir.MapRow(
              id: skir.ItemId(value: const Uuid().v4()),
              key: key.value,
              value: replacement.value,
            ),
          ],
        );
      case skir.LocalEditorAction_updateMapRowWrapper(:final value):
        final key = _evaluate(value.key, context);
        final replacement = _evaluate(value.value, context);
        if (key == null || replacement == null) {
          return _reject(
            "The action value is unavailable",
            target: location(value.target, context: context),
          );
        }
        return _editMap(
          value.target,
          context,
          requiredRow: value.row,
          reads: [...key.reads, ...replacement.reads],
          update: (rows) => [
            for (final row in rows)
              if (row.id == value.row)
                skir.MapRow(
                  id: row.id,
                  key: key.value,
                  value: replacement.value,
                )
              else
                row,
          ],
        );
      case skir.LocalEditorAction_removeMapRowWrapper(:final value):
        return _editMap(
          value.target,
          context,
          requiredRow: value.row,
          update: (rows) => rows
              .where((candidate) => candidate.id != value.row)
              .toList(growable: false),
        );
      case skir.LocalEditorAction_chooseFormWrapper(:final value):
        return _chooseForm(value, context);
      case skir.LocalEditorAction_unknown():
        return _reject("This local editor action is unavailable");
    }
  }

  Future<PortablePresentationWriteResult> _executeRealm(
    skir.RealmEditorAction realm,
    PortableInvocationContext context,
  ) async {
    await executePortableRealmAction(
      realm,
      evaluate: (expression) {
        final payload = _evaluate(expression, context);
        if (payload == null) {
          throw StateError("The Realm action payload is unavailable");
        }
        return payload.value;
      },
      invokeCommand: capabilities.invokeCommand,
      reload: capabilities.reload,
    );
    return const PortablePresentationWriteApplied();
  }

  _AuthoredActionValue? _evaluate(
    skir.ExpressionNode expression,
    PortableInvocationContext context,
  ) => switch (PortableExpressionEvaluator.located(
    context.bindings,
    budget: budget,
    catalog: context.queries?.catalog ?? authored.catalog,
    queries: context.queries,
  ).evaluate(expression)) {
    PortableExpressionAvailable(:final value, :final reads) =>
      _AuthoredActionValue(value, reads),
    PortableExpressionUnavailable() || PortableExpressionFailed() => null,
  };

  PortablePresentationWriteResult _editList(
    skir.BindingRef reference,
    PortableInvocationContext context, {
    required PortablePathResult<skir.AuthoringRecord> Function(
      skir.ValueLocation target,
      PortableAuthoringEdit operation,
    )
    apply,
    Iterable<skir.ValueLocation> reads = const [],
  }) {
    final target = location(reference, context: context);
    if (target == null) {
      return _reject("The action target is unavailable", target: target);
    }
    return _stage(
      "Edit collection",
      (operation) {
        operation.observeExpressionReads(reads);
        apply(target, operation);
      },
      target: target,
      from: _observation(context),
    );
  }

  PortablePresentationWriteResult _editMap(
    skir.BindingRef reference,
    PortableInvocationContext context, {
    required List<skir.MapRow> Function(List<skir.MapRow> rows) update,
    skir.ItemId? requiredRow,
    Iterable<skir.ValueLocation> reads = const [],
  }) {
    final target = location(reference, context: context);
    final current = read(reference, context: context)?.authoredPayload;
    if (target == null || current is! skir.DataValue_mapValueWrapper) {
      return _reject("The action target is not a map", target: target);
    }
    final rows = current.value.rows.toList();
    if (requiredRow != null && rows.every((row) => row.id != requiredRow)) {
      return _reject("The map row is no longer available", target: target);
    }
    return _stage(
      "Edit map",
      (operation) {
        operation.observeExpressionReads(reads);
        final latest = operation.expect(target);
        if (latest is! PortablePathValue<skir.DataValue> ||
            latest.value.authoredPayload != current) {
          throw StateError("The map changed before this action");
        }
        operation.replaceMap(target, update(rows));
      },
      target: target,
      from: _observation(context),
    );
  }

  Future<PortablePresentationWriteResult> _chooseForm(
    skir.ChooseFormAction choice,
    PortableInvocationContext context,
  ) async {
    final target = location(choice.target, context: context);
    final prepare = prepareValue;
    final named = switch (choice.type) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    if (target == null || prepare == null || named == null) {
      return _reject("The selected form cannot be prepared", target: target);
    }
    final request = skir.ValuePreparationRequest(
      catalog: authored.generation,
      target: skir.PreparationTarget.wrapRecord(
        skir.TypeSelection.wrapComplete(named),
      ),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
    );
    final binding = edit!;
    final result = await binding.prepare(
      label: "Choose form",
      from: authored,
      apply: (operation) async {
        operation.expect(target);
        final prepared = await prepare(request);
        operation.applyPreparedRecord(target, request, prepared);
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
      },
    );
    if (result case EditStageRejected(:final message)) {
      return _reject(message, target: target);
    }
    return const PortablePresentationWriteApplied();
  }

  /// The current operation owns the write, but expectations belong to the read observation.
  AuthoringDocument _observation(PortableInvocationContext context) =>
      switch (context.queries?.authored) {
        final AuthoringDocument document => document,
        null => authored,
        _ => throw StateError(
          "The authored query observation cannot own edit expectations",
        ),
      };

  PortablePresentationWriteResult _stage(
    String label,
    void Function(AuthoringEdit operation) apply, {
    bool independent = false,
    skir.ValueLocation? target,
    AuthoringDocument? from,
  }) {
    final binding = edit;
    if (!enabled || readOnly || binding == null) {
      return _reject("This presentation is read only", target: target);
    }
    final result = independent
        ? binding.workspace.edit(
            label: label,
            apply: apply,
            from: from ?? authored,
          )
        : binding.edit(label: label, apply: apply, from: from ?? authored);
    return switch (result) {
      EditStageRejected(:final message) => _reject(message, target: target),
      _ => const PortablePresentationWriteApplied(),
    };
  }

  PortablePresentationWriteResult _reject(
    String message, {
    skir.ValueLocation? target,
  }) => PortablePresentationWriteResult.rejected([
    PortablePresentationDiagnostic(
      code: "edit_rejected",
      message: message,
      severity: skir.DiagnosticSeverity.error,
      targets: target == null
          ? const []
          : [PortableDiagnosticTarget.value(target)],
    ),
  ]);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

final class _AuthoredActionValue {
  const _AuthoredActionValue(this.value, this.reads);

  final skir.DataValue value;
  final List<skir.ValueLocation> reads;
}
