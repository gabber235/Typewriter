import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_session.freezed.dart";
part "authoring_session.g.dart";
part "authoring_resource_repository.dart";
part "authoring_session_state.dart";

@riverpod
class AuthoringSession extends _$AuthoringSession {
  late AuthoringResourceRepository _repository;
  late skir.RecordId _organizationId;
  late skir.RecordId _realmId;
  var _lifecycleRevision = 0;
  Future<void>? _refreshing;
  var _refreshRequested = false;
  var _catalogRefreshRequested = false;
  skir.CatalogGeneration? _latestInvalidatedGeneration;
  @override
  AuthoringSessionState build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) {
    final lifecycleRevision = ++_lifecycleRevision;
    _refreshing = null;
    _refreshRequested = false;
    _catalogRefreshRequested = false;
    _latestInvalidatedGeneration = null;
    _organizationId = organizationId;
    _realmId = realmId;
    final repositories = ref.watch(resourceRepositoriesProvider);
    final repository = repositories.authoring(organizationId, realmId);
    _repository = repository;
    final changes = repository.changes.listen(
      (change) => _acceptChange(change, lifecycleRevision),
      onError: (Object _, StackTrace _) => _scheduleRefresh(lifecycleRevision),
    );
    final invalidations = repository.invalidations.listen(
      (_) => _scheduleRefresh(lifecycleRevision),
    );
    final catalogInvalidations = ref.listen(
      realmCatalogInvalidationsProvider(organizationId, realmId),
      (previous, next) {
        if (!_isActive(lifecycleRevision)) return;
        if (next.hasError) {
          _scheduleRefresh(lifecycleRevision, catalog: true);
          return;
        }
        if (next case AsyncData(:final value)) {
          _latestInvalidatedGeneration = value.generation;
          final current = state.catalog?.snapshot.generation;
          if (current != null && value.generation != current) {
            _scheduleRefresh(lifecycleRevision, catalog: true);
          }
        }
      },
    );
    ref
      ..onDispose(() {
        if (_lifecycleRevision == lifecycleRevision) {
          _lifecycleRevision++;
        }
      })
      ..onDispose(changes.cancel)
      ..onDispose(invalidations.cancel)
      ..onDispose(catalogInvalidations.close)
      ..onDispose(() => repositories.releaseAuthoring(repository));
    unawaited(
      _start(
        repositories,
        repository,
        lifecycleRevision,
        organizationId,
        realmId,
      ).catchError((Object error, StackTrace stackTrace) {
        if (!_isActive(lifecycleRevision)) return;
        state = state.copyWith(refreshing: false, failure: error);
      }),
    );
    return const AuthoringSessionState();
  }

  Future<void> _start(
    ResourceRepositories repositories,
    AuthoringResourceRepository repository,
    int lifecycleRevision,
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) async {
    await repositories.ensureAuthoringRealmsAdmitted(
      repositories.authoringRealms(organizationId),
    );
    if (!_isActive(lifecycleRevision)) return;
    await repository.start();
    if (!_isActive(lifecycleRevision)) return;
    await _refresh(repository, lifecycleRevision, organizationId, realmId);
  }

  Future<void> refresh({bool catalog = false}) => _refresh(
    _repository,
    _lifecycleRevision,
    _organizationId,
    _realmId,
    catalog: catalog,
  );

  Future<void> _refresh(
    AuthoringResourceRepository repository,
    int lifecycleRevision,
    skir.RecordId organizationId,
    skir.RecordId realmId, {
    bool catalog = false,
  }) {
    if (!_isActive(lifecycleRevision)) return Future.value();
    _refreshRequested = true;
    _catalogRefreshRequested = _catalogRefreshRequested || catalog;
    final active = _refreshing;
    if (active != null) return active;
    final operation =
        _drainRefreshes(
          repository,
          lifecycleRevision,
          organizationId,
          realmId,
        ).whenComplete(() {
          if (!_isActive(lifecycleRevision)) return;
          _refreshing = null;
          if (_refreshRequested) {
            unawaited(
              _refresh(repository, lifecycleRevision, organizationId, realmId),
            );
          }
        });
    _refreshing = operation;
    return operation;
  }

  Future<void> _drainRefreshes(
    AuthoringResourceRepository repository,
    int lifecycleRevision,
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) async {
    while (_isActive(lifecycleRevision) && _refreshRequested) {
      _refreshRequested = false;
      final catalog = _catalogRefreshRequested;
      _catalogRefreshRequested = false;
      await _runRefresh(
        repository,
        lifecycleRevision,
        organizationId,
        realmId,
        refreshCatalog: catalog,
      );
    }
  }

  Future<void> _runRefresh(
    AuthoringResourceRepository repository,
    int lifecycleRevision,
    skir.RecordId organizationId,
    skir.RecordId realmId, {
    required bool refreshCatalog,
  }) async {
    if (!_isActive(lifecycleRevision)) return;
    state = state.copyWith(refreshing: true, failure: null);
    try {
      var catalog = state.catalog?.snapshot;
      if (catalog == null || refreshCatalog) {
        catalog = await _fetchCatalog(organizationId, realmId);
      }
      if (!_isActive(lifecycleRevision)) return;
      final invalidatedGeneration = _latestInvalidatedGeneration;
      if (invalidatedGeneration != null &&
          catalog.generation != invalidatedGeneration) {
        catalog = await _fetchCatalog(organizationId, realmId);
      }
      if (!_isActive(lifecycleRevision)) return;
      skir.AuthoringState snapshot;
      try {
        snapshot = await repository.fetch(generation: catalog.generation);
      } on CatalogGenerationChanged {
        catalog = await _fetchCatalog(organizationId, realmId);
        if (!_isActive(lifecycleRevision)) return;
        snapshot = await repository.fetch(generation: catalog.generation);
      }
      if (!_isActive(lifecycleRevision)) return;
      state = AuthoringSessionState(
        snapshot: snapshot,
        catalog: CheckedEditorCatalog(catalog),
      );
    } on Object catch (error) {
      if (error is BoundedTransferCancelled && repository._isDisposed) return;
      if (!_isActive(lifecycleRevision)) return;
      state = state.copyWith(refreshing: false, failure: error);
      rethrow;
    }
  }

  Future<skir.EditorCatalogWireSnapshot> _fetchCatalog(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) async {
    final provider = realmCatalogTransferProvider(
      organizationId,
      realmId,
      uuid.v4(),
    );
    final retention = ref.listen(provider, (previous, next) {});
    try {
      return await ref.read(provider.future);
    } finally {
      retention.close();
    }
  }

  bool _isActive(int lifecycleRevision) =>
      ref.mounted && _lifecycleRevision == lifecycleRevision;

  void _scheduleRefresh(int lifecycleRevision, {bool catalog = false}) {
    if (!_isActive(lifecycleRevision)) return;
    unawaited(
      _refresh(
        _repository,
        lifecycleRevision,
        _organizationId,
        _realmId,
        catalog: catalog,
      ).catchError((Object _) {}),
    );
  }

  void _acceptChange(skir.AuthoringChanged change, int lifecycleRevision) {
    if (!_isActive(lifecycleRevision)) return;
    _scheduleRefresh(
      lifecycleRevision,
      catalog: change.generation != state.generation,
    );
  }

  PreparedCommit<skir.CommitPreparedEditResponse> prepareCommit(
    skir.PreparedEdit edit,
  ) => _repository.prepareCommit(edit);

  Future<skir.TypePreviewResult> previewTypeArguments({
    required skir.ResourceId resource,
    required skir.TypeSelection requested,
  }) {
    final snapshot = state.snapshot;
    if (snapshot == null) throw StateError("Authoring is not loaded");
    return _repository.previewTypeArgumentChange(
      skir.PreviewTypeArgumentChangeRequest(
        resource: resource,
        requested: requested,
        catalog: snapshot.generation,
      ),
    );
  }

  Future<skir.PreparedEditResult> prepareTypeArguments(
    skir.TypeArgumentChangePreview preview,
  ) => _repository.prepareTypeArgumentChange(preview);

  Future<skir.PreparedValue> prepareValue(
    skir.ValuePreparationRequest request,
  ) =>
      NatsRealmEditorCatalogSource(ref)
          .prepareValue(_organizationId, _realmId, request);

  Future<skir.SearchAuthoringResponse> search(
    skir.SearchAuthoringRequest request,
  ) => _repository.search(request);

  Future<skir.CommandResult> invokeCommand({
    required skir.CapabilityId capabilityId,
    required skir.DataValue payload,
  }) {
    final catalog = state.catalog;
    if (catalog == null) throw StateError("The editor catalog is not loaded");
    return NatsAuthoredCapabilityTransport(
      ref: ref,
      organizationId: _organizationId,
      realmId: _realmId,
    ).command(
      generation: catalog.snapshot.generation,
      capabilityId: capabilityId,
      payload: payload,
    );
  }

  Stream<skir.RealmPresentationSearchUpdate> watchPresentationSearch(
    skir.RealmPresentationSearchRequest request,
  ) => NatsRealmPresentationSearchTransport(
    ref: ref,
    organizationId: _organizationId,
    realmId: _realmId,
  ).watch(request);
}
