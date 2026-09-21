part of "authoring_session.dart";

final class AuthoringResourceRepository {
  AuthoringResourceRepository(this.session, this.organization, this.realm);

  final ResourceRepositories session;
  final skir.RecordId organization;
  final skir.RecordId realm;
  final _changes = StreamController<skir.AuthoringChanged>.broadcast(
    sync: true,
  );
  final _invalidations = StreamController<void>.broadcast(sync: true);

  Stream<skir.AuthoringChanged> get changes => _changes.stream;
  Stream<void> get invalidations => _invalidations.stream;

  RealmServiceAddress get address =>
      RealmServiceAddress(organizationId: organization, realmId: realm);

  bool isScopedTo(skir.RecordId organizationId, skir.RecordId realmId) =>
      organization == organizationId && realm == realmId;

  late final combiner =
      MutationCombiner<AuthoringContribution, skir.ApplyAuthoringBatchResponse>(
        prepare: prepare,
      );

  Future<skir.AuthoringGraphSnapshot> fetch(
    skir.GraphSelection selection, {
    CatalogGeneration? generation,
  }) async {
    session.checkActive();
    final resolvedGeneration = generation ?? await _currentGeneration();
    final request = skir.QueryAuthoringGraphRequest(
      generation: skir.CatalogGeneration(value: resolvedGeneration.value),
      selections: [selection],
    );
    final response = await session.transport.request(
      address.request("library.authoring.graph.query"),
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

  Future<CatalogGeneration> _currentGeneration() async {
    final result = await session.catalog.fetch(
      RealmEditorCatalogRoute(organizationId: organization, realmId: realm),
      const RealmEditorCatalogRequest(),
    );
    return switch (result) {
      RealmEditorCatalogFetched(:final snapshot) => snapshot.generation,
      RealmEditorCatalogGenerationMismatch(:final currentGeneration) =>
        currentGeneration,
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
      address.request("library.authoring.batch.preview"),
      skir.PreviewAuthoringBatchRequest.serializer.toBytes(request),
      skir.PreviewAuthoringBatchResponse.serializer,
    );
    session.checkActive();
    return response;
  }

  PreparedCommit<skir.ApplyAuthoringBatchResponse> prepare(
    List<AuthoringContribution> contributions,
  ) {
    session.checkActive();
    final generations = contributions.map((item) => item.generation).toSet();
    if (generations.length != 1) {
      throw StateError("Authoring contributions use different catalogs");
    }
    final operations = contributions.expand((item) => item.operations).toList();
    final request = skir.ApplyAuthoringBatchRequest(
      batchId: uuid.v4(),
      generation: skir.CatalogGeneration(value: generations.single.value),
      operations: operations,
    );
    return session.transport.prepare(
      address.request("library.authoring.batch.apply"),
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
    unawaited(_changes.close());
    unawaited(_invalidations.close());
  }
}
