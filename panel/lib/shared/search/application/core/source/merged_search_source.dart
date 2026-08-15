import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

final class MergedSearchSource implements SearchSource {
  MergedSearchSource({required this.sources}) : assert(sources.isNotEmpty) {
    _latestSnapshots = List.filled(sources.length, null);
    _latestSelectors = List.filled(sources.length, null);
  }

  final List<SearchSource> sources;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  final _selectors = StreamController<List<QuerySelectorDefinition>>.broadcast(
    sync: true,
  );
  late final List<SearchSourceSnapshot?> _latestSnapshots;
  late final List<List<QuerySelectorDefinition>?> _latestSelectors;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<String, SearchSource> _resultSources = {};
  bool _initialized = false;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => _selectors.stream;

  @override
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    for (var index = 0; index < sources.length; index++) {
      final source = sources[index];
      _subscriptions.add(
        source.snapshots.listen((snapshot) => _onSnapshot(index, snapshot)),
      );
      _subscriptions.add(
        source.selectors.listen((selectors) => _onSelectors(index, selectors)),
      );
      source.initialize();
    }
  }

  @override
  void search(SearchQueryContext context) {
    _latestSnapshots.fillRange(0, _latestSnapshots.length, null);
    _resultSources.clear();
    for (final source in sources) {
      source.search(context);
    }
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    final source = _resultSources[request.resultId];
    if (source == null) {
      return Future.value(
        const SearchPreviewRequestResult.error(
          message: "Preview source is unavailable",
        ),
      );
    }
    return source.preview(request);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    for (final source in sources) {
      source.dispose();
    }
    unawaited(_snapshots.close());
    unawaited(_selectors.close());
  }

  void _onSnapshot(int index, SearchSourceSnapshot snapshot) {
    if (_disposed) return;
    _latestSnapshots[index] = snapshot;
    _snapshots.add(_mergeSnapshots());
  }

  SearchSourceSnapshot _mergeSnapshots() {
    final available = _latestSnapshots.whereType<SearchSourceSnapshot>();
    final nodes = <SearchNode>[];
    final actions = <Type, SearchAction>{};
    final guidance = <SearchGuidance>[];
    final guidanceIds = <String>{};
    final errors = <SearchErrorSummary>[];
    final errorIds = <String>{};
    _resultSources.clear();

    for (var index = 0; index < _latestSnapshots.length; index++) {
      final snapshot = _latestSnapshots[index];
      if (snapshot == null) continue;
      nodes.addAll(snapshot.nodes);
      for (final entry in snapshot.actions.entries) {
        actions.putIfAbsent(entry.key, () => entry.value);
      }
      guidance.addAll(
        snapshot.guidance.where((item) {
          return guidanceIds.add(item.id);
        }),
      );
      errors.addAll(
        snapshot.errorSummaries.where((item) {
          return errorIds.add(item.id);
        }),
      );
      for (final result
          in snapshot.nodes.walk().whereType<SearchResultNode>()) {
        _resultSources.putIfAbsent(result.result.id, () => sources[index]);
      }
    }

    final statuses = available.map((snapshot) => snapshot.status).toList();
    if (statuses.isEmpty || statuses.every((status) => status == .idle)) {
      return SearchSourceSnapshot.idle(
        nodes: nodes,
        actions: actions,
        guidance: guidance,
      );
    }

    final allChildrenReported = statuses.length == sources.length;
    final allErrors =
        allChildrenReported && statuses.every((status) => status == .error);
    if (allErrors && nodes.isEmpty) {
      return SearchSourceSnapshot.error(
        nodes: nodes,
        actions: actions,
        guidance: guidance,
        errorSummaries: errors,
      );
    }

    final isLoading =
        !allChildrenReported ||
        statuses.any((status) {
          return status == .loading;
        });
    if (isLoading) {
      return SearchSourceSnapshot.loading(
        nodes: nodes,
        actions: actions,
        guidance: guidance,
        errorSummaries: errors,
      );
    }

    if (statuses.any((status) => status == .ready)) {
      return SearchSourceSnapshot.ready(
        nodes: nodes,
        actions: actions,
        guidance: guidance,
        errorSummaries: errors,
      );
    }

    return SearchSourceSnapshot(
      status: SearchSourceStatus.idle,
      nodes: nodes,
      actions: actions,
      guidance: guidance,
      errorSummaries: errors,
    );
  }

  void _onSelectors(int index, List<QuerySelectorDefinition> selectors) {
    if (_disposed) return;
    _latestSelectors[index] = selectors;
    var merged = <QuerySelectorDefinition>[];
    for (final current
        in _latestSelectors.whereType<List<QuerySelectorDefinition>>()) {
      merged = merged.merge(current);
    }
    _selectors.add(merged);
  }
}

extension MergedSearchSourcesX on Iterable<SearchSource> {
  SearchSource merged() {
    return MergedSearchSource(sources: toList(growable: false));
  }
}
