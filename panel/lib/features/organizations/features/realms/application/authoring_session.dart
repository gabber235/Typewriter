import "dart:async";

import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_session.freezed.dart";
part "authoring_session.g.dart";
part "authored_draft_autosave.dart";
part "authoring_resource_repository.dart";
part "authoring_session_state.dart";

@riverpod
class AuthoringSession extends _$AuthoringSession {
  AuthoringResourceRepository get repository => _repository;

  late AuthoringResourceRepository _repository;
  late skir.RecordId _organizationId;
  late skir.RecordId _realmId;
  var _lifecycleRevision = 0;
  Future<void>? _refreshing;
  var _refreshRequested = false;
  var _catalogRefreshRequested = false;
  skir.CatalogGeneration? _latestInvalidatedGeneration;
  Completer<skir.AuthoringState> _ready = Completer();
  final Set<AuthoredDraftAutosave> _autosaves = {};

  Future<skir.AuthoringState> get ready {
    final snapshot = state.snapshot;
    return snapshot == null ? _ready.future : Future.value(snapshot);
  }

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
    if (_ready.isCompleted) _ready = Completer();
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
    final catalogSource = NatsRealmEditorCatalogSource(ref);
    final catalogRoute = RealmEditorCatalogRoute(
      organizationId: organizationId,
      realmId: realmId,
    );
    final catalogInvalidations = catalogSource
        .watchInvalidations(catalogRoute)
        .listen(
          (event) {
            if (!_isActive(lifecycleRevision)) return;
            _latestInvalidatedGeneration = event.generation;
            final current = state.catalog?.snapshot.generation;
            if (current != null && event.generation != current) {
              _scheduleRefresh(lifecycleRevision, catalog: true);
            }
          },
          onError: (Object _, StackTrace _) =>
              _scheduleRefresh(lifecycleRevision, catalog: true),
        );
    ref
      ..onDispose(() {
        if (_lifecycleRevision == lifecycleRevision) {
          _lifecycleRevision++;
        }
        for (final autosave in _autosaves.toList()) {
          autosave.close();
        }
        _autosaves.clear();
      })
      ..onDispose(changes.cancel)
      ..onDispose(invalidations.cancel)
      ..onDispose(catalogInvalidations.cancel)
      ..onDispose(() => repositories.releaseAuthoring(repository));
    unawaited(
      _start(
        repository,
        lifecycleRevision,
        organizationId,
        realmId,
      ).catchError((Object _) {}),
    );
    return const AuthoringSessionState();
  }

  Future<void> _start(
    AuthoringResourceRepository repository,
    int lifecycleRevision,
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) async {
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
      _rememberSnapshot(snapshot);
      if (!_ready.isCompleted) _ready.complete(snapshot);
    } on Object catch (error) {
      if (error is BoundedTransferCancelled && repository._isDisposed) return;
      if (!_isActive(lifecycleRevision)) return;
      state = state.copyWith(refreshing: false, failure: error);
      if (!_ready.isCompleted) {
        _ready.completeError(error);
        _ready = Completer();
      }
      rethrow;
    }
  }

  Future<skir.EditorCatalogWireSnapshot> _fetchCatalog(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => NatsRealmEditorCatalogSource(ref).fetch(
    RealmEditorCatalogRoute(organizationId: organizationId, realmId: realmId),
  );

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

  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) async {
    return ref.read(localWorkControllerProvider).execute(prepareCommit(edit));
  }

  Future<skir.AuthoringResource> awaitResource(skir.ResourceId resource) {
    final completer = Completer<skir.AuthoringResource>();

    void accept(AuthoringSessionState next) {
      if (completer.isCompleted) return;
      if (next.resources[resource] case final adopted?) {
        completer.complete(adopted);
      } else if (next.failure case final failure?) {
        completer.completeError(failure, StackTrace.current);
      }
    }

    final stop = listenSelf((_, next) => accept(next));
    ref.onDispose(() {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError(
            "The authoring session closed before creation was adopted",
          ),
          StackTrace.current,
        );
      }
    });
    accept(state);
    return completer.future.whenComplete(stop);
  }

  AuthoredDraftAutosave openAutosave({
    required skir.ResourceId resource,
    required AuthoredDraft baseline,
    EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
  }) {
    for (final autosave in _autosaves) {
      if (autosave.resource == resource &&
          autosave.policy == policy &&
          autosave.detached) {
        autosave
          ..attach()
          ..acceptBaseline(baseline);
        return autosave;
      }
    }
    late final AuthoredDraftAutosave autosave;
    final lease = ref.keepAlive();
    autosave = AuthoredDraftAutosave(
      resource: resource,
      baseline: baseline,
      policy: policy,
      commit: commit,
      fetchCurrent: () async {
        await refresh();
        return ready;
      },
      reload: refresh,
      onSettled: () {
        if (autosave.detached && autosave.settled) {
          _autosaves.remove(autosave);
          autosave.close();
          lease.close();
        }
      },
    );
    _autosaves.add(autosave);
    return autosave;
  }

  void _rememberSnapshot(skir.AuthoringState snapshot) {
    final baseline = state.draft;
    if (baseline != null) {
      for (final autosave in _autosaves) {
        autosave.acceptBaseline(baseline);
      }
    }
  }

  Future<void> commitDraft(
    AuthoredDraft draft, {
    required String conflictMessage,
  }) async {
    final response = await commit(draft.prepare());
    switch (response) {
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult.committed,
      ):
        await refresh();
        return;
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult_conflictWrapper(),
      ):
        throw ApiException.conflict(conflictMessage);
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult_rejectedWrapper(),
      ):
        throw ApiException.badRequest("The Realm rejected this edit");
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult_catalogChangedWrapper(),
      ):
        throw ApiException.conflict("The editor catalog changed");
      default:
        throw ApiException.internalServerError();
    }
  }

  Future<void> deleteResource(
    skir.ResourceId resource, {
    String conflictMessage = "The resource changed before deletion",
  }) async {
    final baseline = state.draft;
    if (baseline == null) {
      throw ApiException.badRequest("Authoring is not ready");
    }
    final draft = baseline.fork()..delete(resource);
    final response = await commit(draft.prepare());
    switch (response) {
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult.committed,
      ):
        await refresh();
        return;
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult_conflictWrapper(),
      ):
        throw ApiException.conflict(conflictMessage);
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult_rejectedWrapper(),
      ):
        throw ApiException.badRequest("The Realm rejected this deletion");
      case skir.CommitPreparedEditResponse_resultWrapper(
        value: skir.CommitResult_catalogChangedWrapper(),
      ):
        throw ApiException.conflict("The editor catalog changed");
      default:
        throw ApiException.internalServerError();
    }
  }

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

  Future<skir.CommitTypeArgumentChangeResponse> commitTypeArguments(
    skir.TypeArgumentChangePreview preview,
  ) async {
    return ref
        .read(localWorkControllerProvider)
        .execute(_repository.prepareTypeCommit(preview));
  }

  Future<skir.PreparedCreation> prepareCreation(
    skir.InitializationRequest request,
  ) => NatsRealmEditorCatalogSource(ref).prepareCreation(
    RealmEditorCatalogRoute(organizationId: _organizationId, realmId: _realmId),
    request,
  );

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

@freezed
abstract class AuthoringSessionAccess with _$AuthoringSessionAccess {
  const factory AuthoringSessionAccess({
    required AuthoringSession notifier,
    required AuthoringSessionState state,
  }) = _AuthoringSessionAccess;
}
