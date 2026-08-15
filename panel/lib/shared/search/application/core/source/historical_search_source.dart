import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class SearchHistoryStorage {
  Future<List<SearchResult>> loadValidResults({
    required String key,
    required int capacity,
  });

  Future<void> replaceResults({
    required String key,
    required List<SearchResult> results,
  });
}

final class HistoricalSearchSource implements SearchSource {
  HistoricalSearchSource({
    required this.source,
    required this.key,
    required this.label,
    required this.capacity,
    required this.storage,
    required this.committedSelections,
  }) : assert(key.isNotEmpty),
       assert(label.isNotEmpty),
       assert(capacity > 0) {
    _snapshotSubscription = source.snapshots.listen(_onSnapshot);
    _selectionSubscription = committedSelections.listen(_onSelection);
  }

  final SearchSource source;
  final String key;
  final String label;
  final int capacity;
  final SearchHistoryStorage storage;
  final Stream<SearchResult> committedSelections;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  StreamSubscription<SearchSourceSnapshot>? _snapshotSubscription;
  StreamSubscription<SearchResult>? _selectionSubscription;
  final Map<String, SearchResult> _knownResults = {};
  final List<SearchResult> _pendingSelections = [];
  List<SearchResult> _recent = const [];
  SearchQueryContext _activeContext = _emptySearchQuery;
  SearchSourceSnapshot? _lastChildSnapshot;
  Future<void> _writeChain = Future.value();
  bool _initialized = false;
  bool _loaded = false;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => source.selectors;

  @override
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    unawaited(_load());
    source.initialize();
  }

  @override
  void search(SearchQueryContext context) {
    _activeContext = context;
    if (_isEmptyQuery && _loaded) {
      _emitHistory(_lastChildSnapshot ?? SearchSourceSnapshot.idle());
    }
    source.search(context);
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    return source.preview(request);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_snapshotSubscription?.cancel());
    _snapshotSubscription = null;
    unawaited(_selectionSubscription?.cancel());
    _selectionSubscription = null;
    unawaited(_snapshots.close());
    source.dispose();
  }

  Future<void> _load() async {
    List<SearchResult> loaded;
    try {
      loaded = await storage.loadValidResults(key: key, capacity: capacity);
    } on Object {
      loaded = const [];
    }
    if (_disposed) return;

    _recent = _deduplicate(loaded);
    _loaded = true;
    for (final result in _pendingSelections) {
      _remember(result);
    }
    _pendingSelections.clear();
    if (_isEmptyQuery) {
      _emitHistory(_lastChildSnapshot ?? SearchSourceSnapshot.idle());
    }
  }

  void _onSnapshot(SearchSourceSnapshot snapshot) {
    if (_disposed) return;
    _lastChildSnapshot = snapshot;
    _knownResults
      ..clear()
      ..addEntries(
        snapshot.nodes.walk().whereType<SearchResultNode>().map(
          (node) => MapEntry(node.result.id, node.result),
        ),
      );

    if (!_isEmptyQuery || !_loaded) {
      _snapshots.add(snapshot);
      return;
    }
    _emitHistory(snapshot);
  }

  void _onSelection(SearchResult selection) {
    if (_disposed) return;
    final result = _knownResults[selection.id] ?? _findRecent(selection.id);
    if (result == null) return;
    if (!_loaded) {
      _pendingSelections.add(result);
      return;
    }
    _remember(result);
    if (_isEmptyQuery) {
      _emitHistory(_lastChildSnapshot ?? SearchSourceSnapshot.idle());
    }
  }

  void _remember(SearchResult result) {
    _recent = [
      result,
      ..._recent.where((item) => item.id != result.id),
    ].take(capacity).toList(growable: false);
    final stored = _recent;
    _writeChain = _writeChain
        .then((_) => storage.replaceResults(key: key, results: stored))
        .onError((_, _) {});
  }

  List<SearchResult> _deduplicate(List<SearchResult> results) {
    final seen = <String>{};
    return results
        .where((result) => seen.add(result.id))
        .take(capacity)
        .toList(growable: false);
  }

  SearchResult? _findRecent(String id) {
    for (final result in _recent) {
      if (result.id == id) return result;
    }
    return null;
  }

  void _emitHistory(SearchSourceSnapshot snapshot) {
    if (_disposed) return;
    if (_recent.isEmpty) {
      _snapshots.add(snapshot);
      return;
    }

    final nodes = [
      SearchNode.section(
        id: "history:$key",
        title: label,
        children: _recent
            .map((result) => SearchNode.result(result: result))
            .toList(growable: false),
      ),
      ...snapshot.nodes,
    ];
    final status = snapshot.status == SearchSourceStatus.idle
        ? SearchSourceStatus.ready
        : snapshot.status;
    _snapshots.add(snapshot.copyWith(status: status, nodes: nodes));
  }

  bool get _isEmptyQuery => _activeContext.normalizedQuery.isEmpty;
}

const _emptySearchQuery = SearchQueryContext(
  normalizedQuery: "",
  selectors: [],
);

extension HistoricalSearchSourceX on SearchSource {
  SearchSource withHistory({
    required String key,
    required String label,
    required int capacity,
    required SearchHistoryStorage storage,
    required Stream<SearchResult> committedSelections,
  }) {
    return HistoricalSearchSource(
      source: this,
      key: key,
      label: label,
      capacity: capacity,
      storage: storage,
      committedSelections: committedSelections,
    );
  }
}
