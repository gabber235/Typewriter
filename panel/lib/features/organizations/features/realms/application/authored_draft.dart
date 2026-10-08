import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredDraft {
  AuthoredDraft({
    required this.generation,
    required Iterable<skir.AuthoringResource> resources,
    required Iterable<skir.LinkProjection> links,
    this.catalog,
  }) : _resources = {
         for (final resource in resources) resource.id: resource.content,
       },
       _links = List.of(links),
       _baselineResources = {
         for (final resource in resources) resource.id: resource.content,
       },
       _baselineLinks = List.of(links);

  factory AuthoredDraft.fromState(
    skir.AuthoringState source, {
    CheckedEditorCatalog? catalog,
  }) => AuthoredDraft(
    generation: source.generation,
    resources: source.resources,
    links: source.links,
    catalog: catalog,
  );
  final skir.CatalogGeneration generation;
  final CheckedEditorCatalog? catalog;
  final Map<skir.ResourceId, skir.AuthoringRecord> _resources;
  final List<skir.LinkProjection> _links;
  final Map<skir.ResourceId, skir.AuthoringRecord> _baselineResources;
  final List<skir.LinkProjection> _baselineLinks;
  final Map<Object, skir.EditExpectation> _observed = {};
  final List<skir.EditIntent> _intents = [];
  final List<skir.InitializationDiagnostic> _initializationFindings = [];
  final Map<skir.ValueLocation, _MaterializationOperation>
  _materializationOperations = {};

  List<skir.EditIntent> get intents => List.unmodifiable(_intents);

  Map<skir.ResourceId, skir.AuthoringRecord> get resources =>
      Map.unmodifiable(_resources);

  List<skir.LinkProjection> get links => List.unmodifiable(_links);

  List<skir.EditExpectation> get expectations =>
      List.unmodifiable(_observed.values);

  List<skir.InitializationDiagnostic> get initializationFindings =>
      List.unmodifiable(_initializationFindings);

  void observeExpressionReads(Iterable<PortableExpressionRead> reads) {
    for (final read in reads) {
      final location = read.location;
      if (location == null) continue;
      _observePath(location);
      _observe(_value(at: location));
    }
  }

  bool stageExpressionEdit(
    Iterable<PortableExpressionRead> reads,
    bool Function(AuthoredDraft draft) edit,
  ) {
    final branch = fork();
    if (!edit(branch)) return false;
    branch.observeExpressionReads(reads);
    _adopt(branch);
    return true;
  }

  AuthoredDraft fork() {
    final branch = AuthoredDraft(
      generation: generation,
      resources: [
        for (final entry in _resources.entries)
          skir.AuthoringResource(
            id: entry.key,
            definition:
                catalog?.resourceDefinition(entry.value.configuration)?.id ??
                skir.ResourceDefinitionId.defaultInstance,
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
    branch._materializationOperations.addAll(_materializationOperations);
    return branch;
  }

  AuthoredDraftRebase rebaseOnto(AuthoredDraft baseline) {
    if (generation != baseline.generation) {
      return const AuthoredDraftRebaseFailed("The editor catalog changed");
    }
    for (final expected in _observed.values) {
      final actual = baseline._actual(expected);
      if (!_sameExpectation(actual, expected)) {
        return AuthoredDraftRebaseConflict(expected: expected, actual: actual);
      }
    }
    final next = baseline.fork();
    for (final intent in _intents) {
      final failure = next._replay(intent);
      if (failure != null) return AuthoredDraftRebaseFailed(failure);
    }
    for (final expected in _observed.values) {
      next._observed[_factKey(expected)] = expected;
    }
    return AuthoredDraftRebased(next);
  }

  AuthoredDraftRebase rebaseTailOnto(
    AuthoredDraft baseline, {
    required int acceptedIntentCount,
  }) {
    if (generation != baseline.generation) {
      return const AuthoredDraftRebaseFailed("The editor catalog changed");
    }
    if (acceptedIntentCount < 0 || acceptedIntentCount > _intents.length) {
      return const AuthoredDraftRebaseFailed(
        "The accepted edit prefix no longer matches the local draft",
      );
    }
    final accepted = AuthoredDraft(
      generation: generation,
      resources: [
        for (final entry in _baselineResources.entries)
          skir.AuthoringResource(
            id: entry.key,
            definition: skir.ResourceDefinitionId.defaultInstance,
            content: entry.value,
          ),
      ],
      links: _baselineLinks,
      catalog: catalog,
    );
    for (final intent in _intents.take(acceptedIntentCount)) {
      final failure = accepted._replay(intent);
      if (failure != null) return AuthoredDraftRebaseFailed(failure);
    }
    for (final expected in _observed.values) {
      final afterSave = accepted._actual(expected, original: false);
      final actual = baseline._actual(expected);
      if (!_sameExpectation(actual, afterSave)) {
        return AuthoredDraftRebaseConflict(expected: afterSave, actual: actual);
      }
    }
    final next = baseline.fork();
    for (final intent in _intents.skip(acceptedIntentCount)) {
      final failure = next._replay(intent);
      if (failure != null) return AuthoredDraftRebaseFailed(failure);
    }
    for (final expected in _observed.values) {
      next._observed[_factKey(expected)] = accepted._actual(
        expected,
        original: false,
      );
    }
    next._initializationFindings.addAll(_initializationFindings);
    next._materializationOperations.addAll(_materializationOperations);
    return AuthoredDraftRebased(next);
  }

  skir.PreparedEdit prepare() => skir.PreparedEdit(
    catalog: generation,
    expectations: expectations,
    intents: intents,
  );

  skir.AuthoringRecord? resource(skir.ResourceId id) => _resources[id];

  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) {
    _observePath(location);
    _observe(_value(at: location));
    final record = _resources[location.resource];
    if (record == null) {
      return const PortablePathUnavailable("The resource is absent");
    }
    return record.readAt(location.path);
  }

  PortablePathResult<skir.AuthoringRecord> set(
    skir.ValueLocation location,
    skir.DataValue value,
  ) {
    final record = _resources[location.resource];
    if (record == null) {
      return const PortablePathUnavailable("The resource is absent");
    }
    final current = record.readAt(location.path);
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

  Future<PortablePathResult<skir.AuthoringRecord>> setWithInitialization(
    skir.ValueLocation location,
    skir.DataValue value,
    Future<skir.PreparedCreation> Function(skir.InitializationRequest request)
    prepare,
  ) async {
    final baseline = _DraftState.capture(this);
    final working = fork();
    var result = working.set(location, value);
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
          "The draft changed while the parent field was being initialized",
        );
      }
      if (!working._preparedRecordIsUsable(containing, plan.request)) {
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
      var parent = containing.record.fields
          .where((field) => field.name == plan.field)
          .firstOrNull
          ?.value;
      if (parent == null ||
          parent == skir.DataValue.unfilled ||
          parent == skir.DataValue.null_) {
        final child = await prepare(plan.childRequest);
        if (!baseline.matches(this)) {
          return const PortablePathUnavailable(
            "The draft changed while the parent field was being initialized",
          );
        }
        if (!working._preparedRecordIsUsable(child, plan.childRequest)) {
          return const PortablePathUnavailable(
            "The parent field initialization needs attention",
          );
        }
        working._initializationFindings.addAll(
          _locatedInitializationFindings(plan.location.path, child.findings),
        );
        final actual = switch (child.record.configuration) {
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
          payload: skir.DataValue.createRecord(fields: child.record.fields),
        );
      }
      if (_containsLink(parent)) {
        return const PortablePathUnavailable(
          "The prepared parent contains relations that need explicit choices",
        );
      }
      final staged = working.set(plan.location, parent);
      if (staged case PortablePathUnavailable()) return staged;
      working._materializationOperations.remove(plan.location);
      result = working.set(location, value);
    }
    if (result case PortablePathValue()) {
      if (!baseline.matches(this)) {
        return const PortablePathUnavailable(
          "The draft changed while the parent field was being initialized",
        );
      }
      _adopt(working);
    }
    return result;
  }

  bool _preparedRecordIsUsable(
    skir.PreparedCreation prepared,
    skir.InitializationRequest request,
  ) {
    if (prepared.record.configuration != request.type) return false;
    final actual = prepared.record.fields.map((field) => field.name).toList();
    if (actual.toSet().length != actual.length) return false;
    final expected = catalog
        ?.fields(request.type)
        .map((field) => field.template.key)
        .toSet();
    return expected != null &&
        actual.length == expected.length &&
        actual.toSet().containsAll(expected);
  }

  void _adopt(AuthoredDraft source) {
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

  PortablePathResult<skir.AuthoringRecord> setPayload(
    skir.ValueLocation location,
    skir.DataValue payload,
  ) {
    final current = read(location);
    return switch (current) {
      PortablePathValue(:final value) => set(
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
  }) => set(
    location,
    expected is skir.TypeUse_nullableWrapper
        ? skir.DataValue.null_
        : skir.DataValue.unfilled,
  );

  PortablePathResult<skir.AuthoringRecord> insert(
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

  PortablePathResult<skir.AuthoringRecord> insertPrepared(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ItemId item,
    skir.InitializationRequest request,
    skir.PreparedCreation prepared,
  ) {
    if (!_preparedRecordIsUsable(prepared, request)) {
      return const PortablePathUnavailable(
        "The prepared collection item does not match the requested type",
      );
    }
    final actual = switch (prepared.record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (actual == null) {
      return const PortablePathUnavailable(
        "The prepared collection item is not a complete named value",
      );
    }
    final branch = fork();
    final result = branch.insert(
      location,
      after,
      skir.ListItem(
        id: item,
        value: skir.DataValue.createNamed(
          actualType: actual,
          payload: skir.DataValue.createRecord(fields: prepared.record.fields),
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

  skir.DataValue defaultValue(skir.TypeUse? type) =>
      _defaultForType(type, const {});

  PortablePathResult<skir.AuthoringRecord> remove(
    skir.ValueLocation location,
    skir.ItemId item,
  ) {
    _observeCollection(location);
    return _updateCollection(location, (items) {
      if (items.every((candidate) => candidate.id != item)) return null;
      return items.where((candidate) => candidate.id != item).toList();
    }, skir.EditIntent.createRemove(at: location, item: item));
  }

  PortablePathResult<skir.AuthoringRecord> move(
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

  PortablePathResult<skir.AuthoringRecord> replaceMap(
    skir.ValueLocation location,
    Iterable<skir.MapRow> rows,
  ) {
    final previous = Map<Object, skir.EditExpectation>.of(_observed);
    _observeCollection(location);
    final result = setPayload(
      location,
      skir.DataValue.createMapValue(rows: rows),
    );
    if (result case PortablePathUnavailable()) {
      _observed
        ..clear()
        ..addAll(previous);
    }
    return result;
  }

  PortablePathResult<skir.AuthoringRecord> applyPreparedRecord(
    skir.ValueLocation location,
    skir.InitializationRequest request,
    skir.PreparedCreation prepared,
  ) {
    if (!_preparedRecordIsUsable(prepared, request)) {
      return const PortablePathUnavailable(
        "The prepared form does not match the requested type",
      );
    }
    final actual = switch (prepared.record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (actual == null) {
      return const PortablePathUnavailable(
        "The prepared form is not a complete named value",
      );
    }
    final branch = fork();
    final result = branch.set(
      location,
      skir.DataValue.createNamed(
        actualType: actual,
        payload: skir.DataValue.createRecord(fields: prepared.record.fields),
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

  void create(skir.ResourceId id, skir.AuthoringRecord record) {
    _observe(_exists(resource: id));
    _resources[id] = record;
    _intents.add(skir.EditIntent.createCreateResource(id: id, record: record));
  }

  void createPrepared(skir.ResourceId id, skir.PreparedCreation prepared) {
    create(id, prepared.record);
    _initializationFindings.addAll(
      _locatedInitializationFindings(
        skir.ValuePath(segments: const []),
        prepared.findings,
      ),
    );
  }

  void delete(skir.ResourceId id) {
    _observe(_exists(resource: id));
    _observe(_configuration(at: _root(id)));
    _observeIncoming(id, null);
    _observeDeletionRelations(id);
    _resources.remove(id);
    _links.removeWhere((link) => link.first == id || link.second == id);
    _intents.add(skir.EditIntent.createDeleteResource(id: id));
  }

  void connect(
    skir.LinkOccurrence source,
    skir.ResourceId target, {
    skir.CounterpartChoice? counterpart,
  }) {
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
    final result = insert(
      skir.ValueLocation(resource: location.resource, path: containingPath),
      items.lastOrNull?.id,
      skir.ListItem(id: item, value: skir.DataValue.unfilled),
    );
    if (result case PortablePathUnavailable(:final message)) {
      throw StateError(message);
    }
  }

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
    if (relation == null) return;
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
    final targetRecord = _resources[target];
    if (targetRecord == null) return null;
    final actual = switch (choice.prepared.record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (actual == null) return null;
    final materialized = skir.DataValue.createNamed(
      actualType: actual,
      payload: skir.DataValue.createRecord(
        fields: choice.prepared.record.fields,
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
        if (authoredPathStartsWith(path, embedded.path)) {
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
    if (record == null) return;
    final current = record.readAt(location.path);
    final payload = skir.DataValue.createLink(
      endpoint: endpoint,
      target: target,
    );
    final replacement = switch (current) {
      PortablePathValue(value: final skir.DataValue value)
          when value is skir.DataValue_namedWrapper =>
        value.withAuthoredPayload(payload),
      _ => switch (_concreteNamed(
        catalog?.valueTypeAt(record.configuration, location.path),
      )) {
        final actual? => skir.DataValue.createNamed(
          actualType: actual,
          payload: payload,
        ),
        null => null,
      },
    };
    if (replacement == null) return;
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
      return;
    }
    final item = (segments.last as skir.PathSegment_itemWrapper).value.id;
    final parent = skir.ValuePath(segments: segments.take(segments.length - 1));
    final current = record.readAt(parent);
    if (current case PortablePathValue(value: final value)) {
      final containing = skir.ValueLocation(
        resource: location.resource,
        path: parent,
      );
      final updated = _replaceCollectionItems(
        _collectionValue(containing, value),
        (items) {
          if (items.any((candidate) => candidate.id == item)) return null;
          return [...items, skir.ListItem(id: item, value: replacement)];
        },
      );
      if (updated == null) return;
      final staged = record.replaceAt(parent, updated);
      if (staged case PortablePathValue(value: final next)) {
        _resources[location.resource] = next;
      }
    }
  }

  void _stageLinkClear(skir.ValueLocation location) {
    final record = _resources[location.resource];
    if (record == null) return;
    final segments = location.path.segments.toList(growable: false);
    if (segments.isNotEmpty && segments.last is skir.PathSegment_itemWrapper) {
      final item = (segments.last as skir.PathSegment_itemWrapper).value.id;
      final parent = skir.ValuePath(
        segments: segments.take(segments.length - 1),
      );
      final current = record.readAt(parent);
      if (current case PortablePathValue(value: final value)) {
        final updated = _replaceCollectionItems(
          value,
          (items) => items
              .where((candidate) => candidate.id != item)
              .toList(growable: false),
        );
        if (updated != null) {
          final staged = record.replaceAt(parent, updated);
          if (staged case PortablePathValue(value: final next)) {
            _resources[location.resource] = next;
          }
        }
      }
      return;
    }
    final expected = catalog?.valueTypeAt(record.configuration, location.path);
    final replacement = expected is skir.TypeUse_nullableWrapper
        ? skir.DataValue.null_
        : skir.DataValue.unfilled;
    final updated = record.replaceAt(location.path, replacement);
    if (updated case PortablePathValue(value: final staged)) {
      _resources[location.resource] = staged;
    }
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
    _observe(_value(at: location));
    _observePath(location);
    _observe(_configuration(at: location));
    _observeIncoming(location.resource, null);
    _intents.add(skir.EditIntent.createRetag(at: location, type: type));
  }

  void configureResource(
    skir.ResourceId resource,
    skir.TypeSelection configuration,
  ) {
    final current = _resources[resource];
    if (current == null) return;
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
        result = set(value.at, value.value);
      case skir.EditIntent_insertWrapper(:final value):
        result = insert(value.at, value.after, value.item);
      case skir.EditIntent_removeWrapper(:final value):
        result = remove(value.at, value.item);
      case skir.EditIntent_moveWrapper(:final value):
        result = move(value.at, value.item, value.after);
      case skir.EditIntent_connectRelationWrapper(:final value):
        connect(value.source, value.target, counterpart: value.counterpart);
      case skir.EditIntent_disconnectRelationWrapper(:final value):
        _disconnect(value);
      case skir.EditIntent_retagWrapper(:final value):
        retag(value.at, value.type);
      case skir.EditIntent_configureResourceWrapper(:final value):
        configureResource(value.resource, value.configuration);
      case skir.EditIntent_unknown():
        return "The draft contains an unknown edit";
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

  void _observeDeletionRelations(skir.ResourceId requested) {
    final deleting = <skir.ResourceId>{requested};
    final pending = <skir.ResourceId>[requested];
    final contracts = <skir.RelationId, skir.RelationContract>{};
    if (catalog case final checked?) {
      for (final relation in checked.snapshot.relations) {
        contracts[relation.id] = relation;
      }
    }
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final link in _links.where(
        (link) => link.first == current || link.second == current,
      )) {
        final contract = contracts[link.contract];
        if (contract == null) continue;
        final endpoint = link.first == current
            ? contract.first
            : contract.second;
        if (endpoint.onDelete != skir.RelationDeletePolicy.cascade) {
          continue;
        }
        final related = link.first == current ? link.second : link.first;
        if (deleting.add(related)) pending.add(related);
      }
    }
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
            request: skir.InitializationRequest(
              id: skir.InitializationRequestId(
                value: "panel:materialize:${operation.id}:containing",
              ),
              catalog: generation,
              type: selection,
              supplied: supplied,
              intentHash: containingIdentity,
            ),
            childRequest: skir.InitializationRequest(
              id: skir.InitializationRequestId(
                value: "panel:materialize:${operation.id}:child",
              ),
              catalog: generation,
              type: skir.TypeSelection.wrapComplete(expected),
              supplied: const [],
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
  ) {
    if (visiting.contains(actual)) return skir.DataValue.unfilled;
    final checked = catalog!;
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
    final checked = catalog!;
    final captured = descriptor?.captured
        .where((candidate) => candidate.field == field.template.owner)
        .firstOrNull
        ?.value;
    if (captured != null) return captured;
    if (checked.hasConstructorDefault(field.template.owner)) {
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

  PortablePathResult<skir.AuthoringRecord> _updateCollection(
    skir.ValueLocation location,
    List<skir.ListItem>? Function(List<skir.ListItem> items) update,
    skir.EditIntent intent,
  ) {
    final current = read(location);
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
    return initialized.authoredItems == null ? current : initialized;
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

sealed class AuthoredDraftRebase {
  const AuthoredDraftRebase();
}

final class AuthoredDraftRebased extends AuthoredDraftRebase {
  const AuthoredDraftRebased(this.draft);

  final AuthoredDraft draft;
}

final class AuthoredDraftRebaseFailed extends AuthoredDraftRebase {
  const AuthoredDraftRebaseFailed(this.message);

  final String message;
}

final class AuthoredDraftRebaseConflict extends AuthoredDraftRebase {
  const AuthoredDraftRebaseConflict({
    required this.expected,
    required this.actual,
  });

  final skir.EditExpectation expected;
  final skir.EditExpectation actual;
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
  final skir.InitializationRequest request;
  final skir.InitializationRequest childRequest;
}

final class _MaterializationOperation {
  const _MaterializationOperation({
    required this.id,
    required this.fingerprint,
  });

  final String id;
  final String fingerprint;
}

final class _DraftState {
  const _DraftState({
    required this.resources,
    required this.links,
    required this.observed,
    required this.intents,
    required this.initializationFindings,
  });

  factory _DraftState.capture(AuthoredDraft draft) => _DraftState(
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

  bool matches(AuthoredDraft draft) =>
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

skir.DataValue valueAt(skir.AuthoringRecord record, skir.ValuePath path) =>
    switch (record.readAt(path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => skir.DataValue.unfilled,
    };

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
