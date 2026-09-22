part of "authoring_session.dart";

extension RealmEditorCatalogCompilationRoots on RealmEditorCatalogSnapshot {
  Set<skir.CompilationRoot> compilationRoots(
    Iterable<skir.AuthoringResource> resources,
  ) {
    if (compilationProjections.isEmpty) return const {};
    final registry = TypeRegistry(catalog);
    final types = SkirTypeCodec(registry);
    final roots = <skir.CompilationRoot>{};
    for (final resource in resources) {
      final rootType = types.decodeReference(resource.content.rootType);
      final root = rootType.valueOrNull;
      if (root == null) continue;
      final actual = TypeExpression.named(root);
      for (final projection in compilationProjections) {
        if (!actual.isStructurallyAssignableTo(projection.root, registry)) {
          continue;
        }
        roots.add(
          skir.CompilationRoot(
            projection: skir.CompilationProjectionId(value: projection.id),
            resource: resource.id,
          ),
        );
      }
    }
    return roots;
  }
}

mixin _AuthoringSessionSnapshots on _$AuthoringSession {
  AuthoringResourceRepository get _repository;
  bool _isSelectionActive(String key);
  Set<String> get _activeSelectionKeys;

  Future<
    ({
      skir.AuthoringGraphSnapshot graph,
      Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses,
    })
  >
  _fetchSnapshot(List<skir.GraphSelection> selections) async {
    final generation = state.generation ?? _catalogGeneration();
    final graph = await _repository.fetchSelections(
      selections,
      generation: generation,
    );
    final graphGeneration = CatalogGeneration(graph.generation.value);
    final request = _catalogRequest(graph);
    final currentCatalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
    final catalog =
        currentCatalog != null &&
            currentCatalog.generation == graphGeneration &&
            _catalogCovers(currentCatalog, request)
        ? currentCatalog
        : await _fetchExactCatalog(graphGeneration, request);
    final activeSelections = graph.selections
        .where((selection) => _isSelectionActive(selection.key))
        .toList(growable: false);
    final activeResourceIds =
        activeSelections.isEmpty && _activeSelectionKeys.isNotEmpty
        ? graph.resources.map((resource) => resource.id).toSet()
        : activeSelections.expand((selection) => selection.resourceIds).toSet();
    final compiledStatuses = await _repository.fetchCompiledStates(
      catalog
          .compilationRoots(graph.resources)
          .where((root) => activeResourceIds.contains(root.resource)),
    );
    return (graph: graph, compiledStatuses: compiledStatuses);
  }

  RealmEditorCatalogRequest _catalogRequest(skir.AuthoringGraphSnapshot graph) {
    final result = authoringGraphCatalogRequest(
      graph.resources,
      graph.presentations.map((presentation) => presentation.subject),
    );
    final request = result.valueOrNull;
    if (request != null) return request;
    throw StateError(
      result.diagnostics.map((diagnostic) => diagnostic.message).join("; "),
    );
  }

  bool _catalogCovers(
    RealmEditorCatalogSnapshot catalog,
    RealmEditorCatalogRequest request,
  ) {
    final registry = TypeRegistry(catalog.catalog);
    return request.types.every(
      (type) => registry.resolveExact(type).valueOrNull != null,
    );
  }

  Future<RealmEditorCatalogSnapshot> _fetchExactCatalog(
    CatalogGeneration generation,
    RealmEditorCatalogRequest request,
  ) async {
    final cache = ref.read(realmEditorCatalogCacheProvider);
    if (cache == null) throw StateError("The editor catalog is unavailable");
    return switch (await cache.fetchExact(generation, request)) {
      RealmEditorCatalogFetched(:final snapshot) => snapshot,
      RealmEditorCatalogGenerationMismatch(:final currentGeneration) =>
        throw StateError(
          "Authoring graph generation ${generation.value} does not match catalog $currentGeneration",
        ),
      RealmEditorCatalogFetchUnavailable(:final diagnostics) =>
        throw StateError(
          diagnostics.map((diagnostic) => diagnostic.message).join("; "),
        ),
    };
  }

  skir.CatalogGeneration _catalogGeneration() {
    final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (snapshot == null) throw StateError("The editor catalog is unavailable");
    return skir.CatalogGeneration(value: snapshot.generation.value);
  }

  void _applySnapshot(
    skir.AuthoringGraphSnapshot snapshot,
    Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses,
  ) {
    final activeSelections = snapshot.selections
        .where((selection) => _isSelectionActive(selection.key))
        .toList(growable: false);
    final replacedKeys = activeSelections.map((value) => value.key).toSet();
    final retainedSelections = Map<String, skir.GraphSelectionResult>.of(
      state.selections,
    )..removeWhere((key, _) => replacedKeys.contains(key));
    final retainedResourceIds = retainedSelections.values
        .expand((value) => value.resourceIds)
        .toSet();
    final retainedEdgeIds = retainedSelections.values
        .expand((value) => value.edgeIds)
        .toSet();
    final snapshotResourceIds = activeSelections
        .expand((selection) => selection.resourceIds)
        .toSet();
    final snapshotEdgeIds = activeSelections
        .expand((selection) => selection.edgeIds)
        .toSet();
    if (activeSelections.isEmpty && _activeSelectionKeys.isNotEmpty) {
      snapshotResourceIds.addAll(
        snapshot.resources.map((resource) => resource.id),
      );
      snapshotEdgeIds.addAll(snapshot.edges.map((edge) => edge.id));
    }
    state = AuthoringSessionState(
      generation: snapshot.generation,
      sequence: snapshot.sequence,
      resources: Map.unmodifiable({
        for (final entry in state.resources.entries)
          if (retainedResourceIds.contains(entry.key)) entry.key: entry.value,
        for (final resource in snapshot.resources)
          if (snapshotResourceIds.contains(resource.id)) resource.id: resource,
      }),
      edges: Map.unmodifiable({
        for (final entry in state.edges.entries)
          if (retainedEdgeIds.contains(entry.key)) entry.key: entry.value,
        for (final edge in snapshot.edges)
          if (snapshotEdgeIds.contains(edge.id)) edge.id: edge,
      }),
      presentations: Map.unmodifiable({
        for (final entry in state.presentations.entries)
          if (retainedResourceIds.contains(entry.key)) entry.key: entry.value,
        for (final presentation in snapshot.presentations)
          if (snapshotResourceIds.contains(presentation.resource))
            presentation.resource: presentation.subject,
      }),
      compiledStatuses: Map.unmodifiable({
        for (final entry in state.compiledStatuses.entries)
          if (retainedResourceIds.contains(entry.key.resource))
            entry.key: entry.value,
        for (final entry in compiledStatuses.entries)
          if (snapshotResourceIds.contains(entry.key.resource))
            entry.key: entry.value,
      }),
      selections: Map.unmodifiable({
        ...retainedSelections,
        for (final selection in activeSelections) selection.key: selection,
      }),
      diagnostics: List.unmodifiable(snapshot.diagnostics),
      refreshing: state.refreshing,
    );
  }
}
