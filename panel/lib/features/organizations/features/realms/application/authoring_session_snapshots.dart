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
    final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (catalog == null) throw StateError("The editor catalog is unavailable");
    final compiledStatuses = await _repository.fetchCompiledStates(
      catalog.compilationRoots(graph.resources),
    );
    return (graph: graph, compiledStatuses: compiledStatuses);
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
    final replacedKeys = snapshot.selections.map((value) => value.key).toSet();
    final retainedSelections = Map<String, skir.GraphSelectionResult>.of(
      state.selections,
    )..removeWhere((key, _) => replacedKeys.contains(key));
    final retainedResourceIds = retainedSelections.values
        .expand((value) => value.resourceIds)
        .toSet();
    final retainedEdgeIds = retainedSelections.values
        .expand((value) => value.edgeIds)
        .toSet();
    state = AuthoringSessionState(
      generation: snapshot.generation,
      sequence: snapshot.sequence,
      resources: Map.unmodifiable({
        for (final entry in state.resources.entries)
          if (retainedResourceIds.contains(entry.key)) entry.key: entry.value,
        for (final resource in snapshot.resources) resource.id: resource,
      }),
      edges: Map.unmodifiable({
        for (final entry in state.edges.entries)
          if (retainedEdgeIds.contains(entry.key)) entry.key: entry.value,
        for (final edge in snapshot.edges) edge.id: edge,
      }),
      presentations: Map.unmodifiable({
        for (final entry in state.presentations.entries)
          if (retainedResourceIds.contains(entry.key)) entry.key: entry.value,
        for (final presentation in snapshot.presentations)
          presentation.resource: presentation.subject,
      }),
      compiledStatuses: Map.unmodifiable({
        for (final entry in state.compiledStatuses.entries)
          if (retainedResourceIds.contains(entry.key.resource))
            entry.key: entry.value,
        ...compiledStatuses,
      }),
      selections: Map.unmodifiable({
        ...retainedSelections,
        for (final selection in snapshot.selections) selection.key: selection,
      }),
      diagnostics: List.unmodifiable(snapshot.diagnostics),
      refreshing: state.refreshing,
    );
  }
}
