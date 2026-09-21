part of "authoring_session.dart";

mixin _AuthoringSessionSnapshots on _$AuthoringSession {
  RealmServiceAddress get _address;

  Future<
    ({
      skir.AuthoringGraphSnapshot graph,
      Map<skir.ResourceId, skir.CompiledResourceState> compiledStatuses,
    })
  >
  _fetchSnapshot(List<_AuthoringScope> scopes) async {
    final generation = state.generation ?? _catalogGeneration();
    final request = skir.QueryAuthoringGraphRequest(
      generation: generation,
      selections: scopes.map((scope) => scope.selection),
    );
    final response = await ref.requestSkir(
      _address.request("library.authoring.graph.query"),
      skir.QueryAuthoringGraphRequest.serializer.toBytes(request),
      skir.QueryAuthoringGraphResponse.serializer,
    );
    final graph = switch (response) {
      skir.QueryAuthoringGraphResponse_successWrapper(:final value) => value,
      skir.QueryAuthoringGraphResponse_invalidWrapper(:final value) =>
        throw value.toApiException(),
      skir.QueryAuthoringGraphResponse_catalogChangedWrapper() =>
        throw StateError("The Realm catalog changed during graph acquisition"),
      skir.QueryAuthoringGraphResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.QueryAuthoringGraphResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
    };
    final statusRequest = skir.QueryCompiledResourceStatusRequest(
      generation: graph.generation,
      resources: graph.resources.map((resource) => resource.id),
    );
    final statusResponse = await ref.requestSkir(
      _address.request("library.authoring.compiled.status.query"),
      skir.QueryCompiledResourceStatusRequest.serializer.toBytes(statusRequest),
      skir.QueryCompiledResourceStatusResponse.serializer,
    );
    final compiledStatuses = switch (statusResponse) {
      skir.QueryCompiledResourceStatusResponse_successWrapper(:final value) =>
        Map<skir.ResourceId, skir.CompiledResourceState>.unmodifiable({
          for (final status in value.statuses) status.resource: status.state,
        }),
      skir.QueryCompiledResourceStatusResponse_invalidWrapper(:final value) =>
        throw value.toApiException(),
      skir.QueryCompiledResourceStatusResponse_catalogChangedWrapper() =>
        throw StateError("The Realm catalog changed during status acquisition"),
      skir.QueryCompiledResourceStatusResponse_internalErrorWrapper() =>
        throw ApiException.internalServerError(),
      skir.QueryCompiledResourceStatusResponse_unknown() =>
        throw ApiException.unknownResponseMessage(),
    };
    return (graph: graph, compiledStatuses: compiledStatuses);
  }

  skir.CatalogGeneration _catalogGeneration() {
    final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (snapshot == null) throw StateError("The editor catalog is unavailable");
    return skir.CatalogGeneration(value: snapshot.generation.value);
  }

  void _applySnapshot(
    skir.AuthoringGraphSnapshot snapshot,
    Map<skir.ResourceId, skir.CompiledResourceState> compiledStatuses,
  ) {
    state = AuthoringSessionState(
      generation: snapshot.generation,
      sequence: snapshot.sequence,
      resources: Map.unmodifiable({
        for (final resource in snapshot.resources) resource.id: resource,
      }),
      edges: Map.unmodifiable({
        for (final edge in snapshot.edges) edge.id: edge,
      }),
      presentations: Map.unmodifiable({
        for (final presentation in snapshot.presentations)
          presentation.resource: presentation.subject,
      }),
      compiledStatuses: compiledStatuses,
      selections: Map.unmodifiable({
        for (final selection in snapshot.selections) selection.key: selection,
      }),
      diagnostics: List.unmodifiable(snapshot.diagnostics),
      refreshing: state.refreshing,
    );
  }
}
