part of "authoring_session.dart";

final class AuthoringResourceRepository {
  AuthoringResourceRepository(this.session, this.organization, this.realm);

  final ResourceRepositories session;
  final skir.RecordId organization;
  final skir.RecordId realm;
  final _changes = StreamController<skir.AuthoringChanged>.broadcast(
    sync: true,
  );
  final _compiledChanges =
      StreamController<skir.CompiledContentChanged>.broadcast(sync: true);
  final _invalidations = StreamController<void>.broadcast(sync: true);

  Stream<skir.AuthoringChanged> get changes => _changes.stream;
  Stream<skir.CompiledContentChanged> get compiledChanges =>
      _compiledChanges.stream;
  Stream<void> get invalidations => _invalidations.stream;

  NatsSubscription? _authoringSubscription;
  NatsSubscription? _compiledSubscription;
  StreamSubscription<NatsMessage>? _authoringMessages;
  StreamSubscription<NatsMessage>? _compiledMessages;
  StreamSubscription<NatsConnectionState>? _lifecycle;
  var _started = false;
  var _reconnectNeedsRefresh = false;

  RealmServiceAddress get address =>
      RealmServiceAddress(organizationId: organization, realmId: realm);

  bool isScopedTo(skir.RecordId organizationId, skir.RecordId realmId) =>
      organization == organizationId && realm == realmId;

  /// Starts the repository owned watches exactly once.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final client = session.transport.client;
    _lifecycle = client.connectionStateChanges.listen(_onLifecycle);
    _onLifecycle(client.connectionState);
    _authoringSubscription = await client.subscribe(
      address.event("editor.authoring.changed"),
    );
    _compiledSubscription = await client.subscribe(
      address.event("editor.authoring.compiled.changed"),
    );
    _authoringMessages = _authoringSubscription!.messages.listen(
      _acceptAuthoringMessage,
      onError: (Object _, StackTrace _) => _invalidations.add(null),
    );
    _compiledMessages = _compiledSubscription!.messages.listen(
      _acceptCompiledMessage,
      onError: (Object _, StackTrace _) => _invalidations.add(null),
    );
  }

  void _acceptAuthoringMessage(NatsMessage message) {
    try {
      _changes.add(skir.AuthoringChanged.serializer.fromBytes(message.payload));
    } on Object {
      _invalidations.add(null);
    }
  }

  void _acceptCompiledMessage(NatsMessage message) {
    try {
      _compiledChanges.add(
        skir.CompiledContentChanged.serializer.fromBytes(message.payload),
      );
    } on Object {
      _invalidations.add(null);
    }
  }

  void _onLifecycle(NatsConnectionState lifecycle) {
    switch (lifecycle) {
      case NatsReconnecting() || NatsFailed():
        _reconnectNeedsRefresh = true;
      case NatsConnected() when _reconnectNeedsRefresh:
        _reconnectNeedsRefresh = false;
        _invalidations.add(null);
      case NatsConnecting() || NatsConnected() || NatsClosed():
    }
  }

  late final combiner =
      MutationCombiner<AuthoringContribution, skir.ApplyAuthoringBatchResponse>(
        prepare: prepare,
      );

  Future<skir.AuthoringGraphSnapshot> fetch(
    skir.GraphSelection selection, {
    CatalogGeneration? generation,
  }) => fetchSelections(
    [selection],
    generation: generation == null
        ? null
        : skir.CatalogGeneration(value: generation.value),
  );

  /// Fetches one bounded graph snapshot through this repository.
  Future<skir.AuthoringGraphSnapshot> fetchSelections(
    Iterable<skir.GraphSelection> selections, {
    skir.CatalogGeneration? generation,
  }) async {
    session.checkActive();
    final resolvedGeneration = generation ?? await _currentGeneration();
    final request = skir.QueryAuthoringGraphRequest(
      generation: resolvedGeneration,
      selections: selections,
    );
    final response = await session.transport.request(
      address.request("editor.authoring.graph.query"),
      skir.QueryAuthoringGraphRequest.serializer.toBytes(request),
      skir.QueryAuthoringGraphResponse.serializer,
    );
    session.checkActive();
    return switch (response) {
      skir.QueryAuthoringGraphResponse_successWrapper(:final value) => value,
      skir.QueryAuthoringGraphResponse_invalidWrapper(:final value) =>
        throw value.toApiException(),
      skir.QueryAuthoringGraphResponse_catalogChangedWrapper() =>
        throw StateError("The Realm catalog changed during graph acquisition"),
      _ => throw ApiException.internalServerError(),
    };
  }

  /// Fetches compiled states for the exact projection roots returned by a graph slice.
  Future<Map<skir.CompilationRoot, skir.CompiledResourceState>>
  fetchCompiledStates(Iterable<skir.CompilationRoot> roots) async {
    session.checkActive();
    final request = skir.QueryCompiledResourceStatusRequest(roots: roots);
    final response = await session.transport.request(
      address.request("editor.authoring.compiled.status.query"),
      skir.QueryCompiledResourceStatusRequest.serializer.toBytes(request),
      skir.QueryCompiledResourceStatusResponse.serializer,
    );
    session.checkActive();
    return switch (response) {
      skir.QueryCompiledResourceStatusResponse_successWrapper(:final value) =>
        Map.unmodifiable({
          for (final status in value.statuses) status.root: status.state,
        }),
      _ => throw ApiException.internalServerError(),
    };
  }

  Future<skir.SearchAuthoringGraphResponse> search(
    skir.SearchAuthoringGraphRequest request,
  ) async {
    session.checkActive();
    final response = await session.transport.request(
      address.request("editor.authoring.graph.search"),
      skir.SearchAuthoringGraphRequest.serializer.toBytes(request),
      skir.SearchAuthoringGraphResponse.serializer,
    );
    session.checkActive();
    return response;
  }

  Future<skir.CatalogGeneration> _currentGeneration() async {
    final result = await session.catalog.fetch(
      RealmEditorCatalogRoute(organizationId: organization, realmId: realm),
      const RealmEditorCatalogRequest(),
    );
    return switch (result) {
      RealmEditorCatalogFetched(:final snapshot) => skir.CatalogGeneration(
        value: snapshot.generation.value,
      ),
      RealmEditorCatalogGenerationMismatch(:final currentGeneration) =>
        skir.CatalogGeneration(value: currentGeneration.value),
      RealmEditorCatalogFetchUnavailable(:final diagnostics) =>
        throw StateError(diagnostics.map((item) => item.message).join("; ")),
    };
  }

  Future<RealmEditorCatalogSnapshot> fetchCatalog(
    skir.CatalogGeneration generation,
    RealmEditorCatalogRequest request,
  ) async {
    session.checkActive();
    final result = await session.catalog.fetch(
      RealmEditorCatalogRoute(organizationId: organization, realmId: realm),
      request,
      expectedGeneration: CatalogGeneration(generation.value),
    );
    session.checkActive();
    return switch (result) {
      RealmEditorCatalogFetched(:final snapshot) => snapshot,
      RealmEditorCatalogGenerationMismatch(:final currentGeneration) =>
        throw StateError(
          "Authoring catalog ${generation.value} is unavailable. Current generation is ${currentGeneration.value}",
        ),
      RealmEditorCatalogFetchUnavailable(:final diagnostics) =>
        throw StateError(diagnostics.map((item) => item.message).join("; ")),
    };
  }

  Future<skir.PreviewAuthoringBatchResponse> preview({
    required CatalogGeneration generation,
    required Iterable<skir.AuthoringOperation> operations,
  }) async {
    session.checkActive();
    final request = skir.PreviewAuthoringBatchRequest(
      generation: skir.CatalogGeneration(value: generation.value),
      operations: operations,
    );
    final response = await session.transport.request(
      address.request("editor.authoring.batch.preview"),
      skir.PreviewAuthoringBatchRequest.serializer.toBytes(request),
      skir.PreviewAuthoringBatchResponse.serializer,
    );
    session.checkActive();
    return response;
  }

  PreparedCommit<skir.ApplyAuthoringBatchResponse> prepare(
    List<AuthoringContribution> contributions, {
    String? batchId,
  }) {
    session.checkActive();
    final generations = contributions.map((item) => item.generation).toSet();
    if (generations.length != 1) {
      throw StateError("Authoring contributions use different catalogs");
    }
    final operations = contributions.expand((item) => item.operations).toList();
    final request = skir.ApplyAuthoringBatchRequest(
      batchId: batchId ?? uuid.v4(),
      generation: skir.CatalogGeneration(value: generations.single.value),
      operations: operations,
    );
    return session.transport.prepare(
      address.request("editor.authoring.batch.apply"),
      skir.ApplyAuthoringBatchRequest.serializer.toBytes(request),
      skir.ApplyAuthoringBatchResponse.serializer,
      submissionId: request.batchId,
      replay: SubmissionReplay.identicalRequest,
      label: _authoringLabel(operations),
      resources: {
        for (final operation in operations)
          for (final id in _operationResources(operation))
            (organization, realm, id),
      },
      classify: (response) => switch (response) {
        skir.ApplyAuthoringBatchResponse_appliedWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.ApplyAuthoringBatchResponse_internalErrorWrapper() ||
        skir.ApplyAuthoringBatchResponse_unknown() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
      onResponse: (response) async {
        session.checkActive();
        switch (response) {
          case skir.ApplyAuthoringBatchResponse_appliedWrapper(:final value):
            _changes.add(value);
          case skir.ApplyAuthoringBatchResponse_conflictWrapper():
            _invalidations.add(null);
          default:
            break;
        }
      },
    );
  }

  void dispose() {
    unawaited(_authoringMessages?.cancel());
    unawaited(_compiledMessages?.cancel());
    unawaited(_lifecycle?.cancel());
    unawaited(_authoringSubscription?.unsubscribe());
    unawaited(_compiledSubscription?.unsubscribe());
    unawaited(_changes.close());
    unawaited(_compiledChanges.close());
    unawaited(_invalidations.close());
  }
}
