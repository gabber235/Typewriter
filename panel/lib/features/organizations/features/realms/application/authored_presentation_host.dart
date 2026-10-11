import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredPresentationHost extends ChangeNotifier
    implements
        PortablePresentationHost,
        PortableCollectionMutationHost,
        PortableCollectionProjectionHost,
        PortableLinkHost,
        PortablePageHost {
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
    this.reportStatus,
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
  final AuthoringBinding? edit;
  ValueChanged<String>? reportStatus;
  var _disposed = false;

  /// Updates view metadata without replacing an active operation's host.
  void update({
    required AuthoringDocument source,
    required PortablePresentationCapabilities capabilities,
    required bool available,
    required bool readOnly,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
    prepareValue,
    ValueChanged<String>? reportStatus,
  }) {
    _source = source;
    this.capabilities = capabilities;
    this.available = available;
    this.readOnly = readOnly;
    this.prepareValue = prepareValue;
    this.reportStatus = reportStatus;
  }

  @override
  bool get enabled => !_disposed && available;

  @override
  PortablePresentationDocument get document {
    final record = authored.resource(resource);
    if (record == null) {
      throw StateError("The authored resource is absent");
    }
    final checked = authored.catalog;
    if (checked.snapshot.generation != authored.generation) {
      throw StateError("The authoring catalog is unavailable");
    }
    final payload = skir.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
    return PortablePresentationDocument(
      catalog: checked,
      root: material.layout,
      bindings: {
        presentationSubjectIdentifierBindingId: PortablePresentationBinding(
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          ),
          value: skir.DataValue.wrapStringValue(resource.value),
        ),
        configuredValueBindingId: PortablePresentationBinding(
          schema: switch (record.configuration) {
            skir.TypeSelection_completeWrapper(:final value) =>
              CompletePortablePresentationBinding(
                skir.TypeUse.wrapNamed(value),
              ),
            _ => PartialPortablePresentationBinding(record.configuration),
          },
          value: value,
          editable: true,
          location: skir.ValueLocation(
            resource: resource,
            path: skir.ValuePath(segments: const []),
          ),
        ),
      },
      budget: budget,
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
    if (context.catalogGeneration != authored.generation) return null;
    final exposed = context.bindings[reference.bindingId];
    if (exposed == null) return null;
    if (reference.path.segments.isEmpty) return exposed.value;
    return switch (exposed.value.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != authored.generation) return null;
    final base = context.bindings[reference.bindingId]?.location;
    if (base == null) return null;
    return skir.ValueLocation(
      resource: base.resource,
      path: skir.ValuePath(
        segments: [...base.path.segments, ...reference.path.segments],
      ),
    );
  }

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    final target = location(reference, context: context);
    final record = target == null ? null : authored.resource(target.resource);
    return record == null
        ? null
        : authored.catalog.valueTypeAt(
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
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final target = location(reference, context: context);
    if (target == null) {
      return const PortablePresentationWriteRejected(
        "The presentation binding is unavailable",
      );
    }
    final binding = edit;
    if (binding == null) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final previousFindingCount = authored.initializationFindings.length;
    final result = await binding.prepare(
      label: "Edit value",
      from: authored,
      apply: (operation) async {
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
    if (result case AuthoringEditRejected(:final message)) {
      return PortablePresentationWriteRejected(message);
    }
    final findings = authored.initializationFindings.skip(previousFindingCount);
    if (!_disposed && findings.isNotEmpty) {
      reportStatus?.call(
        findings.map(formatPortableInitializationDiagnostic).join("\n"),
      );
    }
    return const PortablePresentationWriteApplied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async {
    if (!enabled || readOnly || edit == null) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    if (context.catalogGeneration != authored.generation) {
      return const PortablePresentationWriteRejected(
        "The editor catalog changed",
      );
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
        skir.EditorAction_unknown() => const PortablePresentationWriteRejected(
          "This editor action is unavailable",
        ),
      };
    } on Object catch (error) {
      return PortablePresentationWriteRejected(
        "The editor action did not complete: $error",
      );
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
      return const PortablePresentationWriteRejected(
        "The collection binding is unavailable",
      );
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
      });
    }
    final prepare = prepareValue;
    if (named == null || prepare == null) {
      return const PortablePresentationWriteRejected(
        "The collection item cannot be prepared",
      );
    }
    final selection = skir.TypeSelection.wrapComplete(named);
    final identity = sha256
        .convert(
          utf8.encode(
            "${authored.generation.value}\u0000${target.resource.value}\u0000${target.path}\u0000$selection",
          ),
        )
        .toString();
    final request = skir.ValuePreparationRequest(
      id: skir.InitializationRequestId(value: "panel:item:$identity"),
      catalog: authored.generation,
      target: skir.PreparationTarget.wrapRecord(selection),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
      intentHash: identity,
    );
    final previousFindingCount = authored.initializationFindings.length;
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
    if (result case AuthoringEditRejected(:final message)) {
      return PortablePresentationWriteRejected(message);
    }
    final findings = authored.initializationFindings.skip(previousFindingCount);
    if (findings.isNotEmpty) {
      reportStatus?.call(
        findings.map(formatPortableInitializationDiagnostic).join("\n"),
      );
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
    if (definition == null ||
        context.catalogGeneration != authored.generation) {
      return PortableCollectionProjection(
        definition: definition,
        rows: const [],
        problem: "The presentation collection is unavailable",
      );
    }
    final projected = definition.projection;
    final resources = definition.resources;
    if ((projected == null) == (resources == null)) {
      return PortableCollectionProjection(
        definition: definition,
        rows: const [],
        problem: "The presentation collection source is invalid",
      );
    }
    final rows = <PortableCollectionRowProjection>[];
    final entries = authored.resources.entries.toList()
      ..sort((left, right) => left.key.value.compareTo(right.key.value));
    for (final entry in entries) {
      final record = entry.value;
      final eligible = resources != null
          ? authored.catalog
                .nominalDefinitions(record.configuration)
                .contains(resources.root)
          : authored.catalog.matchesNamedTemplate(
              record.configuration,
              projected!.root,
            );
      if (!eligible) continue;
      final row = resources != null
          ? _resourceRow(record)
          : _projectionRow(definition, projected!, record);
      if (row == null) {
        return PortableCollectionProjection(
          definition: definition,
          rows: const [],
          problem: "A presentation collection row could not be projected",
        );
      }
      final resourceBinding =
          resources?.resourceBindingId ?? projected!.resourceBindingId;
      final bindings = {
        ...context.bindings,
        definition.rowBindingId: PortableExpressionBinding(value: row),
        resourceBinding: PortableExpressionBinding(
          value: skir.DataValue.wrapStringValue(entry.key.value),
        ),
      };
      final evaluator = PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
      );
      final key = evaluator.evaluate(definition.key);
      final selectable = evaluator.evaluate(definition.selectability);
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
          label: _resourceLabel(record) ?? entry.key.value,
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
    if (context.catalogGeneration != authored.generation) return null;
    final record = authored.resource(resource);
    if (record == null) return null;
    return PortableResourceProjection(
      resource: resource,
      configuration: record.configuration,
      label: _resourceLabel(record) ?? resource.value,
      value: _resourceRow(record),
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
    return portableLinkPlans(
      draft: authored,
      catalog: authored.catalog,
      source: source,
    );
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
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    if (context.catalogGeneration != authored.generation) {
      return const PortablePresentationWriteRejected(
        "The editor catalog changed",
      );
    }
    final preparation = switch (counterpart) {
      PortableCreatedCounterpart(:final slot) => _counterpartPreparation(
        plan.source.id.location,
        target.resource,
        slot,
      ),
      _ => null,
    };
    final result = await binding.prepare(
      label: "Change link",
      from: authored,
      apply: (operation) async {
        operation.expect(plan.source.id.location);
        final choice = switch (counterpart) {
          PortableAutomaticCounterpart() => null,
          PortableExistingCounterpart(:final occurrence) =>
            skir.CounterpartChoice.wrapExisting(occurrence),
          PortableCreatedCounterpart(:final slot) =>
            skir.CounterpartChoice.createNew(
              containing: slot.containing,
              prepared: await preparation!(),
            ),
        };
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        operation.connect(plan.source, target.resource, counterpart: choice);
      },
    );
    return switch (result) {
      AuthoringEditRejected(:final message) =>
        PortablePresentationWriteRejected(message),
      _ => const PortablePresentationWriteApplied(),
    };
  }

  Future<skir.PreparedValue> Function() _counterpartPreparation(
    skir.ValueLocation source,
    skir.ResourceId target,
    PortableNewCounterpartChoice slot,
  ) {
    final prepare = prepareValue;
    if (prepare == null) {
      throw StateError("Creation preparation is unavailable");
    }
    final generation = authored.generation;
    final content = [
      generation.value,
      source.resource.value,
      source.path.toString(),
      target.value,
      slot.containing.resource.value,
      slot.containing.path.toString(),
      slot.selection.toString(),
    ].join("\u0000");
    final identity = sha256.convert(utf8.encode(content)).toString();
    final request = skir.ValuePreparationRequest(
      id: skir.InitializationRequestId(value: "panel:link:$identity"),
      catalog: generation,
      target: skir.PreparationTarget.wrapRecord(slot.selection),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
      intentHash: identity,
    );
    return () => prepare(request);
  }

  @override
  PortablePresentationWriteResult disconnectLink(
    skir.LinkOccurrence occurrence, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != authored.generation) {
      return const PortablePresentationWriteRejected(
        "The editor catalog changed",
      );
    }
    return _stage("Clear link", (operation) {
      operation.disconnect(occurrence);
    });
  }

  @override
  PortablePageProjection projectPage(
    skir.BindingRef source, {
    required PortableInvocationContext context,
  }) {
    final location = this.location(source, context: context);
    if (location == null) {
      return PortablePageProjection(
        entries: [],
        edges: [],
        timeline: {},
        problem: "The page elements binding is unavailable",
      );
    }
    final relations = {
      for (final relation in authored.catalog.snapshot.relations)
        relation.id: relation,
    };
    final entries = <PortablePageEntryProjection>[];
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
      entries.add(
        PortablePageEntryProjection(
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
            target: skir.LinkTarget(resource: target, opposite: opposite),
          ),
          resourceProjection: resource,
          graph: _graphPlacement(record.authoredField("placement")),
        ),
      );
    }
    final ids = entries.map((entry) => entry.resource).toSet();
    final edges = <PortablePageEdgeProjection>[];
    for (final link in authored.links) {
      if (!ids.contains(link.first) || !ids.contains(link.second)) continue;
      edges.add(
        PortablePageEdgeProjection(
          id: _linkOccurrenceKey(link, relations[link.contract]),
          source: link.first,
          target: link.second,
        ),
      );
    }
    final direct = {for (final entry in entries) entry.resource};
    final ownership = authored.relations;
    final timeline = <skir.ResourceId, List<PortableTimelineCueProjection>>{};
    for (final entry in entries) {
      final visited = <skir.ResourceId>{entry.resource};
      timeline[entry.resource] = [
        for (final target in _ownedTimelineTargets(entry.resource, ownership))
          ?_timelineCue(target, direct, visited, ownership),
      ];
    }
    return PortablePageProjection(
      entries: entries,
      edges: edges,
      timeline: timeline,
      problem: switch ({
        for (final resource in {location.resource, ...direct})
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
      _writePageInteger(operation, change.resource, "x", change.x);
      _writePageInteger(operation, change.resource, "y", change.y);
    }
  });

  @override
  PortablePresentationWriteResult resizeGraphNodes(
    List<PortableGraphSizeChange> changes, {
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Resize graph nodes", (operation) {
    for (final change in changes) {
      _writePageInteger(operation, change.resource, "width", change.width);
      _writePageInteger(operation, change.resource, "height", change.height);
    }
  });

  @override
  PortablePresentationWriteResult moveTimelineElements(
    List<PortableTimelineChange> changes, {
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Move timeline elements", (operation) {
    for (final change in changes) {
      final placement = operation
          .resource(change.resource)
          ?.authoredField("placement");
      if (placement?.authoredField("frame") != null) {
        _writePageInteger(
          operation,
          change.resource,
          "frame",
          change.startFrame,
        );
      } else {
        _writePageInteger(
          operation,
          change.resource,
          "startFrame",
          change.startFrame,
        );
        _writePageInteger(
          operation,
          change.resource,
          "endFrame",
          change.endFrame,
        );
      }
    }
  });

  @override
  PortablePresentationWriteResult removePageResource(
    PortablePageEntryProjection entry, {
    required bool delete,
    required PortableInvocationContext context,
  }) => _pageEdit(context, "Change page resource", (operation) {
    if (delete) {
      operation.delete(entry.resource);
    } else {
      operation.disconnect(entry.occurrence);
    }
  });

  PortablePresentationWriteResult _pageEdit(
    PortableInvocationContext context,
    String label,
    void Function(AuthoringEdit operation) apply,
  ) {
    if (context.catalogGeneration != authored.generation) {
      return const PortablePresentationWriteRejected(
        "The editor catalog changed",
      );
    }
    return _stage(label, apply, independent: true);
  }

  PortablePageGraphPlacement? _graphPlacement(skir.DataValue? value) {
    final x = value?.authoredField("x")?.authoredInteger?.toInt();
    final y = value?.authoredField("y")?.authoredInteger?.toInt();
    final width = value?.authoredField("width")?.authoredInteger?.toInt();
    final height = value?.authoredField("height")?.authoredInteger?.toInt();
    if (x == null || y == null || width == null || height == null) return null;
    if (width <= 0 || height <= 0) return null;
    return PortablePageGraphPlacement(x: x, y: y, width: width, height: height);
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

  Iterable<skir.ResourceId> _ownedTimelineTargets(
    skir.ResourceId source,
    AuthoringRelationIndex relations,
  ) sync* {
    if (authored.resource(source) == null) return;
    for (final target in relations.ownedBy(source)) {
      final record = authored.resource(target);
      if (record == null ||
          !authored.catalog.isResourceDefinition(
            record.configuration,
            _timelineCueResource,
          ) ||
          _timelinePlacement(record) == null) {
        continue;
      }
      yield target;
    }
  }

  PortableTimelinePlacement? _timelinePlacement(skir.AuthoringRecord record) {
    final placementType = authored.catalog
        .fields(record.configuration)
        .where((field) => field.template.key == "placement")
        .firstOrNull
        ?.type;
    if (placementType == null) return null;
    final placement = record.authoredField("placement");
    if (authored.catalog.isReadableAs(
      placementType,
      _timelineKeyframePlacement,
    )) {
      final frame = placement?.authoredField("frame")?.authoredInteger?.toInt();
      return frame == null || frame < 0
          ? null
          : PortableTimelineKeyframe(frame);
    }
    if (!authored.catalog.isReadableAs(
      placementType,
      _timelineSegmentPlacement,
    )) {
      return null;
    }
    final start = placement
        ?.authoredField("startFrame")
        ?.authoredInteger
        ?.toInt();
    final end = placement?.authoredField("endFrame")?.authoredInteger?.toInt();
    return start == null || end == null || start < 0 || end < start
        ? null
        : PortableTimelineSegment(start, end);
  }

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
      label: _resourceLabel(record) ?? resource.value,
      placement: placement,
      children: children,
    );
  }

  void _writePageInteger(
    AuthoringEdit operation,
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
    final current = operation.read(location);
    if (current is! PortablePathValue<skir.DataValue>) {
      throw StateError("The resource placement is unavailable");
    }
    operation.set(
      location,
      current.value.withAuthoredPayload(
        skir.DataValue.wrapInteger(value.toString()),
      ),
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
    final applied = authored.catalog.applyTemplate(
      definition.rowType,
      record.configuration,
    );
    return applied == null ? row : _completeProjectedValue(row, applied);
  }

  skir.DataValue? _completeProjectedValue(
    skir.DataValue authoredValue,
    skir.TypeUse expected,
  ) {
    if (authoredValue == skir.DataValue.unfilled) return authoredValue;
    return switch (expected) {
      skir.TypeUse_nullableWrapper(value: final nullable) =>
        authoredValue == skir.DataValue.null_
            ? authoredValue
            : _completeProjectedValue(authoredValue, nullable.value),
      skir.TypeUse_namedWrapper(value: final named) =>
        _completeProjectedNamedValue(authoredValue, named),
      _ => authoredValue,
    };
  }

  skir.DataValue? _completeProjectedNamedValue(
    skir.DataValue authoredValue,
    skir.NamedTypeUse expected,
  ) {
    final payload = switch (authoredValue) {
      skir.DataValue_namedWrapper(:final value)
          when value.actualType == expected =>
        value.payload,
      skir.DataValue_namedWrapper() => null,
      _ => authoredValue,
    };
    if (payload == null) return null;
    final representation = authored.catalog
        .published(expected.definition)
        ?.definition
        .representation;
    if (representation is! skir.RepresentationTemplate_recordWrapper) {
      return skir.DataValue.createNamed(actualType: expected, payload: payload);
    }
    final projected = payload.authoredRecord;
    if (projected == null) return null;
    final fields = authored.catalog.fields(
      skir.TypeSelection.wrapComplete(expected),
    );
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
          : _completeProjectedValue(fieldValue, field.type!);
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

  String? _resourceLabel(skir.AuthoringRecord record) {
    for (final field in const ["name", "title"]) {
      final value = record.authoredField(field)?.authoredString?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  PortablePresentationWriteResult addMapRow(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    final target = location(reference, context: context);
    final payload = read(reference, context: context)?.authoredPayload;
    final rows = switch (payload) {
      skir.DataValue_mapValueWrapper(:final value) => value.rows.toList(),
      final value when value == skir.DataValue.unfilled => <skir.MapRow>[],
      _ => null,
    };
    if (target == null || rows == null) {
      return const PortablePresentationWriteRejected(
        "The map binding is unavailable",
      );
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
    return _stage("Add map row", (operation) {
      final current = operation.expect(target);
      if (current is! PortablePathValue<skir.DataValue> ||
          current.value.authoredPayload != payload) {
        throw StateError("The map changed before this edit");
      }
      operation.replaceMap(target, [
        ...rows,
        skir.MapRow(
          id: item,
          key: authored.defaultValue(branchType(skir.PathSegment.mapKey)),
          value: authored.defaultValue(branchType(skir.PathSegment.mapValue)),
        ),
      ]);
    });
  }

  Future<PortablePresentationWriteResult> _executeLocal(
    skir.LocalEditorAction local,
    PortableInvocationContext context,
  ) async {
    switch (local) {
      case skir.LocalEditorAction_setValueWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        return replacement == null
            ? const PortablePresentationWriteRejected(
                "The action value is unavailable",
              )
            : _stage("Edit value", (operation) {
                final target = location(value.target, context: context);
                if (target == null) {
                  throw StateError("The action target is unavailable");
                }
                operation
                  ..observeExpressionReads(replacement.reads)
                  ..set(target, replacement.value);
              });
      case skir.LocalEditorAction_insertListItemWrapper(:final value):
        final replacement = _evaluate(value.value, context);
        if (replacement == null) {
          return const PortablePresentationWriteRejected(
            "The action value is unavailable",
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
          return const PortablePresentationWriteRejected(
            "The action target is not a collection",
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
          return const PortablePresentationWriteRejected(
            "The collection item is no longer available",
          );
        }
        return _editList(
          value.target,
          context,
          reads: [
            PortableExpressionRead(
              value.target.bindingId,
              skir.ValuePath(
                segments: [
                  ...value.target.path.segments,
                  skir.PathSegment.createItem(id: source.id),
                ],
              ),
              location: skir.ValueLocation(
                resource: target.resource,
                path: skir.ValuePath(
                  segments: [
                    ...target.path.segments,
                    skir.PathSegment.createItem(id: source.id),
                  ],
                ),
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
          return const PortablePresentationWriteRejected(
            "The action value is unavailable",
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
          return const PortablePresentationWriteRejected(
            "The action value is unavailable",
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
        return const PortablePresentationWriteRejected(
          "This local editor action is unavailable",
        );
    }
  }

  Future<PortablePresentationWriteResult> _executeRealm(
    skir.RealmEditorAction realm,
    PortableInvocationContext context,
  ) async {
    switch (realm) {
      case skir.RealmEditorAction_reloadWrapper():
        final reload = capabilities.reload;
        if (reload == null) {
          return const PortablePresentationWriteRejected(
            "Reload is unavailable",
          );
        }
        await reload();
      case skir.RealmEditorAction_commandWrapper(:final value):
        final invoke = capabilities.invokeCommand;
        final payload = _evaluate(value.payload, context);
        if (invoke == null || payload == null) {
          return const PortablePresentationWriteRejected(
            "Realm commands are unavailable",
          );
        }
        await invoke(value.capabilityId, payload.value);
      case skir.RealmEditorAction_unknown():
        return const PortablePresentationWriteRejected(
          "This Realm editor action is unavailable",
        );
    }
    return const PortablePresentationWriteApplied();
  }

  _AuthoredActionValue? _evaluate(
    skir.ExpressionNode expression,
    PortableInvocationContext context,
  ) => switch (PortableExpressionEvaluator.located(
    context.bindings,
    budget: budget,
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
    Iterable<PortableExpressionRead> reads = const [],
  }) {
    final target = location(reference, context: context);
    if (target == null) {
      return const PortablePresentationWriteRejected(
        "The action target is unavailable",
      );
    }
    return _stage("Edit collection", (operation) {
      operation.observeExpressionReads(reads);
      apply(target, operation);
    });
  }

  PortablePresentationWriteResult _editMap(
    skir.BindingRef reference,
    PortableInvocationContext context, {
    required List<skir.MapRow> Function(List<skir.MapRow> rows) update,
    skir.ItemId? requiredRow,
    Iterable<PortableExpressionRead> reads = const [],
  }) {
    final target = location(reference, context: context);
    final current = read(reference, context: context)?.authoredPayload;
    if (target == null || current is! skir.DataValue_mapValueWrapper) {
      return const PortablePresentationWriteRejected(
        "The action target is not a map",
      );
    }
    final rows = current.value.rows.toList();
    if (requiredRow != null && rows.every((row) => row.id != requiredRow)) {
      return const PortablePresentationWriteRejected(
        "The map row is no longer available",
      );
    }
    return _stage("Edit map", (operation) {
      operation.observeExpressionReads(reads);
      final latest = operation.expect(target);
      if (latest is! PortablePathValue<skir.DataValue> ||
          latest.value.authoredPayload != current) {
        throw StateError("The map changed before this action");
      }
      operation.replaceMap(target, update(rows));
    });
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
      return const PortablePresentationWriteRejected(
        "The selected form cannot be prepared",
      );
    }
    final operationId = const Uuid().v4();
    final request = skir.ValuePreparationRequest(
      id: skir.InitializationRequestId(value: "panel:form:$operationId"),
      catalog: authored.generation,
      target: skir.PreparationTarget.wrapRecord(
        skir.TypeSelection.wrapComplete(named),
      ),
      suppliedValue: skir.DataValue.createRecord(fields: const []),
      intentHash: sha256
          .convert(
            utf8.encode(
              "${authored.generation.value}\u0000${target.resource.value}\u0000${target.path}\u0000$named",
            ),
          )
          .toString(),
    );
    final binding = edit!;
    final previousFindingCount = authored.initializationFindings.length;
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
    if (result case AuthoringEditRejected(:final message)) {
      return PortablePresentationWriteRejected(message);
    }
    final findings = authored.initializationFindings.skip(previousFindingCount);
    if (findings.isNotEmpty) {
      reportStatus?.call(
        findings.map(formatPortableInitializationDiagnostic).join("\n"),
      );
    }
    return const PortablePresentationWriteApplied();
  }

  PortablePresentationWriteResult _stage(
    String label,
    void Function(AuthoringEdit operation) apply, {
    bool independent = false,
  }) {
    final binding = edit;
    if (!enabled || readOnly || binding == null) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final result = independent
        ? binding.workspace.edit(label: label, apply: apply, from: authored)
        : binding.edit(label: label, apply: apply, from: authored);
    return switch (result) {
      AuthoringEditRejected(:final message) =>
        PortablePresentationWriteRejected(message),
      _ => const PortablePresentationWriteApplied(),
    };
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

final _timelineCueResource = skir.ResourceDefinitionId(value: "typewriter.cue");
final _timelineSegmentPlacement = _declaredPresentationType(
  "54e38e56871243d2ae747ed6c0083381",
);
final _timelineKeyframePlacement = _declaredPresentationType(
  "e0369811aac94bf6a291f65d1c719e1b",
);

skir.TypeUse _declaredPresentationType(String id) => skir.TypeUse.createNamed(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(value: id),
    revision: 1,
  ),
  arguments: const [],
);

final class _AuthoredActionValue {
  const _AuthoredActionValue(this.value, this.reads);

  final skir.DataValue value;
  final List<PortableExpressionRead> reads;
}
