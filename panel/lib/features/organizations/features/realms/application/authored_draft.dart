import "dart:convert";

import "package:crypto/crypto.dart";
import "package:skir_client/skir_client.dart" show ByteString;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/checking.dart"
    as checking;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/duration.dart"
    as kernel;
import "package:typewriter_panel/shared/editors/application/checked_editor_catalog.dart";
import "package:typewriter_panel/shared/editors/application/portable_expression.dart";
import "package:typewriter_panel/shared/editors/application/portable_value_tree.dart";
import "package:uuid/uuid.dart";

final class AuthoredDraft {
  AuthoredDraft({
    required this.snapshot,
    required this.generation,
    required Iterable<authoring.AuthoringResource> resources,
    required Iterable<authoring.LinkProjection> links,
    required Iterable<checking.InputObservation> observations,
    required this.absentInputToken,
    this.catalog,
  }) : _resources = {
         for (final resource in resources) resource.id: resource.content,
       },
       _links = List.of(links),
       _original = {
         for (final observation in observations)
           observation.identity: observation,
       };

  factory AuthoredDraft.fromSnapshot(
    authoring.AuthoringSnapshot source, {
    CheckedEditorCatalog? catalog,
  }) => AuthoredDraft(
    snapshot: source.snapshot,
    generation: source.generation,
    resources: source.resources,
    links: source.links,
    observations: source.observations,
    absentInputToken: source.absentInputToken,
    catalog: catalog,
  );

  final types.SnapshotId snapshot;
  final types.CatalogGeneration generation;
  final types.InputToken absentInputToken;
  final CheckedEditorCatalog? catalog;
  final Map<types.ResourceId, types.AuthoringRecord> _resources;
  final List<authoring.LinkProjection> _links;
  final Map<checking.InputIdentity, checking.InputObservation> _original;
  final Map<checking.InputIdentity, checking.InputObservation> _observed = {};
  final List<authoring.EditIntent> _intents = [];
  final List<diagnostic_wire.InitializationDiagnostic> _initializationFindings =
      [];
  final Map<types.ValueLocation, _MaterializationOperation>
  _materializationOperations = {};

  List<authoring.EditIntent> get intents => List.unmodifiable(_intents);

  Map<types.ResourceId, types.AuthoringRecord> get resources =>
      Map.unmodifiable(_resources);

  List<authoring.LinkProjection> get links => List.unmodifiable(_links);

  List<checking.InputObservation> get observations =>
      List.unmodifiable(_observed.values);

  List<diagnostic_wire.InitializationDiagnostic> get initializationFindings =>
      List.unmodifiable(_initializationFindings);

  void observeExpressionReads(Iterable<PortableExpressionRead> reads) {
    _observeCatalog();
    for (final read in reads) {
      final location = read.location;
      if (location == null) continue;
      _observePath(location);
      _observe(checking.InputIdentity.createValue(at: location));
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
      snapshot: snapshot,
      generation: generation,
      resources: [
        for (final entry in _resources.entries)
          authoring.AuthoringResource(
            id: entry.key,
            definition:
                catalog?.resourceDefinition(entry.value.configuration)?.id ??
                catalog_wire.ResourceDefinitionId.defaultInstance,
            content: entry.value,
          ),
      ],
      links: _links,
      observations: _original.values,
      absentInputToken: absentInputToken,
      catalog: catalog,
    );
    branch._observed.addAll(_observed);
    branch._intents.addAll(_intents);
    branch._initializationFindings.addAll(_initializationFindings);
    branch._materializationOperations.addAll(_materializationOperations);
    return branch;
  }

  AuthoredDraftRebase rebaseOnto(AuthoredDraft baseline) {
    for (final observation in _observed.values) {
      if (observation.identity is checking.InputIdentity_catalogWrapper) {
        continue;
      }
      final actual =
          baseline._original[observation.identity]?.token ??
          baseline.absentInputToken;
      if (actual != observation.token) {
        return AuthoredDraftRebaseConflict(
          identity: observation.identity,
          expected: observation.token,
          actual: actual,
        );
      }
    }
    final next = AuthoredDraft(
      snapshot: baseline.snapshot,
      generation: baseline.generation,
      resources: [
        for (final entry in baseline._resources.entries)
          authoring.AuthoringResource(
            id: entry.key,
            definition:
                baseline.catalog
                    ?.resourceDefinition(entry.value.configuration)
                    ?.id ??
                catalog_wire.ResourceDefinitionId.defaultInstance,
            content: entry.value,
          ),
      ],
      links: baseline._links,
      observations: baseline._original.values,
      absentInputToken: baseline.absentInputToken,
      catalog: baseline.catalog,
    );
    for (final intent in _intents) {
      final failure = next._replay(intent);
      if (failure != null) return AuthoredDraftRebaseFailed(failure);
    }
    for (final observation in _observed.values) {
      if (observation.identity is checking.InputIdentity_catalogWrapper) {
        continue;
      }
      next._observed[observation.identity] = observation;
    }
    return AuthoredDraftRebased(next);
  }

  AuthoredDraftRebase rebaseTailOnto(
    AuthoredDraft baseline, {
    required int acceptedIntentCount,
    required Iterable<checking.InputIdentity> acceptedChanges,
  }) {
    if (acceptedIntentCount < 0 || acceptedIntentCount > _intents.length) {
      return const AuthoredDraftRebaseFailed(
        "The accepted edit prefix no longer matches the local draft",
      );
    }
    final accepted = acceptedChanges.toSet();
    for (final observation in _observed.values) {
      if (observation.identity is checking.InputIdentity_catalogWrapper) {
        continue;
      }
      final actual =
          baseline._original[observation.identity]?.token ??
          baseline.absentInputToken;
      if (actual != observation.token &&
          !accepted.contains(observation.identity)) {
        return AuthoredDraftRebaseConflict(
          identity: observation.identity,
          expected: observation.token,
          actual: actual,
        );
      }
    }
    final next = baseline.fork();
    for (final intent in _intents.skip(acceptedIntentCount)) {
      final failure = next._replay(intent);
      if (failure != null) return AuthoredDraftRebaseFailed(failure);
    }
    for (final observation in _observed.values) {
      if (observation.identity is checking.InputIdentity_catalogWrapper) {
        continue;
      }
      next._observed[observation.identity] = checking.InputObservation(
        identity: observation.identity,
        token:
            baseline._original[observation.identity]?.token ??
            baseline.absentInputToken,
      );
    }
    next._initializationFindings.addAll(_initializationFindings);
    next._materializationOperations.addAll(_materializationOperations);
    return AuthoredDraftRebased(next);
  }

  authoring.PreparedEdit prepare(types.BatchId id) => authoring.PreparedEdit(
    id: id,
    catalog: generation,
    snapshot: snapshot,
    observations: observations,
    intents: intents,
  );

  types.AuthoringRecord? resource(types.ResourceId id) => _resources[id];

  PortablePathResult<types.DataValue> read(types.ValueLocation location) {
    _observeCatalog();
    _observePath(location);
    _observe(checking.InputIdentity.createValue(at: location));
    final record = _resources[location.resource];
    if (record == null) {
      return const PortablePathUnavailable("The resource is absent");
    }
    return record.readAt(location.path);
  }

  PortablePathResult<types.AuthoringRecord> set(
    types.ValueLocation location,
    types.DataValue value,
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
    final originalObserved =
        Map<checking.InputIdentity, checking.InputObservation>.from(_observed);
    PortablePathResult<types.AuthoringRecord> rollback(
      PortablePathResult<types.AuthoringRecord> result,
    ) {
      _resources[location.resource] = record;
      _intents.removeRange(originalIntents, _intents.length);
      _observed
        ..clear()
        ..addAll(originalObserved);
      return result;
    }

    final materialized = _materializeParents(location);
    if (materialized case PortablePathUnavailable<types.AuthoringRecord>()) {
      return rollback(materialized);
    }
    final writableRecord = _resources[location.resource]!;
    _observeCatalog();
    _observePath(location);
    _observe(checking.InputIdentity.createValue(at: location));
    final updated = writableRecord.replaceAt(location.path, value);
    if (updated case PortablePathValue(value: final stagedRecord)) {
      _resources[location.resource] = stagedRecord;
      _intents.add(
        authoring.EditIntent.createSetValue(at: location, value: value),
      );
      return updated;
    }
    return rollback(updated);
  }

  Future<PortablePathResult<types.AuthoringRecord>> setWithInitialization(
    types.ValueLocation location,
    types.DataValue value,
    Future<catalog_wire.PreparedCreation> Function(
      catalog_wire.InitializationRequest request,
    )
    prepare,
  ) async {
    final baseline = _DraftState.capture(this);
    final working = fork();
    var result = working.set(location, value);
    while (result is PortablePathUnavailable<types.AuthoringRecord> &&
        result.message == "The parent field needs prepared initialization") {
      final plan = working._parentInitialization(location);
      if (plan == null) return result;
      _materializationOperations[plan.location] =
          working._materializationOperations[plan.location]!;
      working
        .._observeCatalog()
        .._observePath(plan.containing)
        .._observe(checking.InputIdentity.createValue(at: plan.containing));
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
          parent == types.DataValue.unfilled ||
          parent == types.DataValue.null_) {
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
          types.TypeSelection_completeWrapper(:final value) => value,
          _ => null,
        };
        if (actual == null ||
            !(catalog?.isReadableAs(
                  types.TypeUse.wrapNamed(actual),
                  types.TypeUse.wrapNamed(plan.expected),
                ) ??
                false)) {
          return const PortablePathUnavailable(
            "The prepared parent field has an incompatible type",
          );
        }
        parent = types.DataValue.createNamed(
          actualType: actual,
          payload: types.DataValue.createRecord(fields: child.record.fields),
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
    catalog_wire.PreparedCreation prepared,
    catalog_wire.InitializationRequest request,
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

  PortablePathResult<types.AuthoringRecord> setPayload(
    types.ValueLocation location,
    types.DataValue payload,
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

  PortablePathResult<types.AuthoringRecord> clear(
    types.ValueLocation location, {
    types.TypeUse? expected,
  }) => set(
    location,
    expected is types.TypeUse_nullableWrapper
        ? types.DataValue.null_
        : types.DataValue.unfilled,
  );

  PortablePathResult<types.AuthoringRecord> insert(
    types.ValueLocation location,
    types.ItemId? after,
    types.ListItem item,
  ) {
    _observeCatalog();
    _observeCollection(location, order: true);
    return _updateCollection(
      location,
      (items) {
        if (items.any((candidate) => candidate.id == item.id)) return null;
        final index = after == null
            ? 0
            : items.indexWhere((candidate) => candidate.id == after) + 1;
        if (after != null && index == 0) return null;
        return [...items.take(index), item, ...items.skip(index)];
      },
      authoring.EditIntent.createInsert(at: location, after: after, item: item),
    );
  }

  PortablePathResult<types.AuthoringRecord> insertPrepared(
    types.ValueLocation location,
    types.ItemId? after,
    types.ItemId item,
    catalog_wire.InitializationRequest request,
    catalog_wire.PreparedCreation prepared,
  ) {
    if (!_preparedRecordIsUsable(prepared, request)) {
      return const PortablePathUnavailable(
        "The prepared collection item does not match the requested type",
      );
    }
    final actual = switch (prepared.record.configuration) {
      types.TypeSelection_completeWrapper(:final value) => value,
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
      types.ListItem(
        id: item,
        value: types.DataValue.createNamed(
          actualType: actual,
          payload: types.DataValue.createRecord(fields: prepared.record.fields),
        ),
      ),
    );
    if (result case PortablePathValue()) {
      branch._initializationFindings.addAll(
        _locatedInitializationFindings(
          types.ValuePath(
            segments: [
              ...location.path.segments,
              types.PathSegment.createItem(id: item),
            ],
          ),
          prepared.findings,
        ),
      );
      _adopt(branch);
    }
    return result;
  }

  types.DataValue defaultValue(types.TypeUse? type) =>
      _defaultForType(type, const {});

  PortablePathResult<types.AuthoringRecord> remove(
    types.ValueLocation location,
    types.ItemId item,
  ) {
    _observeCatalog();
    _observeCollection(location, order: true);
    return _updateCollection(location, (items) {
      if (items.every((candidate) => candidate.id != item)) return null;
      return items.where((candidate) => candidate.id != item).toList();
    }, authoring.EditIntent.createRemove(at: location, item: item));
  }

  PortablePathResult<types.AuthoringRecord> move(
    types.ValueLocation location,
    types.ItemId item,
    types.ItemId? after,
  ) {
    _observeCatalog();
    _observeCollection(location, order: true);
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
    }, authoring.EditIntent.createMove(at: location, item: item, after: after));
  }

  PortablePathResult<types.AuthoringRecord> replaceMap(
    types.ValueLocation location,
    Iterable<types.MapRow> rows,
  ) {
    final previous = Map<checking.InputIdentity, checking.InputObservation>.of(
      _observed,
    );
    _observeCollection(location, order: false);
    final result = setPayload(
      location,
      types.DataValue.createMapValue(rows: rows),
    );
    if (result case PortablePathUnavailable()) {
      _observed
        ..clear()
        ..addAll(previous);
    }
    return result;
  }

  PortablePathResult<types.AuthoringRecord> applyPreparedRecord(
    types.ValueLocation location,
    catalog_wire.InitializationRequest request,
    catalog_wire.PreparedCreation prepared,
  ) {
    if (!_preparedRecordIsUsable(prepared, request)) {
      return const PortablePathUnavailable(
        "The prepared form does not match the requested type",
      );
    }
    final actual = switch (prepared.record.configuration) {
      types.TypeSelection_completeWrapper(:final value) => value,
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
      types.DataValue.createNamed(
        actualType: actual,
        payload: types.DataValue.createRecord(fields: prepared.record.fields),
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

  void create(types.ResourceId id, types.AuthoringRecord record) {
    _observeCatalog();
    _observe(checking.InputIdentity.createExistence(resource: id));
    _observe(_resourceSelection);
    _resources[id] = record;
    _intents.add(
      authoring.EditIntent.createCreateResource(id: id, record: record),
    );
  }

  void createPrepared(
    types.ResourceId id,
    catalog_wire.PreparedCreation prepared,
  ) {
    create(id, prepared.record);
    _initializationFindings.addAll(
      _locatedInitializationFindings(
        types.ValuePath(segments: const []),
        prepared.findings,
      ),
    );
  }

  void delete(types.ResourceId id) {
    _observeCatalog();
    _observe(checking.InputIdentity.createExistence(resource: id));
    _observe(checking.InputIdentity.createForm(at: _root(id)));
    _observeIncoming(id, null);
    _observeDeletionRelations(id);
    _observe(_resourceSelection);
    _resources.remove(id);
    _links.removeWhere((link) => link.first == id || link.second == id);
    _intents.add(authoring.EditIntent.createDeleteResource(id: id));
  }

  void connect(
    authoring.LinkOccurrence source,
    types.ResourceId target, {
    authoring.CounterpartChoice? counterpart,
  }) {
    _observeCatalog();
    _observeRelationPath(source.id.location);
    _observe(checking.InputIdentity.createExistence(resource: target));
    _observe(checking.InputIdentity.createForm(at: _root(target)));
    _observeIncoming(source.source, null);
    _observeIncoming(target, null);
    _observeRelationsForEndpoint(source.id.endpoint, source.source, target);
    switch (counterpart) {
      case authoring.CounterpartChoice_existingWrapper(:final value):
        _observeRelationPath(value.id.location);
      case authoring.CounterpartChoice_newWrapper(:final value):
        _observePath(value.containing);
        _observe(checking.InputIdentity.createForm(at: value.containing));
        _observe(checking.InputIdentity.createValue(at: value.containing));
        _observe(checking.InputIdentity.createMembership(at: value.containing));
        _observe(checking.InputIdentity.createOrder(at: value.containing));
      case null:
      case authoring.CounterpartChoice_unknown():
    }
    _insertMissingCollectionLinkItem(source.id.location);
    _stageConnection(source, target, counterpart);
    final wireSource = source.target.resource.value.isEmpty
        ? authoring.LinkOccurrence(
            id: source.id,
            source: source.source,
            target: types.LinkTarget(resource: target, opposite: null),
          )
        : source;
    _intents.add(
      authoring.EditIntent.createConnectRelation(
        source: wireSource,
        target: target,
        counterpart: counterpart,
      ),
    );
  }

  void _insertMissingCollectionLinkItem(types.ValueLocation location) {
    final record = _resources[location.resource];
    if (record == null || record.readAt(location.path) is PortablePathValue) {
      return;
    }
    final segments = location.path.segments.toList(growable: false);
    if (segments.isEmpty || segments.last is! types.PathSegment_itemWrapper) {
      return;
    }
    final item = (segments.last as types.PathSegment_itemWrapper).value.id;
    final containingPath = types.ValuePath(
      segments: segments.take(segments.length - 1),
    );
    final containing = record.readAt(containingPath);
    final items = switch (containing) {
      PortablePathValue(value: final value) => value.authoredItems,
      PortablePathUnavailable() => null,
    };
    if (items == null) return;
    final result = insert(
      types.ValueLocation(resource: location.resource, path: containingPath),
      items.lastOrNull?.id,
      types.ListItem(id: item, value: types.DataValue.unfilled),
    );
    if (result case PortablePathUnavailable(:final message)) {
      throw StateError(message);
    }
  }

  void disconnect(authoring.LinkOccurrence occurrence) {
    _disconnect(
      occurrence.id,
      source: occurrence.source,
      target: occurrence.target.resource,
    );
  }

  void _disconnect(
    authoring.LinkOccurrenceId occurrence, {
    types.ResourceId? source,
    types.ResourceId? target,
  }) {
    _observeCatalog();
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
        final opposite = types.ValueLocation(
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
    _intents.add(authoring.EditIntent.wrapDisconnectRelation(occurrence));
  }

  void _stageConnection(
    authoring.LinkOccurrence source,
    types.ResourceId target,
    authoring.CounterpartChoice? counterpart,
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
      authoring.CounterpartChoice_existingWrapper(:final value) => value,
      _ => null,
    };
    final newOpposite = switch (counterpart) {
      authoring.CounterpartChoice_newWrapper(:final value) =>
        _stageNewCounterpart(
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
      final previousTarget = previous.first == source.source
          ? previous.second
          : previous.first;
      final previousOpposite = previous.first == source.source
          ? previous.secondLocation
          : previous.firstLocation;
      if ((previousTarget != target || previousOpposite != oppositePath) &&
          previousOpposite != null) {
        final previousLocation = types.ValueLocation(
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
      types.LinkTarget(resource: target, opposite: oppositePath),
    );
    if (oppositeOccurrence != null) {
      _stageLinkValue(
        oppositeOccurrence.id.location,
        oppositeOccurrence.id.endpoint,
        types.LinkTarget(
          resource: source.source,
          opposite: source.id.location.path,
        ),
      );
    }
    if (newOpposite != null) {
      _stageLinkValue(
        newOpposite,
        oppositeEndpoint,
        types.LinkTarget(
          resource: source.source,
          opposite: source.id.location.path,
        ),
      );
    }
    if (automaticOpposite != null) {
      _stageLinkValue(
        automaticOpposite,
        oppositeEndpoint,
        types.LinkTarget(
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
      authoring.LinkProjection(
        contract: relation.id,
        first: sourceIsFirst ? source.source : target,
        second: sourceIsFirst ? target : source.source,
        firstLocation: sourceIsFirst ? source.id.location.path : oppositePath,
        secondLocation: sourceIsFirst ? oppositePath : source.id.location.path,
      ),
    );
  }

  types.ValueLocation? _automaticScalarCounterpart(
    types.ResourceId resource,
    types.EndpointId endpoint,
  ) {
    final record = _resources[resource];
    final checked = catalog;
    if (record == null || checked == null) return null;
    final owners = checked.nominalDefinitions(record.configuration);
    final candidates = <types.ValueLocation>{};
    for (final binding in checked.endpointBindings(record.configuration)) {
      if (binding.template.endpoint != endpoint ||
          binding.template.containsCollection ||
          !owners.contains(binding.template.valueOwner)) {
        continue;
      }
      final path = _directFieldPath(binding.template.relativePath);
      if (path != null) {
        candidates.add(types.ValueLocation(resource: resource, path: path));
      }
    }
    return candidates.length == 1 ? candidates.single : null;
  }

  types.ValueLocation? _stageNewCounterpart({
    required authoring.LinkOccurrence source,
    required types.ResourceId target,
    required types.EndpointId oppositeEndpoint,
    required authoring.NewCounterpartChoice choice,
  }) {
    final targetRecord = _resources[target];
    if (targetRecord == null) return null;
    final actual = switch (choice.prepared.record.configuration) {
      types.TypeSelection_completeWrapper(:final value) => value,
      _ => null,
    };
    if (actual == null) return null;
    final materialized = types.DataValue.createNamed(
      actualType: actual,
      payload: types.DataValue.createRecord(
        fields: choice.prepared.record.fields,
      ),
    );
    var embedded = choice.containing;
    final current = targetRecord.readAt(choice.containing.path);
    if (current case PortablePathValue(value: final value)
        when value.authoredItems != null) {
      final item = _nextStagedItem(choice.containing);
      embedded = types.ValueLocation(
        resource: target,
        path: types.ValuePath(
          segments: [
            ...choice.containing.path.segments,
            types.PathSegment.createItem(id: item),
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
    final locations = <types.ValueLocation>[];
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
          locations.add(types.ValueLocation(resource: target, path: path));
        }
      }
    }
    return locations.length == 1 ? locations.single : null;
  }

  types.ItemId _nextStagedItem(types.ValueLocation containing) {
    final prefix = "panel:new:${_intents.length}:";
    var index = 0;
    while (true) {
      final candidate = types.ItemId(value: "$prefix$index");
      final location = types.ValuePath(
        segments: [
          ...containing.path.segments,
          types.PathSegment.createItem(id: candidate),
        ],
      );
      if (_resources[containing.resource]?.readAt(location)
          is PortablePathUnavailable<types.DataValue>) {
        return candidate;
      }
      index++;
    }
  }

  void _stageLinkValue(
    types.ValueLocation location,
    types.EndpointId endpoint,
    types.LinkTarget target,
  ) {
    final record = _resources[location.resource];
    if (record == null) return;
    final current = record.readAt(location.path);
    final payload = types.DataValue.createLink(
      endpoint: endpoint,
      target: target,
    );
    final replacement = switch (current) {
      PortablePathValue(value: final types.DataValue value)
          when value is types.DataValue_namedWrapper =>
        value.withAuthoredPayload(payload),
      _ => switch (_concreteNamed(
        catalog?.valueTypeAt(record.configuration, location.path),
      )) {
        final actual? => types.DataValue.createNamed(
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
    types.AuthoringRecord record,
    types.ValueLocation location,
    types.DataValue replacement,
  ) {
    final segments = location.path.segments.toList(growable: false);
    if (segments.isEmpty || segments.last is! types.PathSegment_itemWrapper) {
      return;
    }
    final item = (segments.last as types.PathSegment_itemWrapper).value.id;
    final parent = types.ValuePath(
      segments: segments.take(segments.length - 1),
    );
    final current = record.readAt(parent);
    if (current case PortablePathValue(value: final value)) {
      final containing = types.ValueLocation(
        resource: location.resource,
        path: parent,
      );
      final updated = _replaceCollectionItems(
        _collectionValue(containing, value),
        (items) {
          if (items.any((candidate) => candidate.id == item)) return null;
          return [...items, types.ListItem(id: item, value: replacement)];
        },
      );
      if (updated == null) return;
      final staged = record.replaceAt(parent, updated);
      if (staged case PortablePathValue(value: final next)) {
        _resources[location.resource] = next;
      }
    }
  }

  void _stageLinkClear(types.ValueLocation location) {
    final record = _resources[location.resource];
    if (record == null) return;
    final segments = location.path.segments.toList(growable: false);
    if (segments.isNotEmpty && segments.last is types.PathSegment_itemWrapper) {
      final item = (segments.last as types.PathSegment_itemWrapper).value.id;
      final parent = types.ValuePath(
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
    final replacement = expected is types.TypeUse_nullableWrapper
        ? types.DataValue.null_
        : types.DataValue.unfilled;
    final updated = record.replaceAt(location.path, replacement);
    if (updated case PortablePathValue(value: final staged)) {
      _resources[location.resource] = staged;
    }
  }

  bool _projectionContainsOccurrence(
    authoring.LinkProjection link,
    authoring.LinkOccurrenceId occurrence,
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

  void retag(types.ValueLocation location, types.NamedTypeUse type) {
    _observeCatalog();
    _observePath(location);
    _observe(checking.InputIdentity.createForm(at: location));
    _observeIncoming(location.resource, null);
    _intents.add(authoring.EditIntent.createRetag(at: location, type: type));
  }

  void configureResource(
    types.ResourceId resource,
    types.TypeSelection configuration,
  ) {
    final current = _resources[resource];
    if (current == null) return;
    _observeCatalog();
    _observe(checking.InputIdentity.createExistence(resource: resource));
    _observe(checking.InputIdentity.createForm(at: _root(resource)));
    _observeIncoming(resource, null);
    _resources[resource] = types.AuthoringRecord(
      configuration: configuration,
      fields: current.fields,
    );
    _intents.add(
      authoring.EditIntent.createConfigureResource(
        resource: resource,
        configuration: configuration,
      ),
    );
  }

  String? _replay(authoring.EditIntent intent) {
    PortablePathResult<types.AuthoringRecord>? result;
    switch (intent) {
      case authoring.EditIntent_createResourceWrapper(:final value):
        create(value.id, value.record);
      case authoring.EditIntent_deleteResourceWrapper(:final value):
        delete(value.id);
      case authoring.EditIntent_setValueWrapper(:final value):
        result = set(value.at, value.value);
      case authoring.EditIntent_insertWrapper(:final value):
        result = insert(value.at, value.after, value.item);
      case authoring.EditIntent_removeWrapper(:final value):
        result = remove(value.at, value.item);
      case authoring.EditIntent_moveWrapper(:final value):
        result = move(value.at, value.item, value.after);
      case authoring.EditIntent_connectRelationWrapper(:final value):
        connect(value.source, value.target, counterpart: value.counterpart);
      case authoring.EditIntent_disconnectRelationWrapper(:final value):
        _disconnect(value);
      case authoring.EditIntent_retagWrapper(:final value):
        retag(value.at, value.type);
      case authoring.EditIntent_configureResourceWrapper(:final value):
        configureResource(value.resource, value.configuration);
      case authoring.EditIntent_unknown():
        return "The draft contains an unknown edit";
    }
    return switch (result) {
      PortablePathUnavailable(:final message) => message,
      _ => null,
    };
  }

  void _observeCollection(types.ValueLocation location, {required bool order}) {
    _observePath(location);
    _observe(checking.InputIdentity.createForm(at: location));
    _observe(checking.InputIdentity.createMembership(at: location));
    if (order) _observe(checking.InputIdentity.createOrder(at: location));
  }

  void _observeCatalog() {
    _observe(checking.InputIdentity.wrapCatalog(generation));
  }

  void _observePath(types.ValueLocation location) {
    _observe(
      checking.InputIdentity.createExistence(resource: location.resource),
    );
    var current = _root(location.resource);
    _observe(checking.InputIdentity.createForm(at: current));
    for (final segment in location.path.segments) {
      if (segment is types.PathSegment_itemWrapper) {
        _observe(checking.InputIdentity.createMembership(at: current));
      }
      current = types.ValueLocation(
        resource: current.resource,
        path: types.ValuePath(segments: [...current.path.segments, segment]),
      );
      _observe(checking.InputIdentity.createForm(at: current));
    }
  }

  void _observeIncoming(types.ResourceId resource, types.RelationId? relation) {
    _observe(
      checking.InputIdentity.createIncoming(
        resource: resource,
        relation: relation,
      ),
    );
  }

  void _observeRelationsForEndpoint(
    types.EndpointId endpoint,
    types.ResourceId source,
    types.ResourceId target,
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

  void _observeDeletionRelations(types.ResourceId requested) {
    final deleting = <types.ResourceId>{requested};
    final pending = <types.ResourceId>[requested];
    final contracts = <types.RelationId, catalog_wire.RelationContract>{};
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
        if (endpoint.onDelete != catalog_wire.RelationDeletePolicy.cascade) {
          continue;
        }
        final related = link.first == current ? link.second : link.first;
        if (deleting.add(related)) pending.add(related);
      }
    }
    for (final resource in deleting) {
      _observe(checking.InputIdentity.createExistence(resource: resource));
      _observe(checking.InputIdentity.createForm(at: _root(resource)));
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

  void _observeRelationProjection(authoring.LinkProjection link) {
    _observeIncoming(link.first, link.contract);
    _observeIncoming(link.second, link.contract);
    if (link.firstLocation case final path?) {
      _observeRelationPath(
        types.ValueLocation(resource: link.first, path: path),
      );
    }
    if (link.secondLocation case final path?) {
      _observeRelationPath(
        types.ValueLocation(resource: link.second, path: path),
      );
    }
  }

  void _observeRelationPath(types.ValueLocation location) {
    _observePath(location);
    _observe(checking.InputIdentity.createValue(at: location));
    final segments = location.path.segments.toList();
    if (segments.lastOrNull is types.PathSegment_itemWrapper) {
      final parent = types.ValueLocation(
        resource: location.resource,
        path: types.ValuePath(segments: segments.take(segments.length - 1)),
      );
      _observe(checking.InputIdentity.createForm(at: parent));
      _observe(checking.InputIdentity.createMembership(at: parent));
      _observe(checking.InputIdentity.createOrder(at: parent));
    }
  }

  void _observe(checking.InputIdentity identity) {
    _observed.putIfAbsent(
      identity,
      () =>
          _original[identity] ??
          checking.InputObservation(
            identity: identity,
            token: absentInputToken,
          ),
    );
  }

  PortablePathResult<types.AuthoringRecord> _materializeParents(
    types.ValueLocation target,
  ) {
    final checked = catalog;
    if (checked == null || target.path.segments.length < 2) {
      return PortablePathValue(_resources[target.resource]!);
    }
    while (true) {
      final record = _resources[target.resource]!;
      var selection = record.configuration;
      var currentPath = <types.PathSegment>[];
      var changed = false;
      for (final segment in target.path.segments.take(
        target.path.segments.length - 1,
      )) {
        if (segment case types.PathSegment_fieldWrapper(:final value)) {
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
          final location = types.ValueLocation(
            resource: target.resource,
            path: types.ValuePath(segments: currentPath),
          );
          final child = record.readAt(location.path);
          final childValue = switch (child) {
            PortablePathValue(:final value) => value,
            PortablePathUnavailable() => types.DataValue.unfilled,
          };
          if (childValue == types.DataValue.unfilled ||
              childValue == types.DataValue.null_) {
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
            _observeCatalog();
            _observePath(location);
            _observe(checking.InputIdentity.createValue(at: location));
            final updated = record.replaceAt(location.path, parent);
            if (updated case PortablePathValue(value: final stagedRecord)) {
              _resources[target.resource] = stagedRecord;
              _intents.add(
                authoring.EditIntent.createSetValue(
                  at: location,
                  value: parent,
                ),
              );
              changed = true;
              break;
            }
            return updated;
          }
          selection = switch (childValue) {
            types.DataValue_namedWrapper(:final value) =>
              types.TypeSelection.wrapComplete(value.actualType),
            _ => types.TypeSelection.unknown,
          };
        } else {
          currentPath = [...currentPath, segment];
          final child = record.readAt(types.ValuePath(segments: currentPath));
          if (child case PortablePathUnavailable()) {
            return const PortablePathUnavailable(
              "The collection item is absent",
            );
          }
          final childValue =
              (child as PortablePathValue<types.DataValue>).value;
          selection = switch (childValue) {
            types.DataValue_namedWrapper(:final value) =>
              types.TypeSelection.wrapComplete(value.actualType),
            _ => types.TypeSelection.unknown,
          };
        }
      }
      if (!changed) return PortablePathValue(record);
    }
  }

  types.DataValue? _materializeParent(
    types.TypeSelection containing,
    types.FieldOwner owner,
    types.NamedTypeUse expected,
  ) {
    final checked = catalog!;
    final containingDefinition = checked.selected(containing)?.definition.id;
    final containingDescriptor = containingDefinition == null
        ? null
        : checked.initialization(containingDefinition);
    if (containingDescriptor?.mode ==
        catalog_wire.InitializationMode.creation) {
      return null;
    }
    final captured = containingDescriptor?.captured
        .where((candidate) => candidate.field == owner)
        .firstOrNull
        ?.value;
    if (captured case types.DataValue_namedWrapper(:final value)
        when checked.isReadableAs(
          types.TypeUse.wrapNamed(value.actualType),
          types.TypeUse.wrapNamed(expected),
        )) {
      return captured;
    }
    final descriptor = checked.initialization(expected.definition);
    if (descriptor?.mode == catalog_wire.InitializationMode.creation) {
      return null;
    }
    return _defaultForNamed(expected, <types.NamedTypeUse>{});
  }

  _ParentInitialization? _parentInitialization(types.ValueLocation target) {
    final checked = catalog;
    final root = _resources[target.resource];
    if (checked == null || root == null || target.path.segments.length < 2) {
      return null;
    }
    var selection = root.configuration;
    var fields = root.fields.toList(growable: false);
    var currentPath = <types.PathSegment>[];
    for (final segment in target.path.segments.take(
      target.path.segments.length - 1,
    )) {
      currentPath = [...currentPath, segment];
      final child = root.readAt(types.ValuePath(segments: currentPath));
      if (segment case types.PathSegment_fieldWrapper(:final value)) {
        final field = checked
            .fields(selection)
            .where((candidate) => candidate.template.key == value.name)
            .firstOrNull;
        final expected = _concreteNamed(field?.type);
        if (field == null || expected == null) return null;
        final childValue = switch (child) {
          PortablePathValue(:final value) => value,
          PortablePathUnavailable() => types.DataValue.unfilled,
        };
        if ((childValue == types.DataValue.unfilled ||
                childValue == types.DataValue.null_) &&
            _materializeParent(selection, field.template.owner, expected) ==
                null) {
          final location = types.ValueLocation(
            resource: target.resource,
            path: types.ValuePath(segments: currentPath),
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
          final containingLocation = types.ValueLocation(
            resource: target.resource,
            path: types.ValuePath(
              segments: currentPath.take(currentPath.length - 1),
            ),
          );
          return _ParentInitialization(
            location: location,
            containing: containingLocation,
            field: value.name,
            expected: expected,
            request: catalog_wire.InitializationRequest(
              id: types.InitializationRequestId(
                value: "panel:materialize:${operation.id}:containing",
              ),
              catalog: generation,
              type: selection,
              supplied: supplied,
              intentHash: containingIdentity,
            ),
            childRequest: catalog_wire.InitializationRequest(
              id: types.InitializationRequestId(
                value: "panel:materialize:${operation.id}:child",
              ),
              catalog: generation,
              type: types.TypeSelection.wrapComplete(expected),
              supplied: const [],
              intentHash: childIdentity,
            ),
          );
        }
        selection = switch (childValue) {
          types.DataValue_namedWrapper(:final value) =>
            types.TypeSelection.wrapComplete(value.actualType),
          _ => types.TypeSelection.unknown,
        };
        fields =
            childValue.authoredRecord?.fields.toList(growable: false) ??
            const [];
      } else {
        if (child is! PortablePathValue<types.DataValue>) return null;
        final childValue = child.value;
        selection = switch (childValue) {
          types.DataValue_namedWrapper(:final value) =>
            types.TypeSelection.wrapComplete(value.actualType),
          _ => types.TypeSelection.unknown,
        };
        fields =
            childValue.authoredRecord?.fields.toList(growable: false) ??
            const [];
      }
    }
    return null;
  }

  String _initializationFingerprint(
    types.ValueLocation location,
    types.TypeSelection selection,
    List<types.FieldValue> supplied,
  ) {
    final bytes = <int>[
      ...types.CatalogGeneration.serializer.toBytes(generation),
      ...types.ValueLocation.serializer.toBytes(location),
      ...types.TypeSelection.serializer.toBytes(selection),
      for (final field in [
        ...supplied,
      ]..sort((a, b) => a.name.compareTo(b.name)))
        ...types.FieldValue.serializer.toBytes(field),
    ];
    return sha256.convert(bytes).toString();
  }

  String _initializationIntentHash(
    _MaterializationOperation operation,
    String step,
  ) => sha256
      .convert(utf8.encode("${operation.id}:${operation.fingerprint}:$step"))
      .toString();

  types.DataValue _defaultForNamed(
    types.NamedTypeUse actual,
    Set<types.NamedTypeUse> visiting,
  ) {
    if (visiting.contains(actual)) return types.DataValue.unfilled;
    final checked = catalog!;
    final published = checked.published(actual.definition);
    if (published == null) return types.DataValue.unfilled;
    final selection = types.TypeSelection.wrapComplete(actual);
    final descriptor = checked.initialization(actual.definition);
    final payload = switch (published.definition.representation) {
      types.RepresentationTemplate_scalarWrapper(:final value) =>
        _scalarDefault(value.kind),
      types.RepresentationTemplate_sequenceWrapper(:final value) =>
        value.kind == types.CollectionKind.list
            ? types.DataValue.createListValue(items: const [])
            : types.DataValue.createSetValue(items: const []),
      types.RepresentationTemplate_mappingWrapper() =>
        types.DataValue.createMapValue(rows: const []),
      types.RepresentationTemplate_enumerationWrapper(:final value) =>
        value.cases.firstOrNull == null
            ? types.DataValue.unfilled
            : types.DataValue.wrapEnumCase(value.cases.first.key),
      types.RepresentationTemplate_linkWrapper() => types.DataValue.unfilled,
      types.RepresentationTemplate_recordWrapper(:final value) =>
        value.abstract_
            ? types.DataValue.unfilled
            : types.DataValue.createRecord(
                fields: [
                  for (final field in checked.fields(selection))
                    types.FieldValue(
                      name: field.template.key,
                      value: _fieldDefault(
                        field,
                        descriptor: descriptor,
                        visiting: {...visiting, actual},
                      ),
                    ),
                ],
              ),
      types.RepresentationTemplate_unknown() => types.DataValue.unfilled,
    };
    if (payload == types.DataValue.unfilled) return payload;
    return types.DataValue.createNamed(actualType: actual, payload: payload);
  }

  types.DataValue _fieldDefault(
    AppliedEditorField field, {
    required catalog_wire.InitializationDescriptor? descriptor,
    required Set<types.NamedTypeUse> visiting,
  }) {
    final checked = catalog!;
    final captured = descriptor?.captured
        .where((candidate) => candidate.field == field.template.owner)
        .firstOrNull
        ?.value;
    if (captured != null) return captured;
    if (checked.hasConstructorDefault(field.template.owner)) {
      return types.DataValue.unfilled;
    }
    return _defaultForType(field.type, visiting);
  }

  types.DataValue _defaultForType(
    types.TypeUse? type,
    Set<types.NamedTypeUse> visiting,
  ) => switch (type) {
    types.TypeUse_nullableWrapper() => types.DataValue.null_,
    types.TypeUse_scalarWrapper(:final value) => _scalarDefault(value),
    types.TypeUse_namedWrapper(:final value) => _defaultForNamed(
      value,
      visiting,
    ),
    _ => types.DataValue.unfilled,
  };

  types.DataValue _scalarDefault(types.ScalarKind kind) => switch (kind) {
    types.ScalarKind.unit => types.DataValue.unit,
    types.ScalarKind.boolean => types.DataValue.wrapBoolean(false),
    types.ScalarKind.text => types.DataValue.wrapStringValue(""),
    types.ScalarKind_integerWrapper() => types.DataValue.wrapInteger("0"),
    types.ScalarKind_floatWrapper() => types.DataValue.wrapFloat(0),
    types.ScalarKind.decimal => types.DataValue.wrapDecimal("0"),
    types.ScalarKind.bytes => types.DataValue.wrapBytes(ByteString.empty),
    types.ScalarKind.duration => types.DataValue.createDuration(
      value: kernel.Duration(milliseconds: 0),
    ),
    types.ScalarKind.timestamp => types.DataValue.unfilled,
    _ => types.DataValue.unfilled,
  };

  PortablePathResult<types.AuthoringRecord> _updateCollection(
    types.ValueLocation location,
    List<types.ListItem>? Function(List<types.ListItem> items) update,
    authoring.EditIntent intent,
  ) {
    final current = read(location);
    if (current case PortablePathUnavailable(:final message)) {
      return PortablePathUnavailable(message);
    }
    final currentValue = (current as PortablePathValue<types.DataValue>).value;
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

  types.DataValue _collectionValue(
    types.ValueLocation location,
    types.DataValue current,
  ) {
    if (current.authoredItems != null ||
        current.authoredPayload != types.DataValue.unfilled) {
      return current;
    }
    final record = _resources[location.resource];
    if (record == null) return current;
    final expected = catalog?.valueTypeAt(
      record.configuration,
      location.path,
      value: types.DataValue.createRecord(fields: record.fields),
    );
    final initialized = _defaultForType(expected, const {});
    return initialized.authoredItems == null ? current : initialized;
  }
}

Iterable<diagnostic_wire.InitializationDiagnostic>
_locatedInitializationFindings(
  types.ValuePath base,
  Iterable<diagnostic_wire.InitializationDiagnostic> findings,
) sync* {
  for (final finding in findings) {
    final relative = finding.relativePath;
    final segments = [
      ...base.segments,
      if (relative != null) ...relative.segments,
    ];
    yield diagnostic_wire.InitializationDiagnostic(
      field: finding.field,
      code: finding.code,
      message: finding.message,
      relativePath: segments.isEmpty
          ? null
          : types.ValuePath(segments: segments),
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
    required this.identity,
    required this.expected,
    required this.actual,
  });

  final checking.InputIdentity identity;
  final types.InputToken expected;
  final types.InputToken actual;
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

  final types.ValueLocation location;
  final types.ValueLocation containing;
  final String field;
  final types.NamedTypeUse expected;
  final catalog_wire.InitializationRequest request;
  final catalog_wire.InitializationRequest childRequest;
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

  final Map<types.ResourceId, types.AuthoringRecord> resources;
  final List<authoring.LinkProjection> links;
  final Map<checking.InputIdentity, checking.InputObservation> observed;
  final List<authoring.EditIntent> intents;
  final List<diagnostic_wire.InitializationDiagnostic> initializationFindings;

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

final _resourceSelection = checking.InputIdentity.createSelection(
  value: "realm.resources",
);

types.ValueLocation _root(types.ResourceId resource) => types.ValueLocation(
  resource: resource,
  path: types.ValuePath(segments: const []),
);

types.NamedTypeUse? _concreteNamed(types.TypeUse? type) => switch (type) {
  types.TypeUse_namedWrapper(:final value) => value,
  types.TypeUse_nullableWrapper(:final value) => _concreteNamed(value.value),
  _ => null,
};

types.ValuePath? _directFieldPath(types.RelativeFieldPattern pattern) {
  final segments = <types.PathSegment>[];
  for (final segment in pattern.segments) {
    if (segment case types.FieldPatternSegment_fieldWrapper(:final value)) {
      segments.add(types.PathSegment.createField(name: value.name));
    } else {
      return null;
    }
  }
  return types.ValuePath(segments: segments);
}

types.DataValue valueAt(types.AuthoringRecord record, types.ValuePath path) =>
    switch (record.readAt(path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => types.DataValue.unfilled,
    };

types.DataValue? _replaceCollectionItems(
  types.DataValue value,
  List<types.ListItem>? Function(List<types.ListItem> items) update,
) => switch (value) {
  types.DataValue_namedWrapper(:final value) => switch (_replaceCollectionItems(
    value.payload,
    update,
  )) {
    final payload? => types.DataValue.createNamed(
      actualType: value.actualType,
      payload: payload,
    ),
    null => null,
  },
  types.DataValue_listValueWrapper(:final value) => switch (update(
    value.items.toList(),
  )) {
    final items? => types.DataValue.createListValue(items: items),
    null => null,
  },
  types.DataValue_setValueWrapper(:final value) => switch (update(
    value.items.toList(),
  )) {
    final items? => types.DataValue.createSetValue(items: items),
    null => null,
  },
  _ => null,
};

bool _containsLink(types.DataValue value) => switch (value) {
  types.DataValue_linkWrapper() => true,
  types.DataValue_namedWrapper(:final value) => _containsLink(value.payload),
  types.DataValue_recordWrapper(:final value) => value.fields.any(
    (field) => _containsLink(field.value),
  ),
  types.DataValue_listValueWrapper(:final value) ||
  types.DataValue_setValueWrapper(
    :final value,
  ) => value.items.any((item) => _containsLink(item.value)),
  types.DataValue_mapValueWrapper(:final value) => value.rows.any(
    (entry) => _containsLink(entry.key) || _containsLink(entry.value),
  ),
  _ => false,
};
