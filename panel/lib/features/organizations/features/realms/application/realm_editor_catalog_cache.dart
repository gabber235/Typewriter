import "dart:async";

import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog_cache.freezed.dart";

/// Observable lifecycle of the cached realm editor catalog.
///
/// Loading and unavailable states retain the last snapshot when one exists.
/// Consumers can therefore keep rendering known definitions while showing the
/// current recovery state.
@freezed
sealed class RealmEditorCatalogState with _$RealmEditorCatalogState {
  const RealmEditorCatalogState._();

  const factory RealmEditorCatalogState.loading([
    RealmEditorCatalogSnapshot? previous,
  ]) = RealmEditorCatalogLoading;
  const factory RealmEditorCatalogState.ready(
    RealmEditorCatalogSnapshot value,
  ) = RealmEditorCatalogReady;
  const factory RealmEditorCatalogState.unavailable(
    List<TypeDiagnostic> diagnostics, {
    RealmEditorCatalogSnapshot? previous,
  }) = RealmEditorCatalogUnavailable;

  RealmEditorCatalogSnapshot? get snapshot => switch (this) {
    RealmEditorCatalogLoading(:final previous) => previous,
    RealmEditorCatalogReady(:final value) => value,
    RealmEditorCatalogUnavailable(:final previous) => previous,
  };
}

/// Keeps one catalog request in the cache's merged demand until [close].
///
/// The provider that acquired the lease owns its release. Releasing is
/// idempotent, so disposal paths can safely call it more than once.
final class RealmEditorCatalogLease {
  RealmEditorCatalogLease._(this._close);

  final void Function() _close;
  var _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    _close();
  }
}

typedef RealmEditorCatalogPinState = ({
  RealmEditorCatalogSnapshot snapshot,
  RealmEditorCatalogSnapshot? pending,
  bool paused,
  List<TypeDiagnostic> diagnostics,
});

/// Pins one editor to a coherent catalog until compatibility is established.
final class RealmEditorCatalogPin extends ChangeNotifier {
  RealmEditorCatalogPin._(
    this._lease,
    this._request,
    RealmEditorCatalogSnapshot snapshot,
    Stream<RealmEditorCatalogState> states,
  ) : _state = (
        snapshot: snapshot,
        pending: null,
        paused: false,
        diagnostics: const [],
      ) {
    _subscription = states.listen(_accept);
  }

  final RealmEditorCatalogLease _lease;
  final RealmEditorCatalogRequest _request;
  late final StreamSubscription<RealmEditorCatalogState> _subscription;
  RealmEditorCatalogPinState _state;

  RealmEditorCatalogPinState get state => _state;

  Future<bool> reconcile(
    FutureOr<bool> Function(
      RealmEditorCatalogSnapshot pinned,
      RealmEditorCatalogSnapshot candidate,
    )
    validate,
  ) async {
    final pending = _state.pending;
    if (pending == null) return false;
    if (!await validate(_state.snapshot, pending)) return false;
    _state = (
      snapshot: pending,
      pending: null,
      paused: false,
      diagnostics: const [],
    );
    notifyListeners();
    return true;
  }

  void _accept(RealmEditorCatalogState event) {
    switch (event) {
      case RealmEditorCatalogReady(:final value):
        if (value.generation == _state.snapshot.generation) return;
        if (editorCatalogContractsCompatible(
          _state.snapshot,
          value,
          _request,
        )) {
          _state = (
            snapshot: value,
            pending: null,
            paused: false,
            diagnostics: const [],
          );
        } else {
          _state = (
            snapshot: _state.snapshot,
            pending: value,
            paused: true,
            diagnostics: const [
              TypeDiagnostic(
                code: TypeDiagnosticCode.invalidRevision,
                message: "Editor catalog changed incompatibly",
                pathPresent: false,
              ),
            ],
          );
        }
        notifyListeners();
      case RealmEditorCatalogUnavailable(:final diagnostics):
        _state = (
          snapshot: _state.snapshot,
          pending: _state.pending,
          paused: true,
          diagnostics: diagnostics,
        );
        notifyListeners();
      case RealmEditorCatalogLoading():
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _lease.close();
    super.dispose();
  }
}

/// Owns one realm catalog snapshot, its invalidation watch, and consumer leases.
///
/// Each lease contributes requested types, presentations, or subtype queries.
/// The cache merges those requests into fetches, rejects stale responses after
/// invalidation or disposal, retries generation mismatches, and publishes a
/// previous snapshot with diagnostics when recovery fails. It is created by
/// the online realm provider and must be disposed with that provider.
final class RealmEditorCatalogCache {
  RealmEditorCatalogCache({required this.source, required this.route});

  final RealmEditorCatalogSource source;
  final RealmEditorCatalogRoute route;
  final StreamController<RealmEditorCatalogState> _states =
      StreamController.broadcast();

  StreamSubscription<RealmEditorCatalogWatchEvent>? _watchSubscription;
  RealmEditorCatalogState _state = const RealmEditorCatalogLoading();
  var _epoch = 0;
  var _started = false;
  var _disposed = false;
  var _nextLeaseId = 0;
  final Map<int, RealmEditorCatalogRequest> _requests = {};
  final List<_RetainedCatalogSnapshot> _retained = [];

  RealmEditorCatalogRequest get _requested => _requests.values.fold(
    RealmEditorCatalogRequest(),
    (combined, request) => combined.merge(request),
  );

  Stream<RealmEditorCatalogState> get states => Stream.multi((controller) {
    controller.add(_state);
    final subscription = _states.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  }, isBroadcast: true);

  /// Starts the invalidation watch and schedules the initial fetch once.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _watchSubscription = source
        .watchInvalidations(route)
        .listen(
          _handleWatchEvent,
          onError: _handleWatchError,
          onDone: _handleWatchDone,
        );
    unawaited(_refresh());
  }

  /// Retains [request] in the merged fetch scope until the returned lease closes.
  ///
  /// A new request triggers a refresh only after the cache has started. The
  /// request is not removed until its consumer releases the lease.
  RealmEditorCatalogLease acquire(RealmEditorCatalogRequest request) {
    if (_disposed) return RealmEditorCatalogLease._(() {});
    final previous = _requested;
    final id = _nextLeaseId++;
    _requests[id] = request;
    if (_started && previous != _requested) {
      unawaited(_refresh(expectedGeneration: _state.snapshot?.generation));
    }
    return RealmEditorCatalogLease._(() => _requests.remove(id));
  }

  /// Creates an editor specific pin from the currently coherent snapshot.
  RealmEditorCatalogPin pin(RealmEditorCatalogRequest request) {
    final snapshot = _state.snapshot;
    if (snapshot == null) {
      throw StateError("A catalog snapshot is required before pinning");
    }
    return RealmEditorCatalogPin._(acquire(request), request, snapshot, states);
  }

  /// Returns the requested projection from exactly [generation].
  ///
  /// Retained snapshots are reused only when their recorded request covers the
  /// complete projection. A cache miss performs an exact generation fetch and
  /// returns a mismatch instead of decoding against the current generation.
  Future<RealmEditorCatalogFetchResult> fetchExact(
    CatalogGeneration generation,
    RealmEditorCatalogRequest request,
  ) async {
    if (_disposed) {
      return RealmEditorCatalogFetchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm editor catalog cache is disposed",
        ),
      ]);
    }
    for (final retained in _retained.reversed) {
      if (retained.snapshot.generation == generation &&
          retained.request.covers(request)) {
        return RealmEditorCatalogFetched(retained.snapshot);
      }
    }
    final result = await _fetch(generation, request);
    if (_disposed) {
      return RealmEditorCatalogFetchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm editor catalog cache was disposed during the fetch",
        ),
      ]);
    }
    if (result case RealmEditorCatalogFetched(:final snapshot)) {
      if (snapshot.generation != generation) {
        return RealmEditorCatalogGenerationMismatch(snapshot.generation);
      }
      _retain(request, snapshot);
    }
    return result;
  }

  /// Returns the complete currently requested projection from exactly [generation].
  Future<RealmEditorCatalogFetchResult> fetchExactCurrent(
    CatalogGeneration generation,
  ) => fetchExact(generation, _requested);

  /// Reconciles current demand against the latest known catalog generation.
  Future<void> refresh() =>
      _refresh(expectedGeneration: _state.snapshot?.generation);

  /// Stops watches and prevents pending fetches from publishing state.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _epoch++;
    await _watchSubscription?.cancel();
    await _states.close();
  }

  void _handleWatchEvent(RealmEditorCatalogWatchEvent event) {
    switch (event) {
      case RealmEditorCatalogInvalidated(:final generation):
        _emit(RealmEditorCatalogLoading(_state.snapshot));
        unawaited(_refresh(expectedGeneration: generation));
      case RealmEditorCatalogWatchUnavailable(:final diagnostics):
        _epoch++;
        _emitUnavailable(diagnostics);
    }
  }

  void _handleWatchError(Object error, StackTrace stackTrace) {
    _epoch++;
    _emitUnavailable([
      realmEditorCatalogUnavailableDiagnostic(
        "Realm editor catalog invalidation watch failed: $error",
      ),
    ]);
  }

  void _handleWatchDone() {
    _epoch++;
    _emitUnavailable([
      realmEditorCatalogUnavailableDiagnostic(
        "Realm editor catalog invalidation watch closed",
      ),
    ]);
  }

  Future<void> _refresh({CatalogGeneration? expectedGeneration}) async {
    final epoch = ++_epoch;
    final request = _requested;
    _emit(RealmEditorCatalogLoading(_state.snapshot));
    final first = await _fetch(expectedGeneration, request);
    if (!_isCurrent(epoch)) return;
    if (first case RealmEditorCatalogGenerationMismatch(
      :final currentGeneration,
    )) {
      _emit(RealmEditorCatalogLoading(_state.snapshot));
      final retry = await _fetch(currentGeneration, request);
      if (!_isCurrent(epoch)) return;
      _applyFetchResult(retry, request);
      return;
    }
    _applyFetchResult(first, request);
  }

  Future<RealmEditorCatalogFetchResult> _fetch(
    CatalogGeneration? generation,
    RealmEditorCatalogRequest request,
  ) async {
    try {
      return await source.fetch(route, request, expectedGeneration: generation);
    } on Object catch (error) {
      return RealmEditorCatalogFetchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm editor catalog fetch failed: $error",
        ),
      ]);
    }
  }

  void _applyFetchResult(
    RealmEditorCatalogFetchResult result,
    RealmEditorCatalogRequest request,
  ) {
    switch (result) {
      case RealmEditorCatalogFetched(:final snapshot):
        _retain(request, snapshot);
        _emit(RealmEditorCatalogReady(snapshot));
      case RealmEditorCatalogFetchUnavailable(:final diagnostics):
        _emitUnavailable(diagnostics);
      case RealmEditorCatalogGenerationMismatch(:final currentGeneration):
        _emitUnavailable([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidRevision,
            message:
                "Realm editor catalog generation remained inconsistent at $currentGeneration",
            pathPresent: false,
          ),
        ]);
    }
  }

  void _emitUnavailable(Iterable<TypeDiagnostic> diagnostics) {
    _emit(
      RealmEditorCatalogState.unavailable(
        diagnostics.toList(growable: false),
        previous: _state.snapshot,
      ),
    );
  }

  void _emit(RealmEditorCatalogState state) {
    if (_disposed) return;
    _state = state;
    _states.add(state);
  }

  bool _isCurrent(int epoch) => !_disposed && epoch == _epoch;

  void _retain(
    RealmEditorCatalogRequest request,
    RealmEditorCatalogSnapshot snapshot,
  ) {
    _retained.removeWhere(
      (item) =>
          item.snapshot.generation == snapshot.generation &&
          request.covers(item.request),
    );
    _retained.add((request: request, snapshot: snapshot));
  }
}

typedef _RetainedCatalogSnapshot = ({
  RealmEditorCatalogRequest request,
  RealmEditorCatalogSnapshot snapshot,
});

bool editorCatalogContractsCompatible(
  RealmEditorCatalogSnapshot before,
  RealmEditorCatalogSnapshot after,
  RealmEditorCatalogRequest request,
) {
  final beforeTypes = TypeRegistry(before.catalog);
  final afterTypes = TypeRegistry(after.catalog);
  final presentationIds = {...request.presentations};
  for (final type in request.types) {
    final beforeResolved = beforeTypes.resolveExact(type).valueOrNull;
    final afterResolved = afterTypes.resolveExact(type).valueOrNull;
    if (beforeResolved == null || beforeResolved != afterResolved) {
      return false;
    }
    final references = {type, ...beforeResolved.ancestors};
    for (final reference in references) {
      final beforeDefinition = beforeTypes.definition(reference);
      final afterDefinition = afterTypes.definition(reference);
      if (!listEquals(
        beforeDefinition?.fieldMergePolicies,
        afterDefinition?.fieldMergePolicies,
      )) {
        return false;
      }
    }
    for (final role in PresentationRole.values) {
      final beforeRole = beforeTypes
          .resolvePresentationRole(type, role)
          .valueOrNull;
      final afterRole = afterTypes
          .resolvePresentationRole(type, role)
          .valueOrNull;
      if (beforeRole != afterRole) return false;
      if (beforeRole != null) presentationIds.add(beforeRole);
    }
  }
  for (final presentation in presentationIds) {
    if (!_samePresentationContract(
      before.presentations[presentation],
      after.presentations[presentation],
    )) {
      return false;
    }
  }
  for (final query in request.subtypeQueries) {
    if (before.subtypeResults[query.id] != after.subtypeResults[query.id]) {
      return false;
    }
  }
  return true;
}

bool _samePresentationContract(
  PresentationDefinition? before,
  PresentationDefinition? after,
) {
  if (before == null || after == null) return before == after;
  return before.id == after.id &&
      before.primaryInput == after.primaryInput &&
      listEquals(before.inputs, after.inputs);
}
