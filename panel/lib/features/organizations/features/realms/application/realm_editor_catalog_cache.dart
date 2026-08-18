import "dart:async";

import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog_cache.freezed.dart";

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
  var _requested = RealmEditorCatalogRequest();

  Stream<RealmEditorCatalogState> get states => Stream.multi((controller) {
    controller.add(_state);
    final subscription = _states.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  }, isBroadcast: true);

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

  void request(RealmEditorCatalogRequest request) {
    if (_disposed) return;
    final merged = _requested.merge(request);
    final changed =
        merged.types.length != _requested.types.length ||
        merged.presentations.length != _requested.presentations.length ||
        merged.conversions.length != _requested.conversions.length ||
        merged.realmActions.length != _requested.realmActions.length ||
        merged.subtypeQueries.length != _requested.subtypeQueries.length;
    _requested = merged;
    if (_started && changed) {
      unawaited(_refresh(expectedGeneration: _state.snapshot?.generation));
    }
  }

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
        _emit(const RealmEditorCatalogLoading());
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
    _emit(RealmEditorCatalogLoading(_state.snapshot));
    final first = await _fetch(expectedGeneration);
    if (!_isCurrent(epoch)) return;
    if (first case RealmEditorCatalogGenerationMismatch(
      :final currentGeneration,
    )) {
      _emit(const RealmEditorCatalogLoading());
      final retry = await _fetch(currentGeneration);
      if (!_isCurrent(epoch)) return;
      _applyFetchResult(retry);
      return;
    }
    _applyFetchResult(first);
  }

  Future<RealmEditorCatalogFetchResult> _fetch(
    CatalogGeneration? generation,
  ) async {
    try {
      return await source.fetch(
        route,
        _requested,
        expectedGeneration: generation,
      );
    } on Object catch (error) {
      return RealmEditorCatalogFetchUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Realm editor catalog fetch failed: $error",
        ),
      ]);
    }
  }

  void _applyFetchResult(RealmEditorCatalogFetchResult result) {
    switch (result) {
      case RealmEditorCatalogFetched(:final snapshot):
        final previous = _state.snapshot;
        _emit(
          RealmEditorCatalogReady(
            previous == null ? snapshot : previous.merge(snapshot),
          ),
        );
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
}
