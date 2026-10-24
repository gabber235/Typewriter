part of "realm_edit_model.dart";

/// Owns a private working graph, ordered intent, and original fact witnesses for one operation.
///
/// Reads can see prior writes, while recorded expectations always come from the
/// captured baseline. Forked preparation is adopted only after its local checks
/// succeed. References use relation operations so inverse values and graph projections
/// stay together. [prepare] returns proposed intent; the editing workspace owns its
/// admission into shared local work and Realm admission owns the saved write.
final class AuthoringEdit implements PortableAuthoringEdit {
  factory AuthoringEdit({
    required skir.CatalogGeneration generation,
    required Iterable<skir.AuthoringResource> resources,
    required Iterable<skir.LinkProjection> links,
    CheckedEditorCatalog? catalog,
  }) {
    final entries = resources.toList(growable: false);
    final records = {for (final entry in entries) entry.id: entry.content};
    final projections = links.toList(growable: false);
    return AuthoringEdit._(
      generation: generation,
      catalog: catalog,
      records: records,
      links: projections,
      baseline: AuthoringFacts.capture(resources: records, links: projections),
    );
  }

  AuthoringEdit._({
    required this.generation,
    required this.catalog,
    required Map<skir.ResourceId, skir.AuthoringRecord> records,
    required Iterable<skir.LinkProjection> links,
    required AuthoringFacts baseline,
  }) : _resources = Map.of(records),
       _links = List.of(links),
       _baselineFacts = baseline;
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
  final List<skir.LinkProjection> _links;
  final AuthoringFacts _baselineFacts;
  final Map<Object, skir.EditExpectation> _observed = {};
  final List<skir.EditIntent> _intents = [];
  final List<LocatedInitializationFinding> _initializationFindings = [];
  int _inheritedFindings = 0;

  List<skir.EditIntent> get intents => List.unmodifiable(_intents);

  @override
  Map<skir.ResourceId, skir.AuthoringRecord> get resources =>
      Map.unmodifiable(_resources);

  @override
  List<skir.LinkProjection> get links => List.unmodifiable(_links);

  List<skir.EditExpectation> get expectations =>
      List.unmodifiable(_observed.values);

  List<LocatedInitializationFinding> get initializationFindings =>
      List.unmodifiable(_initializationFindings);

  @override
  void observeExpressionReads(Iterable<skir.ValueLocation> reads) {
    for (final location in reads) {
      _observePath(location);
      _observe(_value(at: location));
    }
  }

  @override
  bool stageExpressionEdit(
    Iterable<skir.ValueLocation> reads,
    bool Function(PortableAuthoringEdit edit) edit,
  ) {
    final branch = fork();
    if (!edit(branch)) return false;
    branch.observeExpressionReads(reads);
    _adopt(branch);
    return true;
  }

  AuthoringEdit fork() =>
      AuthoringEdit._(
          generation: generation,
          catalog: catalog,
          records: _resources,
          links: _links,
          baseline: _baselineFacts,
        )
        .._observed.addAll(_observed)
        .._intents.addAll(_intents)
        .._initializationFindings.addAll(_initializationFindings)
        .._inheritedFindings = _inheritedFindings
        .._failure = _failure;

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
        entry.key: skir.AuthoringResource(id: entry.key, content: entry.value),
    },
    links: List.unmodifiable(_links),
    revision: revision,
    initializationFindings: initializationFindings,
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

  /// Composes prepared intent only while its catalog and expected working facts match.
  /// Failure leaves this branch unchanged because replay occurs on a fork.
  void applyPrepared(skir.PreparedEdit prepared) {
    if (prepared.catalog != generation) {
      throw StateError("The editor catalog changed");
    }
    final conflicts = currentFacts.conflicts(prepared.expectations);
    if (conflicts.isNotEmpty) {
      throw AuthoringCompositionFailure(conflicts);
    }
    final branch = fork();
    for (final expected in prepared.expectations) {
      branch._observe(expected);
    }
    for (final intent in prepared.intents) {
      if (branch._replay(intent) case final message?) {
        throw StateError(message);
      }
    }
    branch.requireValid();
    _adopt(branch);
  }

  AuthoringFacts get currentFacts =>
      AuthoringFacts.capture(resources: _resources, links: _links);

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
        _locatedInitializationFindings(plan.containing, containing, generation),
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
          _locatedInitializationFindings(plan.location, child, generation),
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
          skir.ValueLocation(
            resource: location.resource,
            path: skir.ValuePath(
              segments: [
                ...location.path.segments,
                skir.PathSegment.createItem(id: item),
              ],
            ),
          ),
          prepared,
          generation,
        ),
      );
      _adopt(branch);
    }
    return result;
  }

  @override
  skir.DataValue defaultValue(skir.TypeUse? type) =>
      _AuthoringDefaults(catalog).forType(type);

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
        _locatedInitializationFindings(location, prepared, generation),
      );
      _adopt(branch);
    }
    return result;
  }

  void create(skir.ResourceId id, skir.AuthoringRecord record) {
    if (_resources.containsKey(id)) {
      throw StateError("The resource already exists");
    }
    _observe(_exists(resource: id));
    _resources[id] = record;
    _intents.add(skir.EditIntent.createCreateResource(id: id, record: record));
  }

  void createPrepared(skir.ResourceId id, skir.PreparedValue prepared) {
    create(id, prepared.recordContent);
    _initializationFindings.addAll(
      _locatedInitializationFindings(_root(id), prepared, generation),
    );
  }

  @override
  void delete(skir.ResourceId id) => _delete(id);

  @override
  void connect(
    skir.LinkOccurrence source,
    skir.ResourceId target, {
    skir.CounterpartChoice? counterpart,
  }) => _connect(source, target, counterpart: counterpart);

  @override
  void disconnect(skir.LinkOccurrence occurrence) =>
      _disconnectOccurrence(occurrence);

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
    if (current.configuration.definition != configuration.definition) {
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
    _observed.putIfAbsent(
      _factKey(expected),
      () => _baselineFacts.observe(expected),
    );
  }

  PortablePathResult<skir.AuthoringRecord> _materializeParents(
    skir.ValueLocation target,
  ) {
    final checked = catalog;
    if (checked == null || target.path.segments.length < 2) {
      return PortablePathValue(_resources[target.resource]!);
    }
    final record = _resources[target.resource]!;
    var selection = record.configuration;
    var currentPath = <skir.PathSegment>[];
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
          return const PortablePathUnavailable(
            "The parent field needs prepared initialization",
          );
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
          if (_isMapRow(record, currentPath)) continue;
          return const PortablePathUnavailable("The collection item is absent");
        }
        final childValue = (child as PortablePathValue<skir.DataValue>).value;
        selection = switch (childValue) {
          skir.DataValue_namedWrapper(:final value) =>
            skir.TypeSelection.wrapComplete(value.actualType),
          _ => skir.TypeSelection.unknown,
        };
      }
    }
    return PortablePathValue(record);
  }

  bool _isMapRow(skir.AuthoringRecord record, List<skir.PathSegment> path) {
    if (path.lastOrNull is skir.PathSegment_itemWrapper) {
      final parent = record.readAt(
        skir.ValuePath(segments: path.take(path.length - 1)),
      );
      if (parent case PortablePathValue(value: final value)) {
        final payload = value.authoredPayload;
        if (payload case skir.DataValue_mapValueWrapper(value: final map)) {
          final item = (path.last as skir.PathSegment_itemWrapper).value.id;
          return map.rows.any((row) => row.id == item);
        }
      }
    }
    return false;
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
        if (childValue == skir.DataValue.unfilled ||
            childValue == skir.DataValue.null_) {
          final location = skir.ValueLocation(
            resource: target.resource,
            path: skir.ValuePath(segments: currentPath),
          );
          final supplied = fields
              .where((candidate) => candidate.name != value.name)
              .toList(growable: false);
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
              catalog: generation,
              target: skir.PreparationTarget.wrapRecord(selection),
              suppliedValue: skir.DataValue.createRecord(fields: supplied),
            ),
            childRequest: skir.ValuePreparationRequest(
              catalog: generation,
              target: skir.PreparationTarget.wrapRecord(
                skir.TypeSelection.wrapComplete(expected),
              ),
              suppliedValue: skir.DataValue.createRecord(fields: const []),
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
        if (child is! PortablePathValue<skir.DataValue>) {
          if (_isMapRow(root, currentPath)) continue;
          return null;
        }
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
    final initialized = defaultValue(expected);
    return initialized.authoredItems != null ||
            initialized.authoredPayload is skir.DataValue_mapValueWrapper
        ? initialized
        : current;
  }
}

Iterable<LocatedInitializationFinding> _locatedInitializationFindings(
  skir.ValueLocation base,
  skir.PreparedValue prepared,
  skir.CatalogGeneration generation,
) sync* {
  final record = prepared.recordContent;
  final payload = skir.DataValue.createRecord(fields: record.fields);
  final expected = switch (record.configuration) {
    skir.TypeSelection_completeWrapper(:final value)
        when base.path.segments.isNotEmpty =>
      skir.DataValue.createNamed(actualType: value, payload: payload),
    _ => payload,
  };
  final evidence = skir.DiagnosticEvidence(
    catalog: generation,
    expectations: [
      skir.EditExpectation.createValue(at: base, expected: expected),
      if (base.path.segments.isEmpty)
        skir.EditExpectation.createConfiguration(
          at: base,
          expected: record.configuration,
        ),
    ],
  );
  for (final finding in prepared.findings) {
    yield LocatedInitializationFinding(
      location: skir.ValueLocation(
        resource: base.resource,
        path: skir.ValuePath(
          segments: [...base.path.segments, ...?finding.relativePath?.segments],
        ),
      ),
      diagnostic: finding,
      evidence: evidence,
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
  final List<LocatedInitializationFinding> initializationFindings;

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
