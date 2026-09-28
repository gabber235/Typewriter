part of "authoring_session.dart";

mixin _AuthoringSessionSync on _$AuthoringSession, _AuthoringSessionSnapshots {
  @override
  late AuthoringResourceRepository _repository;
  final Map<String, AuthoringSelectionLeaseState> _leases = {};
  final Map<String, Future<void>> _selectionReadiness = {};
  final List<skir.AuthoringChanged> _buffer = [];

  Future<void>? _refreshOperation;
  late Future<void> _startOperation;
  final Set<String> _refreshSelections = {};
  final Set<String> _seenBatchIds = {};

  @override
  bool _isSelectionActive(String key) => _leases.containsKey(key);

  @override
  Set<String> get _activeSelectionKeys => _leases.keys.toSet();
  _AuthoringSelectionLease _acquire(skir.GraphSelection selection) {
    final key = selection.key;
    final existing = _leases[key];
    if (existing != null && existing.selection != selection) {
      throw StateError(
        "Authoring selection key '$key' is already leased for a different selection",
      );
    }
    final added = existing == null;
    _leases[key] = AuthoringSelectionLeaseState(
      selection: selection,
      retainCount: (existing?.retainCount ?? 0) + 1,
      result: state.selections[key],
    );
    final ready = added
        ? _selectionReadiness[key] = _startOperation.then((_) {
            _refreshSelections.add(key);
            return _refresh();
          })
        : _selectionReadiness[key] ?? _startOperation;
    final retention = ref.keepAlive();
    return _AuthoringSelectionLease(ready, () {
      _release(key);
      retention.close();
    });
  }

  void _release(String key) {
    final lease = _leases[key];
    if (lease == null) return;
    if (lease.retainCount == 1) {
      _leases.remove(key);
      _selectionReadiness.remove(key);
      _refreshSelections.remove(key);
      _pruneReleasedSelection(key);
    } else {
      _leases[key] = lease.copyWith(retainCount: lease.retainCount - 1);
    }
  }

  void _pruneReleasedSelection(String key) {
    final selections = Map<String, skir.GraphSelectionResult>.of(
      state.selections,
    )..remove(key);
    final resourceIds = selections.values
        .expand((selection) => selection.resourceIds)
        .toSet();
    final edgeIds = selections.values
        .expand((selection) => selection.edgeIds)
        .toSet();
    state = state.copyWith(
      resources: Map.unmodifiable({
        for (final entry in state.resources.entries)
          if (resourceIds.contains(entry.key)) entry.key: entry.value,
      }),
      edges: Map.unmodifiable({
        for (final entry in state.edges.entries)
          if (edgeIds.contains(entry.key)) entry.key: entry.value,
      }),
      presentations: Map.unmodifiable({
        for (final entry in state.presentations.entries)
          if (resourceIds.contains(entry.key)) entry.key: entry.value,
      }),
      compiledStatuses: Map.unmodifiable({
        for (final entry in state.compiledStatuses.entries)
          if (resourceIds.contains(entry.key.resource)) entry.key: entry.value,
      }),
      selections: Map.unmodifiable(selections),
    );
  }

  void _accept(skir.AuthoringChanged change) {
    if (!_seenBatchIds.add(change.batchId)) return;
    if (_seenBatchIds.length > 512) {
      _seenBatchIds.remove(_seenBatchIds.first);
    }
    if (_refreshOperation != null || state.sequence == null) {
      _buffer.add(change);
      return;
    }
    final current = state.sequence!;
    if (change.sequence <= current) return;
    if (change.sequence != current + 1) {
      _buffer.add(change);
      _scheduleRefresh();
      return;
    }
    _applyEvent(change);
  }

  void _acceptCompiled(skir.CompiledContentChanged change) {
    final currentGeneration = state.generation;
    if (currentGeneration != null && currentGeneration != change.generation) {
      _scheduleRefresh();
      return;
    }
    final currentSequence = state.sequence;
    if (currentSequence == null || change.sourceSequence > currentSequence) {
      _scheduleRefresh();
      return;
    }
    if (change.sourceSequence < currentSequence) {
      final affected = change.states
          .map(
            (state) => switch (state) {
              skir.CompiledResourceStateChange_upsertWrapper(:final value) =>
                value.root.resource,
              skir.CompiledResourceStateChange_removeWrapper(:final value) =>
                value.resource,
              skir.CompiledResourceStateChange_unknown() => null,
            },
          )
          .nonNulls
          .toSet();
      final selections = state.selections.entries
          .where((entry) => entry.value.resourceIds.any(affected.contains))
          .map((entry) => entry.key)
          .toSet();
      if (selections.isNotEmpty) _scheduleRefresh(selections);
      return;
    }
    final statuses = Map<skir.CompilationRoot, skir.CompiledResourceState>.of(
      state.compiledStatuses,
    );
    final activeResources = _activeResourceIds;
    for (final stateChange in change.states) {
      switch (stateChange) {
        case skir.CompiledResourceStateChange_upsertWrapper(:final value):
          if (activeResources.contains(value.root.resource)) {
            statuses[value.root] = value.state;
          }
        case skir.CompiledResourceStateChange_removeWrapper(:final value):
          if (activeResources.contains(value.resource)) statuses.remove(value);
        case skir.CompiledResourceStateChange_unknown():
          _scheduleRefresh();
          return;
      }
    }
    state = state.copyWith(compiledStatuses: Map.unmodifiable(statuses));
  }

  void _applyEvent(skir.AuthoringChanged event) {
    if (state.generation != null && event.generation != state.generation) {
      _scheduleRefresh();
      return;
    }
    final resources = Map<skir.ResourceId, skir.AuthoringResource>.of(
      state.resources,
    );
    final edges = Map<skir.AuthoringEdgeId, skir.AuthoringEdge>.of(state.edges);
    final presentations = Map<skir.ResourceId, skir.PresentationSubject>.of(
      state.presentations,
    );
    final compiledStatuses =
        Map<skir.CompilationRoot, skir.CompiledResourceState>.of(
          state.compiledStatuses,
        );
    for (final change in event.resources) {
      switch (change) {
        case skir.AuthoringResourceChange_upsertWrapper(:final value):
          resources[value.id] = value;
        case skir.AuthoringResourceChange_removeWrapper(:final value):
          resources.remove(value);
          presentations.remove(value);
          compiledStatuses.removeWhere((root, _) => root.resource == value);
        case skir.AuthoringResourceChange_unknown():
          _scheduleRefresh();
          return;
      }
    }
    for (final change in event.edges) {
      switch (change) {
        case skir.AuthoringEdgeChange_upsertWrapper(:final value):
          edges[value.id] = value;
        case skir.AuthoringEdgeChange_removeWrapper(:final value):
          edges.remove(value);
        case skir.AuthoringEdgeChange_unknown():
          _scheduleRefresh();
          return;
      }
    }
    for (final change in event.presentations) {
      switch (change) {
        case skir.PresentationSubjectChange_upsertWrapper(:final value):
          presentations[value.resource] = value.subject;
        case skir.PresentationSubjectChange_removeWrapper(:final value):
          presentations.remove(value);
        case skir.PresentationSubjectChange_unknown():
          _scheduleRefresh();
          return;
      }
    }
    final selections = _applySelectionChanges(state.selections, event);
    final activeResources = selections.values
        .expand((selection) => selection.resourceIds)
        .toSet();
    if (activeResources.isEmpty && _activeSelectionKeys.isNotEmpty) {
      activeResources.addAll(resources.keys);
    }
    for (final root in event.compilationImpact) {
      if (activeResources.contains(root.resource)) {
        compiledStatuses[root] = skir.CompiledResourceState.notCompiled;
      }
    }
    state = state.copyWith(
      generation: event.generation,
      sequence: event.sequence,
      resources: Map.unmodifiable(resources),
      edges: Map.unmodifiable(edges),
      presentations: Map.unmodifiable(presentations),
      compiledStatuses: Map.unmodifiable(compiledStatuses),
      selections: Map.unmodifiable(selections),
    );
    final incomplete = _leases.keys.where((key) => !_canApplyEvent(key, event));
    for (final key in incomplete) {
      _refreshSelections.add(key);
    }
    if (incomplete.isNotEmpty) _scheduleRefresh();
  }

  bool _canApplyEvent(String key, skir.AuthoringChanged event) {
    final selection = state.selections[key];
    if (selection == null || selection.missingIds.isNotEmpty) return false;
    final requested = _leases[key]?.selection;
    if (requested == null) return false;
    final resources = selection.resourceIds.toSet();
    final edges = selection.edgeIds.toSet();
    final hasTraversal = requested.steps.isNotEmpty;
    final scans = requested.seed is skir.ResourceSeed_scanWrapper;
    return event.resources.every(
          (change) => switch (change) {
            skir.AuthoringResourceChange_upsertWrapper(:final value) =>
              resources.contains(value.id) || !scans,
            skir.AuthoringResourceChange_removeWrapper(:final value) =>
              !resources.contains(value) || !hasTraversal,
            skir.AuthoringResourceChange_unknown() => false,
          },
        ) &&
        event.edges.every(
          (change) => switch (change) {
            skir.AuthoringEdgeChange_upsertWrapper(:final value) =>
              !hasTraversal ||
                  (!resources.contains(value.source) &&
                      !resources.contains(value.target)),
            skir.AuthoringEdgeChange_removeWrapper(:final value) =>
              !hasTraversal || !edges.contains(value),
            skir.AuthoringEdgeChange_unknown() => false,
          },
        ) &&
        event.presentations.every(
          (change) => switch (change) {
            skir.PresentationSubjectChange_upsertWrapper(:final value) =>
              resources.contains(value.resource) || !scans,
            skir.PresentationSubjectChange_removeWrapper(:final value) =>
              !resources.contains(value) || !hasTraversal,
            skir.PresentationSubjectChange_unknown() => false,
          },
        );
  }

  Map<String, skir.GraphSelectionResult> _applySelectionChanges(
    Map<String, skir.GraphSelectionResult> current,
    skir.AuthoringChanged event,
  ) {
    final selections = Map<String, skir.GraphSelectionResult>.of(current);
    for (final entry in current.entries) {
      final resources = <skir.ResourceId>{...entry.value.resourceIds};
      final edges = <skir.AuthoringEdgeId>{...entry.value.edgeIds};
      final missingIds = <skir.ResourceId>{...entry.value.missingIds};
      for (final change in event.resources) {
        if (change case skir.AuthoringResourceChange_removeWrapper(
          :final value,
        )) {
          resources.remove(value);
          if (_exactSeedIds(entry.key).contains(value)) missingIds.add(value);
        }
      }
      for (final change in event.edges) {
        if (change case skir.AuthoringEdgeChange_removeWrapper(:final value)) {
          edges.remove(value);
        }
      }
      selections[entry.key] = skir.GraphSelectionResult(
        key: entry.value.key,
        resourceIds: resources,
        edgeIds: edges,
        missingIds: missingIds,
        incompatibleIds: entry.value.incompatibleIds,
      );
    }
    return selections;
  }

  void _scheduleRefresh([Set<String>? selectionKeys]) {
    if (selectionKeys == null) {
      _refreshSelections.addAll(_leases.keys);
    } else {
      _refreshSelections.addAll(selectionKeys);
    }
    unawaited(_refresh().catchError((Object _) {}));
  }

  Future<void> _refresh() {
    final active = _refreshOperation;
    if (active != null) return active;
    return _refreshOperation = _runRefresh()
        .onError((error, stackTrace) {
          state = state.copyWith(
            diagnostics: [
              skir.AuthoringDiagnostic(
                code: "authoring-refresh-failed",
                message: "Could not refresh authoring state: $error",
                resource: null,
                path: null,
              ),
            ],
          );
          Error.throwWithStackTrace(
            error ?? StateError("Authoring refresh failed without an error"),
            stackTrace,
          );
        })
        .whenComplete(() {
          _refreshOperation = null;
        });
  }

  Future<void> _runRefresh() async {
    if (_leases.isEmpty) return;
    state = state.copyWith(refreshing: true);
    try {
      while (_refreshSelections.isNotEmpty && _leases.isNotEmpty) {
        final keys = _refreshSelections
            .where(_leases.containsKey)
            .toList(growable: false);
        _refreshSelections.removeAll(keys);
        if (keys.isEmpty) continue;
        final selections = keys
            .map((key) => _leases[key]?.selection)
            .whereType<skir.GraphSelection>()
            .toList(growable: false);
        final snapshot = await _fetchSnapshot(selections);
        if (snapshot.graph.sequence >= (state.sequence ?? 0)) {
          _applySnapshot(snapshot.graph, snapshot.compiledStatuses);
          _synchronizeLeaseResults();
          _drainBuffer();
        }
      }
    } finally {
      state = state.copyWith(refreshing: false);
    }
  }

  void _drainBuffer() {
    if (state.sequence == null) return;
    _buffer.sort((left, right) => left.sequence.compareTo(right.sequence));
    final buffered = List<skir.AuthoringChanged>.of(_buffer);
    _buffer.clear();
    for (var index = 0; index < buffered.length; index++) {
      final change = buffered[index];
      if (change.sequence <= state.sequence!) continue;
      if (change.sequence != state.sequence! + 1) {
        _buffer.addAll(buffered.skip(index));
        _scheduleRefresh();
        return;
      }
      _applyEvent(change);
    }
  }

  void _synchronizeLeaseResults() {
    for (final key in _leases.keys.toList(growable: false)) {
      final lease = _leases[key]!;
      _leases[key] = lease.copyWith(result: state.selections[key]);
    }
  }

  Set<skir.ResourceId> get _activeResourceIds {
    final ids = {
      for (final key in _leases.keys) ...?state.selections[key]?.resourceIds,
    };
    if (ids.isEmpty && _leases.isNotEmpty) ids.addAll(state.resources.keys);
    return ids;
  }

  Set<skir.ResourceId> _exactSeedIds(String key) {
    final seed = _leases[key]?.selection.seed;
    return switch (seed) {
      skir.ResourceSeed_idsWrapper(:final value) => value.values.toSet(),
      _ => const {},
    };
  }

  Future<void> _dispose() async {
    _refreshSelections.clear();
  }
}
