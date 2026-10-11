part of "authoring_workspace.dart";

/// A private operation branch. Only the workspace can publish its changes.
final class AuthoringEdit implements PortableAuthoringEdit {
  AuthoringEdit({
    required this.generation,
    required Iterable<skir.AuthoringResource> resources,
    required Iterable<skir.LinkProjection> links,
    this.catalog,
  }) : _resources = {
         for (final resource in resources) resource.id: resource.content,
       },
       _definitions = {
         for (final resource in resources) resource.id: resource.definition,
       },
       _links = List.of(links),
       _baselineResources = {
         for (final resource in resources) resource.id: resource.content,
       },
       _baselineLinks = List.of(links);
  factory AuthoringEdit.fromDocument(AuthoringDocument document) =>
      AuthoringEdit(
          generation: document.generation,
          resources: document.entries.values,
          links: document.links,
          catalog: document.catalog,
        )
        .._initializationFindings.addAll(document.initializationFindings)
        .._inheritedFindings = document.initializationFindings.length;

  factory AuthoringEdit.fromState(
    skir.AuthoringState source, {
    CheckedEditorCatalog? catalog,
  }) => AuthoringEdit(
    generation: source.generation,
    resources: source.resources,
    links: source.links,
    catalog: catalog,
  );
  @override
  final skir.CatalogGeneration generation;
  final CheckedEditorCatalog? catalog;
  final Map<skir.ResourceId, skir.AuthoringRecord> _resources;
  final Map<skir.ResourceId, skir.ResourceDefinitionId> _definitions;
  final List<skir.LinkProjection> _links;
  final Map<skir.ResourceId, skir.AuthoringRecord> _baselineResources;
  final List<skir.LinkProjection> _baselineLinks;
  final Map<Object, skir.EditExpectation> _observed = {};
  final List<skir.EditIntent> _intents = [];
  final List<skir.InitializationDiagnostic> _initializationFindings = [];
  int _inheritedFindings = 0;
  final Map<skir.ValueLocation, _MaterializationOperation>
  _materializationOperations = {};

  List<skir.EditIntent> get intents => List.unmodifiable(_intents);

  @override
  Map<skir.ResourceId, skir.AuthoringRecord> get resources =>
      Map.unmodifiable(_resources);

  @override
  List<skir.LinkProjection> get links => List.unmodifiable(_links);

  List<skir.EditExpectation> get expectations =>
      List.unmodifiable(_observed.values);

  @override
  List<skir.InitializationDiagnostic> get initializationFindings =>
      List.unmodifiable(_initializationFindings);

  @override
  void observeExpressionReads(Iterable<PortableExpressionRead> reads) {
    for (final read in reads) {
      final location = read.location;
      if (location == null) continue;
      _observePath(location);
      _observe(_value(at: location));
    }
  }

  @override
  bool stageExpressionEdit(
    Iterable<PortableExpressionRead> reads,
    bool Function(PortableAuthoringEdit edit) edit,
  ) {
    final branch = fork();
    if (!edit(branch)) return false;
    branch.observeExpressionReads(reads);
    _adopt(branch);
    return true;
  }

  AuthoringEdit fork() {
    final branch = AuthoringEdit(
      generation: generation,
      resources: [
        for (final entry in _resources.entries)
          skir.AuthoringResource(
            id: entry.key,
            definition: _definitions[entry.key]!,
            content: entry.value,
          ),
      ],
      links: _links,
      catalog: catalog,
    );
    branch._baselineResources
      ..clear()
      ..addAll(_baselineResources);
    branch._baselineLinks
      ..clear()
      ..addAll(_baselineLinks);
    branch._observed.addAll(_observed);
    branch._intents.addAll(_intents);
    branch._initializationFindings.addAll(_initializationFindings);
    branch._inheritedFindings = _inheritedFindings;
    branch._materializationOperations.addAll(_materializationOperations);
    branch._failure = _failure;
    return branch;
  }

  Future<PortablePathResult<skir.AuthoringRecord>> setWithInitialization(
    skir.ValueLocation location,
    skir.DataValue value,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)
    prepare,
  ) async =>
      _recordResult(await _setWithInitialization(location, value, prepare));

  @override
  int get operationCount => _intents.length;
  String? _failure;
  void requireValid() {
    if (_failure case final message?) throw StateError(message);
  }

  PortablePathResult<skir.AuthoringRecord> _recordResult(
    PortablePathResult<skir.AuthoringRecord> result,
  ) {
    if (result case PortablePathUnavailable(:final message)) {
      _failure ??= message;
    }
    return result;
  }

  AuthoringDocument toDocument({int revision = 0}) => AuthoringDocument(
    catalog: catalog ?? (throw StateError("The editor catalog is unavailable")),
    entries: {
      for (final entry in _resources.entries)
        entry.key: skir.AuthoringResource(
          id: entry.key,
          definition: _definitions[entry.key]!,
          content: entry.value,
        ),
    },
    links: List.unmodifiable(_links),
    revision: revision,
    initializationFindings: List.unmodifiable(_initializationFindings),
  );
  @override
  PortablePathResult<skir.AuthoringRecord> set(
    skir.ValueLocation location,
    skir.DataValue value,
  ) => _recordResult(_set(location, value));
  PortablePathResult<skir.AuthoringRecord> setPayload(
    skir.ValueLocation location,
    skir.DataValue payload,
  ) => _recordResult(_setPayload(location, payload));
  @override
  PortablePathResult<skir.AuthoringRecord> insert(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ListItem item,
  ) => _recordResult(_insert(location, after, item));
  @override
  PortablePathResult<skir.AuthoringRecord> insertPrepared(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ItemId item,
    skir.ValuePreparationRequest request,
    skir.PreparedValue prepared,
  ) => _recordResult(_insertPrepared(location, after, item, request, prepared));
  @override
  PortablePathResult<skir.AuthoringRecord> remove(
    skir.ValueLocation location,
    skir.ItemId item,
  ) => _recordResult(_remove(location, item));
  @override
  PortablePathResult<skir.AuthoringRecord> move(
    skir.ValueLocation location,
    skir.ItemId item,
    skir.ItemId? after,
  ) => _recordResult(_move(location, item, after));
  @override
  PortablePathResult<skir.AuthoringRecord> replaceMap(
    skir.ValueLocation location,
    Iterable<skir.MapRow> rows,
  ) => _recordResult(_replaceMap(location, rows));
  @override
  PortablePathResult<skir.AuthoringRecord> applyPreparedRecord(
    skir.ValueLocation location,
    skir.ValuePreparationRequest request,
    skir.PreparedValue prepared,
  ) => _recordResult(_applyPreparedRecord(location, request, prepared));

  skir.PreparedEdit prepare() => skir.PreparedEdit(
    catalog: generation,
    expectations: expectations,
    intents: intents,
  );

  void applyPrepared(skir.PreparedEdit prepared) {
    if (prepared.catalog != generation) {
      throw StateError("The editor catalog changed");
    }
    for (final expected in prepared.expectations) {
      _observed[_factKey(expected)] = expected;
    }
    for (final intent in prepared.intents) {
      if (_replay(intent) case final message?) {
        throw StateError(message);
      }
    }
  }

  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => _resources[id];

  @override
  PortablePathResult<skir.DataValue> expect(skir.ValueLocation location) {
    _observePath(location);
    _observe(_value(at: location));
    return read(location);
  }

  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) {
    final record = _resources[location.resource];
    if (record == null) {
      return const PortablePathUnavailable("The resource is absent");
    }
    return record.readAt(location.path);
  }

  PortablePathResult<skir.AuthoringRecord> _set(
    skir.ValueLocation location,
    skir.DataValue value,
  ) {
    final record = _resources[location.resource];
    if (record == null) {
      return const PortablePathUnavailable("The resource is absent");
    }
    final current = record.readAt(location.path);
    if (current is PortablePathValue<skir.DataValue> &&
        _sameExpectedValue(current.value, value)) {
      return PortablePathValue(record);
    }
    final currentContainsLink = switch (current) {
      PortablePathValue(value: final currentValue) => _containsLink(
        currentValue,
      ),
      PortablePathUnavailable() => false,
    };
    if (_containsLink(value) || currentContainsLink) {
      return const PortablePathUnavailable(
        "Link values must be changed through relation operations",
      );
    }
    final originalIntents = _intents.length;
    final originalObserved = Map<Object, skir.EditExpectation>.from(_observed);
    PortablePathResult<skir.AuthoringRecord> rollback(
      PortablePathResult<skir.AuthoringRecord> result,
    ) {
      _resources[location.resource] = record;
      _intents.removeRange(originalIntents, _intents.length);
      _observed
        ..clear()
        ..addAll(originalObserved);
      return result;
    }

    final materialized = _materializeParents(location);
    if (materialized case PortablePathUnavailable<skir.AuthoringRecord>()) {
      return rollback(materialized);
    }
    final writableRecord = _resources[location.resource]!;
    _observePath(location);
    _observe(_value(at: location));
    final updated = writableRecord.replaceAt(location.path, value);
    if (updated case PortablePathValue(value: final stagedRecord)) {
      _resources[location.resource] = stagedRecord;
      _intents.add(skir.EditIntent.createSetValue(at: location, value: value));
      return updated;
    }
    return rollback(updated);
  }

  Future<PortablePathResult<skir.AuthoringRecord>> _setWithInitialization(
    skir.ValueLocation location,
    skir.DataValue value,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)
    prepare,
  ) async {
    final baseline = _EditState.capture(this);
    final working = fork();
    var result = working._set(location, value);
    while (result is PortablePathUnavailable<skir.AuthoringRecord> &&
        result.message == "The parent field needs prepared initialization") {
      final plan = working._parentInitialization(location);
      if (plan == null) return result;
      _materializationOperations[plan.location] =
          working._materializationOperations[plan.location]!;
      working
        .._observePath(plan.containing)
        .._observe(_value(at: plan.containing));
      final containing = await prepare(plan.request);
      if (!baseline.matches(this)) {
        return const PortablePathUnavailable(
          "The operation changed while the parent field was being initialized",
        );
      }
      if (!working._recordIsUsable(containing, plan.request)) {
        return const PortablePathUnavailable(
          "The parent field initialization needs attention",
        );
      }
      working._initializationFindings.addAll(
        _locatedInitializationFindings(
          plan.containing.path,
          containing.findings,
        ),
      );
      var parent = containing.recordContent.fields
          .where((field) => field.name == plan.field)
          .firstOrNull
          ?.value;
      if (parent == null ||
          parent == skir.DataValue.unfilled ||
          parent == skir.DataValue.null_) {
        final child = await prepare(plan.childRequest);
        if (!baseline.matches(this)) {
          return const PortablePathUnavailable(
            "The operation changed while the parent field was being initialized",
          );
        }
        if (!working._recordIsUsable(child, plan.childRequest)) {
          return const PortablePathUnavailable(
            "The parent field initialization needs attention",
          );
        }
        working._initializationFindings.addAll(
          _locatedInitializationFindings(plan.location.path, child.findings),
        );
        final actual = switch (child.recordContent.configuration) {
          skir.TypeSelection_completeWrapper(:final value) => value,
          _ => null,
        };
        if (actual == null ||
            !(catalog?.isReadableAs(
                  skir.TypeUse.wrapNamed(actual),
                  skir.TypeUse.wrapNamed(plan.expected),
                ) ??
                false)) {
          return const PortablePathUnavailable(
            "The prepared parent field has an incompatible type",
          );
        }
        parent = skir.DataValue.createNamed(
          actualType: actual,
          payload: skir.DataValue.createRecord(
            fields: child.recordContent.fields,
          ),
        );
      }
      if (_containsLink(parent)) {
        return const PortablePathUnavailable(
          "The prepared parent contains relations that need explicit choices",
        );
      }
      final staged = working._set(plan.location, parent);
      if (staged case PortablePathUnavailable()) return staged;
      working._materializationOperations.remove(plan.location);
      result = working._set(location, value);
    }
    if (result case PortablePathValue()) {
      if (!baseline.matches(this)) {
        return const PortablePathUnavailable(
          "The operation changed while the parent field was being initialized",
        );
      }
      _adopt(working);
    }
    return result;
  }

  bool _recordIsUsable(
    skir.PreparedValue prepared,
    skir.ValuePreparationRequest request,
  ) {
    if (prepared.recordContent.configuration != request.recordSelection) {
      return false;
    }
    final actual = prepared.recordContent.fields
        .map((field) => field.name)
        .toList();
    if (actual.toSet().length != actual.length) return false;
    final expected = catalog
        ?.fields(request.recordSelection)
        .map((field) => field.template.key)
        .toSet();
    return expected != null &&
        actual.length == expected.length &&
        actual.toSet().containsAll(expected);
  }

  void _adopt(AuthoringEdit source) {
    _failure ??= source._failure;
    _definitions
      ..clear()
      ..addAll(source._definitions);
    _resources
      ..clear()
      ..addAll(source._resources);
    _links
      ..clear()
      ..addAll(source._links);
    _observed
      ..clear()
      ..addAll(source._observed);
    _intents
      ..clear()
      ..addAll(source._intents);
    _initializationFindings
      ..clear()
      ..addAll(source._initializationFindings);
    _materializationOperations
      ..clear()
      ..addAll(source._materializationOperations);
  }

  PortablePathResult<skir.AuthoringRecord> _setPayload(
    skir.ValueLocation location,
    skir.DataValue payload,
  ) {
    final current = expect(location);
    return switch (current) {
      PortablePathValue(:final value) => _set(
        location,
        value.withAuthoredPayload(payload),
      ),
      PortablePathUnavailable(:final message) => PortablePathUnavailable(
        message,
      ),
    };
  }

  PortablePathResult<skir.AuthoringRecord> clear(
    skir.ValueLocation location, {
    skir.TypeUse? expected,
  }) => _recordResult(
    _set(
      location,
      expected is skir.TypeUse_nullableWrapper
          ? skir.DataValue.null_
          : skir.DataValue.unfilled,
    ),
  );

  PortablePathResult<skir.AuthoringRecord> _insert(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ListItem item,
  ) {
    _observeCollection(location);
    return _updateCollection(location, (items) {
      if (items.any((candidate) => candidate.id == item.id)) return null;
      final index = after == null
          ? 0
          : items.indexWhere((candidate) => candidate.id == after) + 1;
      if (after != null && index == 0) return null;
      return [...items.take(index), item, ...items.skip(index)];
    }, skir.EditIntent.createInsert(at: location, after: after, item: item));
  }

  PortablePathResult<skir.AuthoringRecord> _insertPrepared(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ItemId item,
    skir.ValuePreparationRequest request,
    skir.PreparedValue prepared,
  ) {
    if (!_recordIsUsable(prepared, request)) {
      return const PortablePathUnavailable(
        "The prepared collection item does not match the requested type",
      );
    }
    final actual = switch (prepared.recordContent.configuration) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (actual == null) {
      return const PortablePathUnavailable(
        "The prepared collection item is not a complete named value",
      );
    }
    final branch = fork();
    final result = branch._insert(
      location,
      after,
      skir.ListItem(
        id: item,
        value: skir.DataValue.createNamed(
          actualType: actual,
          payload: skir.DataValue.createRecord(
            fields: prepared.recordContent.fields,
          ),
        ),
      ),
    );
    if (result case PortablePathValue()) {
      branch._initializationFindings.addAll(
        _locatedInitializationFindings(
          skir.ValuePath(
            segments: [
              ...location.path.segments,
              skir.PathSegment.createItem(id: item),
            ],
          ),
          prepared.findings,
        ),
      );
      _adopt(branch);
    }
    return result;
  }

  @override
  skir.DataValue defaultValue(skir.TypeUse? type) =>
      _defaultForType(type, const {});

  PortablePathResult<skir.AuthoringRecord> _remove(
    skir.ValueLocation location,
    skir.ItemId item,
  ) {
    _observeCollection(location);
    return _updateCollection(location, (items) {
      if (items.every((candidate) => candidate.id != item)) return null;
      return items.where((candidate) => candidate.id != item).toList();
    }, skir.EditIntent.createRemove(at: location, item: item));
  }

  PortablePathResult<skir.AuthoringRecord> _move(
    skir.ValueLocation location,
    skir.ItemId item,
    skir.ItemId? after,
  ) {
    _observeCollection(location);
    return _updateCollection(location, (items) {
      if (item == after || items.every((candidate) => candidate.id != item)) {
        return null;
      }
      final moving = items.firstWhere((candidate) => candidate.id == item);
      final remaining = items
          .where((candidate) => candidate.id != item)
          .toList();
      final index = after == null
          ? 0
          : remaining.indexWhere((candidate) => candidate.id == after) + 1;
      if (after != null && index == 0) return null;
      return [...remaining.take(index), moving, ...remaining.skip(index)];
    }, skir.EditIntent.createMove(at: location, item: item, after: after));
  }

  PortablePathResult<skir.AuthoringRecord> _replaceMap(
    skir.ValueLocation location,
    Iterable<skir.MapRow> rows,
  ) {
    final previous = Map<Object, skir.EditExpectation>.of(_observed);
    _observeCollection(location);
    final observed = expect(location);
    if (observed is! PortablePathValue<skir.DataValue>) {
      return PortablePathUnavailable(
        (observed as PortablePathUnavailable<skir.DataValue>).message,
      );
    }
    final current = _collectionValue(location, observed.value);
    final result = _set(
      location,
      current.withAuthoredPayload(skir.DataValue.createMapValue(rows: rows)),
    );
    if (result case PortablePathUnavailable()) {
      _observed
        ..clear()
        ..addAll(previous);
    }
    return result;
  }

  PortablePathResult<skir.AuthoringRecord> _applyPreparedRecord(
    skir.ValueLocation location,
    skir.ValuePreparationRequest request,
    skir.PreparedValue prepared,
  ) {
    if (!_recordIsUsable(prepared, request)) {
      return const PortablePathUnavailable(
        "The prepared form does not match the requested type",
      );
    }
    final actual = switch (prepared.recordContent.configuration) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (actual == null) {
      return const PortablePathUnavailable(
        "The prepared form is not a complete named value",
      );
    }
    final branch = fork();
    final result = branch._set(
      location,
      skir.DataValue.createNamed(
        actualType: actual,
        payload: skir.DataValue.createRecord(
          fields: prepared.recordContent.fields,
        ),
      ),
    );
    if (result case PortablePathValue()) {
      branch._initializationFindings.addAll(
        _locatedInitializationFindings(location.path, prepared.findings),
      );
      _adopt(branch);
    }
    return result;
  }

  void create(
    skir.ResourceId id,
    skir.AuthoringRecord record, {
    skir.ResourceDefinitionId? definition,
  }) {
    if (_resources.containsKey(id)) {
      throw StateError("The resource already exists");
    }
    _definitions[id] =
        definition ??
        catalog?.resourceDefinition(record.configuration)?.id ??
        skir.ResourceDefinitionId.defaultInstance;
    _observe(_exists(resource: id));
    _resources[id] = record;
    _intents.add(skir.EditIntent.createCreateResource(id: id, record: record));
  }

  void createPrepared(
    skir.ResourceId id,
    skir.PreparedValue prepared, {
    skir.ResourceDefinitionId? definition,
  }) {
    create(id, prepared.recordContent, definition: definition);
    _initializationFindings.addAll(
      _locatedInitializationFindings(
        skir.ValuePath(segments: const []),
        prepared.findings,
      ),
    );
  }

  @override
  void delete(skir.ResourceId id) {
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
      _definitions.remove(resource);
    }
    _links.removeWhere(
      (link) => deleting.contains(link.first) || deleting.contains(link.second),
    );
    _intents.add(skir.EditIntent.createDeleteResource(id: id));
  }

  @override
  void connect(
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

  @override
  void disconnect(skir.LinkOccurrence occurrence) {
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
    final owners = checked.nominalDefinitions(record.configuration);
    final candidates = <skir.ValueLocation>{};
    for (final binding in checked.endpointBindings(record.configuration)) {
      if (binding.template.endpoint != endpoint ||
          binding.template.containsCollection ||
          !owners.contains(binding.template.valueOwner)) {
        continue;
      }
      final path = _directFieldPath(binding.template.relativePath);
      if (path != null) {
        candidates.add(skir.ValueLocation(resource: resource, path: path));
      }
    }
    return candidates.length == 1 ? candidates.single : null;
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
      for (final path in expandAuthoredPattern(
        staged,
        binding.template.relativePath,
      )) {
        if (path.isAtOrBelow(embedded.path)) {
          locations.add(skir.ValueLocation(resource: target, path: path));
        }
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
      catalog?.valueTypeAt(record.configuration, location.path),
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
      final expected = catalog?.valueTypeAt(record.configuration, path);
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

  void retag(skir.ValueLocation location, skir.NamedTypeUse type) {
    if (location.path.segments.isEmpty) {
      throw StateError("Resource configuration requires a type preview");
    }
    final record = _resources[location.resource];
    if (record == null) throw StateError("The resource is absent");
    final current = record.readAt(location.path);
    if (current is! PortablePathValue<skir.DataValue> ||
        current.value is! skir.DataValue_namedWrapper) {
      throw StateError("Only a named value can be retagged");
    }
    final named = (current.value as skir.DataValue_namedWrapper).value;
    final updated = record.replaceAt(
      location.path,
      skir.DataValue.createNamed(actualType: type, payload: named.payload),
    );
    if (updated is! PortablePathValue<skir.AuthoringRecord>) {
      throw StateError("The named value is unavailable");
    }
    _observe(_value(at: location));
    _observePath(location);
    _observe(_configuration(at: location));
    _observeIncoming(location.resource, null);
    _resources[location.resource] = updated.value;
    _intents.add(skir.EditIntent.createRetag(at: location, type: type));
  }

  void configureResource(
    skir.ResourceId resource,
    skir.TypeSelection configuration,
  ) {
    final current = _resources[resource];
    if (current == null) throw StateError("The resource is absent");
    if (_configurationRoot(current.configuration) !=
        _configurationRoot(configuration)) {
      throw StateError("Resource configuration must retain its root type");
    }
    _observe(skir.EditExpectation.createResource(id: resource, expected: null));
    _observe(_exists(resource: resource));
    _observe(_configuration(at: _root(resource)));
    _observeIncoming(resource, null);
    _resources[resource] = skir.AuthoringRecord(
      configuration: configuration,
      fields: current.fields,
    );
    _intents.add(
      skir.EditIntent.createConfigureResource(
        resource: resource,
        configuration: configuration,
      ),
    );
  }

  String? _replay(skir.EditIntent intent) {
    PortablePathResult<skir.AuthoringRecord>? result;
    switch (intent) {
      case skir.EditIntent_createResourceWrapper(:final value):
        create(value.id, value.record);
      case skir.EditIntent_deleteResourceWrapper(:final value):
        delete(value.id);
      case skir.EditIntent_setValueWrapper(:final value):
        result = _set(value.at, value.value);
      case skir.EditIntent_insertWrapper(:final value):
        result = _insert(value.at, value.after, value.item);
      case skir.EditIntent_removeWrapper(:final value):
        result = _remove(value.at, value.item);
      case skir.EditIntent_moveWrapper(:final value):
        result = _move(value.at, value.item, value.after);
      case skir.EditIntent_connectRelationWrapper(:final value):
        connect(value.source, value.target, counterpart: value.counterpart);
      case skir.EditIntent_disconnectRelationWrapper(:final value):
        _disconnect(value);
      case skir.EditIntent_retagWrapper(:final value):
        retag(value.at, value.type);
      case skir.EditIntent_configureResourceWrapper(:final value):
        configureResource(value.resource, value.configuration);
      case skir.EditIntent_unknown():
        return "The operation contains an unknown edit";
    }
    return switch (result) {
      PortablePathUnavailable(:final message) => message,
      _ => null,
    };
  }

  void _observeCollection(skir.ValueLocation location) {
    _observePath(location);
    _observe(_configuration(at: location));
    _observe(_value(at: location));
  }

  void _observePath(skir.ValueLocation location) {
    _observe(_exists(resource: location.resource));
    var current = _root(location.resource);
    _observe(_configuration(at: current));
    for (final segment in location.path.segments) {
      if (segment is skir.PathSegment_itemWrapper) {
        _observe(_value(at: current));
      }
      current = skir.ValueLocation(
        resource: current.resource,
        path: skir.ValuePath(segments: [...current.path.segments, segment]),
      );
      _observe(_configuration(at: current));
    }
  }

  void _observeIncoming(skir.ResourceId resource, skir.RelationId? relation) {
    final contracts = relation == null
        ? catalog?.snapshot.relations.map((value) => value.id) ??
              const <skir.RelationId>[]
        : [relation];
    for (final contract in contracts) {
      _observe(
        skir.EditExpectation.createLinks(
          resource: resource,
          contract: contract,
          direction: skir.TraversalDirection.both,
          expected: const [],
        ),
      );
    }
  }

  void _observeRelationsForEndpoint(
    skir.EndpointId endpoint,
    skir.ResourceId source,
    skir.ResourceId target,
  ) {
    if (catalog case final actualCatalog?) {
      for (final contract in actualCatalog.snapshot.relations.where(
        (relation) =>
            relation.first.id == endpoint || relation.second.id == endpoint,
      )) {
        _observeIncoming(source, contract.id);
        _observeIncoming(target, contract.id);
      }
    }
    for (final link in _links.where(
      (link) =>
          (link.first == source && link.second == target) ||
          (link.first == target && link.second == source),
    )) {
      _observeRelationProjection(link);
    }
  }

  void _observeDeletionRelations(Set<skir.ResourceId> deleting) {
    for (final resource in deleting) {
      _observe(
        skir.EditExpectation.createResource(id: resource, expected: null),
      );
      _observe(_exists(resource: resource));
      _observe(_configuration(at: _root(resource)));
      _observeIncoming(resource, null);
    }
    for (final link in _links.where(
      (link) => deleting.contains(link.first) || deleting.contains(link.second),
    )) {
      _observeIncoming(link.first, null);
      _observeIncoming(link.second, null);
      _observeRelationProjection(link);
    }
  }

  void _observeRelationProjection(skir.LinkProjection link) {
    _observeIncoming(link.first, link.contract);
    _observeIncoming(link.second, link.contract);
    if (link.firstLocation case final path?) {
      _observeRelationPath(
        skir.ValueLocation(resource: link.first, path: path),
      );
    }
    if (link.secondLocation case final path?) {
      _observeRelationPath(
        skir.ValueLocation(resource: link.second, path: path),
      );
    }
  }

  void _observeRelationPath(skir.ValueLocation location) {
    _observePath(location);
    _observe(_value(at: location));
    final segments = location.path.segments.toList();
    if (segments.lastOrNull is skir.PathSegment_itemWrapper) {
      final parent = skir.ValueLocation(
        resource: location.resource,
        path: skir.ValuePath(segments: segments.take(segments.length - 1)),
      );
      _observe(_configuration(at: parent));
      _observe(_value(at: parent));
    }
  }

  void _observe(skir.EditExpectation expected) {
    _observed.putIfAbsent(_factKey(expected), () => _actual(expected));
  }

  skir.EditExpectation _actual(
    skir.EditExpectation expected, {
    bool original = true,
  }) {
    final resources = original ? _baselineResources : _resources;
    final links = original ? _baselineLinks : _links;
    skir.DataValue? value(skir.ValueLocation at) {
      final record = resources[at.resource];
      if (record == null) return null;
      if (at.path.segments.isEmpty) {
        return skir.DataValue.createRecord(fields: record.fields);
      }
      return switch (record.readAt(at.path)) {
        PortablePathValue(:final value) => value,
        _ => null,
      };
    }

    return switch (expected) {
      skir.EditExpectation_valueWrapper(value: final expected) =>
        skir.EditExpectation.createValue(
          at: expected.at,
          expected: value(expected.at),
        ),
      skir.EditExpectation_resourceWrapper(:final value) =>
        skir.EditExpectation.createResource(
          id: value.id,
          expected: resources[value.id],
        ),
      skir.EditExpectation_resourceExistsWrapper(:final value) =>
        skir.EditExpectation.createResourceExists(
          id: value.id,
          expected: resources.containsKey(value.id),
        ),
      skir.EditExpectation_configurationWrapper(value: final config) =>
        skir.EditExpectation.createConfiguration(
          at: config.at,
          expected: config.at.path.segments.isEmpty
              ? resources[config.at.resource]?.configuration
              : switch (value(config.at)) {
                  skir.DataValue_namedWrapper(:final value) =>
                    skir.TypeSelection.wrapComplete(value.actualType),
                  _ => null,
                },
        ),
      skir.EditExpectation_resourceIdsWrapper() =>
        skir.EditExpectation.wrapResourceIds(
          resources.keys.toList()..sort((a, b) => a.value.compareTo(b.value)),
        ),
      skir.EditExpectation_linksWrapper(:final value) =>
        skir.EditExpectation.createLinks(
          resource: value.resource,
          contract: value.contract,
          direction: value.direction,
          expected: links
              .where(
                (link) =>
                    link.contract == value.contract &&
                    switch (value.direction) {
                      skir.TraversalDirection.forward =>
                        link.first == value.resource,
                      skir.TraversalDirection.reverse =>
                        link.second == value.resource,
                      skir.TraversalDirection.both =>
                        link.first == value.resource ||
                            link.second == value.resource,
                      _ => false,
                    },
              )
              .toSet()
              .toList(),
        ),
      _ => throw StateError("Unknown edit expectation"),
    };
  }

  PortablePathResult<skir.AuthoringRecord> _materializeParents(
    skir.ValueLocation target,
  ) {
    final checked = catalog;
    if (checked == null || target.path.segments.length < 2) {
      return PortablePathValue(_resources[target.resource]!);
    }
    while (true) {
      final record = _resources[target.resource]!;
      var selection = record.configuration;
      var currentPath = <skir.PathSegment>[];
      var changed = false;
      for (final segment in target.path.segments.take(
        target.path.segments.length - 1,
      )) {
        if (segment case skir.PathSegment_fieldWrapper(:final value)) {
          final field = checked
              .fields(selection)
              .where((candidate) => candidate.template.key == value.name)
              .firstOrNull;
          if (field == null || field.type == null) {
            return const PortablePathUnavailable(
              "The parent field type is unavailable",
            );
          }
          currentPath = [...currentPath, segment];
          final location = skir.ValueLocation(
            resource: target.resource,
            path: skir.ValuePath(segments: currentPath),
          );
          final child = record.readAt(location.path);
          final childValue = switch (child) {
            PortablePathValue(:final value) => value,
            PortablePathUnavailable() => skir.DataValue.unfilled,
          };
          if (childValue == skir.DataValue.unfilled ||
              childValue == skir.DataValue.null_) {
            final expected = _concreteNamed(field.type);
            if (expected == null) {
              return const PortablePathUnavailable(
                "The parent field is not a concrete record",
              );
            }
            final parent = _materializeParent(
              selection,
              field.template.owner,
              expected,
            );
            if (parent == null) {
              return const PortablePathUnavailable(
                "The parent field needs prepared initialization",
              );
            }
            _observePath(location);
            _observe(_value(at: location));
            final updated = record.replaceAt(location.path, parent);
            if (updated case PortablePathValue(value: final stagedRecord)) {
              _resources[target.resource] = stagedRecord;
              _intents.add(
                skir.EditIntent.createSetValue(at: location, value: parent),
              );
              changed = true;
              break;
            }
            return updated;
          }
          selection = switch (childValue) {
            skir.DataValue_namedWrapper(:final value) =>
              skir.TypeSelection.wrapComplete(value.actualType),
            _ => skir.TypeSelection.unknown,
          };
        } else {
          currentPath = [...currentPath, segment];
          final child = record.readAt(skir.ValuePath(segments: currentPath));
          if (child case PortablePathUnavailable()) {
            return const PortablePathUnavailable(
              "The collection item is absent",
            );
          }
          final childValue = (child as PortablePathValue<skir.DataValue>).value;
          selection = switch (childValue) {
            skir.DataValue_namedWrapper(:final value) =>
              skir.TypeSelection.wrapComplete(value.actualType),
            _ => skir.TypeSelection.unknown,
          };
        }
      }
      if (!changed) return PortablePathValue(record);
    }
  }

  skir.DataValue? _materializeParent(
    skir.TypeSelection containing,
    skir.FieldOwner owner,
    skir.NamedTypeUse expected,
  ) {
    final checked = catalog!;
    final containingDefinition = checked.selected(containing)?.definition.id;
    final containingDescriptor = containingDefinition == null
        ? null
        : checked.initialization(containingDefinition);
    if (containingDescriptor?.mode == skir.InitializationMode.creation) {
      return null;
    }
    final captured = containingDescriptor?.captured
        .where((candidate) => candidate.field == owner)
        .firstOrNull
        ?.value;
    if (captured case skir.DataValue_namedWrapper(:final value)
        when checked.isReadableAs(
          skir.TypeUse.wrapNamed(value.actualType),
          skir.TypeUse.wrapNamed(expected),
        )) {
      return captured;
    }
    final descriptor = checked.initialization(expected.definition);
    if (descriptor?.mode == skir.InitializationMode.creation) {
      return null;
    }
    return _defaultForNamed(expected, <skir.NamedTypeUse>{});
  }

  _ParentInitialization? _parentInitialization(skir.ValueLocation target) {
    final checked = catalog;
    final root = _resources[target.resource];
    if (checked == null || root == null || target.path.segments.length < 2) {
      return null;
    }
    var selection = root.configuration;
    var fields = root.fields.toList(growable: false);
    var currentPath = <skir.PathSegment>[];
    for (final segment in target.path.segments.take(
      target.path.segments.length - 1,
    )) {
      currentPath = [...currentPath, segment];
      final child = root.readAt(skir.ValuePath(segments: currentPath));
      if (segment case skir.PathSegment_fieldWrapper(:final value)) {
        final field = checked
            .fields(selection)
            .where((candidate) => candidate.template.key == value.name)
            .firstOrNull;
        final expected = _concreteNamed(field?.type);
        if (field == null || expected == null) return null;
        final childValue = switch (child) {
          PortablePathValue(:final value) => value,
          PortablePathUnavailable() => skir.DataValue.unfilled,
        };
        if ((childValue == skir.DataValue.unfilled ||
                childValue == skir.DataValue.null_) &&
            _materializeParent(selection, field.template.owner, expected) ==
                null) {
          final location = skir.ValueLocation(
            resource: target.resource,
            path: skir.ValuePath(segments: currentPath),
          );
          final supplied = fields
              .where((candidate) => candidate.name != value.name)
              .toList(growable: false);
          final fingerprint = _initializationFingerprint(
            location,
            selection,
            supplied,
          );
          final existing = _materializationOperations[location];
          final operation = existing?.fingerprint == fingerprint
              ? existing!
              : _MaterializationOperation(
                  id: const Uuid().v4(),
                  fingerprint: fingerprint,
                );
          _materializationOperations[location] = operation;
          final containingIdentity = _initializationIntentHash(
            operation,
            "containing",
          );
          final childIdentity = _initializationIntentHash(operation, "child");
          final containingLocation = skir.ValueLocation(
            resource: target.resource,
            path: skir.ValuePath(
              segments: currentPath.take(currentPath.length - 1),
            ),
          );
          return _ParentInitialization(
            location: location,
            containing: containingLocation,
            field: value.name,
            expected: expected,
            request: skir.ValuePreparationRequest(
              id: skir.InitializationRequestId(
                value: "panel:materialize:${operation.id}:containing",
              ),
              catalog: generation,
              target: skir.PreparationTarget.wrapRecord(selection),
              suppliedValue: skir.DataValue.createRecord(fields: supplied),
              intentHash: containingIdentity,
            ),
            childRequest: skir.ValuePreparationRequest(
              id: skir.InitializationRequestId(
                value: "panel:materialize:${operation.id}:child",
              ),
              catalog: generation,
              target: skir.PreparationTarget.wrapRecord(
                skir.TypeSelection.wrapComplete(expected),
              ),
              suppliedValue: skir.DataValue.createRecord(fields: const []),
              intentHash: childIdentity,
            ),
          );
        }
        selection = switch (childValue) {
          skir.DataValue_namedWrapper(:final value) =>
            skir.TypeSelection.wrapComplete(value.actualType),
          _ => skir.TypeSelection.unknown,
        };
        fields =
            childValue.authoredRecord?.fields.toList(growable: false) ??
            const [];
      } else {
        if (child is! PortablePathValue<skir.DataValue>) return null;
        final childValue = child.value;
        selection = switch (childValue) {
          skir.DataValue_namedWrapper(:final value) =>
            skir.TypeSelection.wrapComplete(value.actualType),
          _ => skir.TypeSelection.unknown,
        };
        fields =
            childValue.authoredRecord?.fields.toList(growable: false) ??
            const [];
      }
    }
    return null;
  }

  String _initializationFingerprint(
    skir.ValueLocation location,
    skir.TypeSelection selection,
    List<skir.FieldValue> supplied,
  ) {
    final bytes = <int>[
      ...skir.CatalogGeneration.serializer.toBytes(generation),
      ...skir.ValueLocation.serializer.toBytes(location),
      ...skir.TypeSelection.serializer.toBytes(selection),
      for (final field in [
        ...supplied,
      ]..sort((a, b) => a.name.compareTo(b.name)))
        ...skir.FieldValue.serializer.toBytes(field),
    ];
    return sha256.convert(bytes).toString();
  }

  String _initializationIntentHash(
    _MaterializationOperation operation,
    String step,
  ) => sha256
      .convert(utf8.encode("${operation.id}:${operation.fingerprint}:$step"))
      .toString();

  skir.DataValue _defaultForNamed(
    skir.NamedTypeUse actual,
    Set<skir.NamedTypeUse> visiting,
  ) => _AuthoringDefaults(catalog)._defaultForNamed(actual, visiting);
  skir.DataValue _defaultForType(
    skir.TypeUse? type,
    Set<skir.NamedTypeUse> visiting,
  ) => _AuthoringDefaults(catalog)._defaultForType(type, visiting);

  PortablePathResult<skir.AuthoringRecord> _updateCollection(
    skir.ValueLocation location,
    List<skir.ListItem>? Function(List<skir.ListItem> items) update,
    skir.EditIntent intent,
  ) {
    final current = expect(location);
    if (current case PortablePathUnavailable(:final message)) {
      return PortablePathUnavailable(message);
    }
    final currentValue = (current as PortablePathValue<skir.DataValue>).value;
    final changed = _replaceCollectionItems(
      _collectionValue(location, currentValue),
      update,
    );
    if (changed == null) {
      return const PortablePathUnavailable("The collection edit is invalid");
    }
    final record = _resources[location.resource]!;
    final staged = record.replaceAt(location.path, changed);
    if (staged case PortablePathValue(:final value)) {
      _resources[location.resource] = value;
      _intents.add(intent);
    }
    return staged;
  }

  skir.DataValue _collectionValue(
    skir.ValueLocation location,
    skir.DataValue current,
  ) {
    if (current.authoredItems != null ||
        current.authoredPayload != skir.DataValue.unfilled) {
      return current;
    }
    final record = _resources[location.resource];
    if (record == null) return current;
    final expected = catalog?.valueTypeAt(
      record.configuration,
      location.path,
      value: skir.DataValue.createRecord(fields: record.fields),
    );
    final initialized = _defaultForType(expected, const {});
    return initialized.authoredItems != null ||
            initialized.authoredPayload is skir.DataValue_mapValueWrapper
        ? initialized
        : current;
  }
}

Iterable<skir.InitializationDiagnostic> _locatedInitializationFindings(
  skir.ValuePath base,
  Iterable<skir.InitializationDiagnostic> findings,
) sync* {
  for (final finding in findings) {
    final relative = finding.relativePath;
    final segments = [
      ...base.segments,
      if (relative != null) ...relative.segments,
    ];
    yield skir.InitializationDiagnostic(
      field: finding.field,
      code: finding.code,
      message: finding.message,
      relativePath: segments.isEmpty
          ? null
          : skir.ValuePath(segments: segments),
    );
  }
}

final class _ParentInitialization {
  const _ParentInitialization({
    required this.location,
    required this.containing,
    required this.field,
    required this.expected,
    required this.request,
    required this.childRequest,
  });

  final skir.ValueLocation location;
  final skir.ValueLocation containing;
  final String field;
  final skir.NamedTypeUse expected;
  final skir.ValuePreparationRequest request;
  final skir.ValuePreparationRequest childRequest;
}

final class _MaterializationOperation {
  const _MaterializationOperation({
    required this.id,
    required this.fingerprint,
  });

  final String id;
  final String fingerprint;
}

final class _EditState {
  const _EditState({
    required this.resources,
    required this.links,
    required this.observed,
    required this.intents,
    required this.initializationFindings,
  });

  factory _EditState.capture(AuthoringEdit draft) => _EditState(
    resources: Map.of(draft._resources),
    links: List.of(draft._links),
    observed: Map.of(draft._observed),
    intents: List.of(draft._intents),
    initializationFindings: List.of(draft._initializationFindings),
  );

  final Map<skir.ResourceId, skir.AuthoringRecord> resources;
  final List<skir.LinkProjection> links;
  final Map<Object, skir.EditExpectation> observed;
  final List<skir.EditIntent> intents;
  final List<skir.InitializationDiagnostic> initializationFindings;

  bool matches(AuthoringEdit draft) =>
      _mapsEqual(resources, draft._resources) &&
      _listsEqual(links, draft._links) &&
      _mapsEqual(observed, draft._observed) &&
      _listsEqual(intents, draft._intents) &&
      _listsEqual(initializationFindings, draft._initializationFindings);
}

bool _mapsEqual<K, V>(Map<K, V> first, Map<K, V> second) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (!second.containsKey(entry.key) || second[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

skir.EditExpectation _value({required skir.ValueLocation at}) =>
    skir.EditExpectation.createValue(at: at, expected: null);
skir.EditExpectation _configuration({required skir.ValueLocation at}) =>
    skir.EditExpectation.createConfiguration(at: at, expected: null);
skir.EditExpectation _exists({required skir.ResourceId resource}) =>
    skir.EditExpectation.createResourceExists(id: resource, expected: false);
Object _factKey(skir.EditExpectation expected) => switch (expected) {
  skir.EditExpectation_valueWrapper(:final value) => ("value", value.at),
  skir.EditExpectation_resourceWrapper(:final value) => ("resource", value.id),
  skir.EditExpectation_resourceExistsWrapper(:final value) => (
    "exists",
    value.id,
  ),
  skir.EditExpectation_configurationWrapper(:final value) => (
    "configuration",
    value.at,
  ),
  skir.EditExpectation_resourceIdsWrapper() => "resources",
  skir.EditExpectation_linksWrapper(:final value) => (
    "links",
    value.resource,
    value.contract,
    value.direction,
  ),
  _ => throw StateError("Unknown edit expectation"),
};
bool _sameExpectation(skir.EditExpectation first, skir.EditExpectation second) {
  if (first is skir.EditExpectation_linksWrapper &&
      second is skir.EditExpectation_linksWrapper) {
    return _factKey(first) == _factKey(second) &&
        first.value.expected.toSet().length ==
            second.value.expected.toSet().length &&
        first.value.expected.toSet().containsAll(second.value.expected);
  }
  if (first is skir.EditExpectation_resourceIdsWrapper &&
      second is skir.EditExpectation_resourceIdsWrapper) {
    return first.value.toSet().length == second.value.toSet().length &&
        first.value.toSet().containsAll(second.value);
  }
  if (_factKey(first) != _factKey(second)) return false;
  if (first is skir.EditExpectation_valueWrapper &&
      second is skir.EditExpectation_valueWrapper) {
    return _sameExpectedValue(first.value.expected, second.value.expected);
  }
  if (first is skir.EditExpectation_resourceWrapper &&
      second is skir.EditExpectation_resourceWrapper) {
    final left = first.value.expected;
    final right = second.value.expected;
    if (left == null || right == null) return left == right;
    return left.configuration == right.configuration &&
        _sameExpectedFields(left.fields, right.fields);
  }
  return first == second;
}

bool _sameExpectedFields(
  Iterable<skir.FieldValue> first,
  Iterable<skir.FieldValue> second,
) {
  final left = {for (final field in first) field.name: field.value};
  final right = {for (final field in second) field.name: field.value};
  return left.length == right.length &&
      left.entries.every(
        (entry) =>
            right.containsKey(entry.key) &&
            _sameExpectedValue(entry.value, right[entry.key]),
      );
}

bool _sameExpectedValue(skir.DataValue? first, skir.DataValue? second) {
  if (first == null || second == null) return first == second;
  return switch ((first, second)) {
    (
      skir.DataValue_recordWrapper(value: final left),
      skir.DataValue_recordWrapper(value: final right),
    ) =>
      _sameExpectedFields(left.fields, right.fields),
    (
      skir.DataValue_namedWrapper(value: final left),
      skir.DataValue_namedWrapper(value: final right),
    ) =>
      left.actualType == right.actualType &&
          _sameExpectedValue(left.payload, right.payload),
    (
      skir.DataValue_listValueWrapper(value: final left),
      skir.DataValue_listValueWrapper(value: final right),
    ) =>
      _sameExpectedItems(left.items, right.items),
    (
      skir.DataValue_setValueWrapper(value: final left),
      skir.DataValue_setValueWrapper(value: final right),
    ) =>
      _sameExpectedItems(left.items, right.items),
    (
      skir.DataValue_mapValueWrapper(value: final left),
      skir.DataValue_mapValueWrapper(value: final right),
    ) =>
      left.rows.length == right.rows.length &&
          Iterable<int>.generate(left.rows.length).every(
            (index) =>
                left.rows.elementAt(index).id ==
                    right.rows.elementAt(index).id &&
                _sameExpectedValue(
                  left.rows.elementAt(index).key,
                  right.rows.elementAt(index).key,
                ) &&
                _sameExpectedValue(
                  left.rows.elementAt(index).value,
                  right.rows.elementAt(index).value,
                ),
          ),
    (
      skir.DataValue_floatWrapper(value: final left),
      skir.DataValue_floatWrapper(value: final right),
    ) =>
      left == right && left.isNegative == right.isNegative ||
          left.isNaN && right.isNaN,
    _ => first == second,
  };
}

bool _sameExpectedItems(
  Iterable<skir.ListItem> first,
  Iterable<skir.ListItem> second,
) =>
    first.length == second.length &&
    Iterable<int>.generate(first.length).every(
      (index) =>
          first.elementAt(index).id == second.elementAt(index).id &&
          _sameExpectedValue(
            first.elementAt(index).value,
            second.elementAt(index).value,
          ),
    );

skir.ValueLocation _root(skir.ResourceId resource) => skir.ValueLocation(
  resource: resource,
  path: skir.ValuePath(segments: const []),
);

skir.NamedTypeUse? _concreteNamed(skir.TypeUse? type) => switch (type) {
  skir.TypeUse_namedWrapper(:final value) => value,
  skir.TypeUse_nullableWrapper(:final value) => _concreteNamed(value.value),
  _ => null,
};

skir.ValuePath? _directFieldPath(skir.RelativeFieldPattern pattern) {
  final segments = <skir.PathSegment>[];
  for (final segment in pattern.segments) {
    if (segment case skir.FieldPatternSegment_fieldWrapper(:final value)) {
      segments.add(skir.PathSegment.createField(name: value.name));
    } else {
      return null;
    }
  }
  return skir.ValuePath(segments: segments);
}

skir.DataValue? _replaceCollectionItems(
  skir.DataValue value,
  List<skir.ListItem>? Function(List<skir.ListItem> items) update,
) => switch (value) {
  skir.DataValue_namedWrapper(:final value) => switch (_replaceCollectionItems(
    value.payload,
    update,
  )) {
    final payload? => skir.DataValue.createNamed(
      actualType: value.actualType,
      payload: payload,
    ),
    null => null,
  },
  skir.DataValue_listValueWrapper(:final value) => switch (update(
    value.items.toList(),
  )) {
    final items? => skir.DataValue.createListValue(items: items),
    null => null,
  },
  skir.DataValue_setValueWrapper(:final value) => switch (update(
    value.items.toList(),
  )) {
    final items? => skir.DataValue.createSetValue(items: items),
    null => null,
  },
  _ => null,
};

bool _containsLink(skir.DataValue value) => switch (value) {
  skir.DataValue_linkWrapper() => true,
  skir.DataValue_namedWrapper(:final value) => _containsLink(value.payload),
  skir.DataValue_recordWrapper(:final value) => value.fields.any(
    (field) => _containsLink(field.value),
  ),
  skir.DataValue_listValueWrapper(:final value) ||
  skir.DataValue_setValueWrapper(
    :final value,
  ) => value.items.any((item) => _containsLink(item.value)),
  skir.DataValue_mapValueWrapper(:final value) => value.rows.any(
    (entry) => _containsLink(entry.key) || _containsLink(entry.value),
  ),
  _ => false,
};

skir.TypeDefinitionId? _configurationRoot(skir.TypeSelection selection) =>
    switch (selection) {
      skir.TypeSelection_completeWrapper(:final value) => value.definition,
      skir.TypeSelection_pendingWrapper(:final value) => value.definition,
      _ => null,
    };

final class _AuthoringDefaults {
  const _AuthoringDefaults(this.catalog);
  final CheckedEditorCatalog? catalog;
  skir.DataValue _defaultForNamed(
    skir.NamedTypeUse actual,
    Set<skir.NamedTypeUse> visiting,
  ) {
    if (visiting.contains(actual)) return skir.DataValue.unfilled;
    final checked = catalog;
    if (checked == null) return skir.DataValue.unfilled;
    final published = checked.published(actual.definition);
    if (published == null) return skir.DataValue.unfilled;
    final selection = skir.TypeSelection.wrapComplete(actual);
    final descriptor = checked.initialization(actual.definition);
    final payload = switch (published.definition.representation) {
      skir.RepresentationTemplate_scalarWrapper(:final value) => _scalarDefault(
        value.kind,
      ),
      skir.RepresentationTemplate_sequenceWrapper(:final value) =>
        value.kind == skir.CollectionKind.list
            ? skir.DataValue.createListValue(items: const [])
            : skir.DataValue.createSetValue(items: const []),
      skir.RepresentationTemplate_mappingWrapper() =>
        skir.DataValue.createMapValue(rows: const []),
      skir.RepresentationTemplate_enumerationWrapper(:final value) =>
        value.cases.firstOrNull == null
            ? skir.DataValue.unfilled
            : skir.DataValue.wrapEnumCase(value.cases.first.key),
      skir.RepresentationTemplate_linkWrapper() => skir.DataValue.unfilled,
      skir.RepresentationTemplate_recordWrapper(:final value) =>
        value.abstract_
            ? skir.DataValue.unfilled
            : skir.DataValue.createRecord(
                fields: [
                  for (final field in checked.fields(selection))
                    skir.FieldValue(
                      name: field.template.key,
                      value: _fieldDefault(
                        field,
                        descriptor: descriptor,
                        visiting: {...visiting, actual},
                      ),
                    ),
                ],
              ),
      skir.RepresentationTemplate_unknown() => skir.DataValue.unfilled,
    };
    if (payload == skir.DataValue.unfilled) return payload;
    return skir.DataValue.createNamed(actualType: actual, payload: payload);
  }

  skir.DataValue _fieldDefault(
    AppliedEditorField field, {
    required skir.InitializationDescriptor? descriptor,
    required Set<skir.NamedTypeUse> visiting,
  }) {
    final checked = catalog;
    final captured = descriptor?.captured
        .where((candidate) => candidate.field == field.template.owner)
        .firstOrNull
        ?.value;
    if (captured != null) return captured;
    if (checked!.hasConstructorDefault(field.template.owner)) {
      return skir.DataValue.unfilled;
    }
    return _defaultForType(field.type, visiting);
  }

  skir.DataValue _defaultForType(
    skir.TypeUse? type,
    Set<skir.NamedTypeUse> visiting,
  ) => switch (type) {
    skir.TypeUse_nullableWrapper() => skir.DataValue.null_,
    skir.TypeUse_scalarWrapper(:final value) => _scalarDefault(value),
    skir.TypeUse_namedWrapper(:final value) => _defaultForNamed(
      value,
      visiting,
    ),
    _ => skir.DataValue.unfilled,
  };

  skir.DataValue _scalarDefault(skir.ScalarKind kind) => switch (kind) {
    skir.ScalarKind.unit => skir.DataValue.unit,
    skir.ScalarKind.boolean => skir.DataValue.wrapBoolean(false),
    skir.ScalarKind.text => skir.DataValue.wrapStringValue(""),
    skir.ScalarKind_integerWrapper() => skir.DataValue.wrapInteger("0"),
    skir.ScalarKind_floatWrapper() => skir.DataValue.wrapFloat(0),
    skir.ScalarKind.decimal => skir.DataValue.wrapDecimal("0"),
    skir.ScalarKind.bytes => skir.DataValue.wrapBytes(skir.ByteString.empty),
    skir.ScalarKind.duration => skir.DataValue.createDuration(
      value: skir.Duration(milliseconds: 0),
    ),
    skir.ScalarKind.timestamp => skir.DataValue.unfilled,
    _ => skir.DataValue.unfilled,
  };
}
