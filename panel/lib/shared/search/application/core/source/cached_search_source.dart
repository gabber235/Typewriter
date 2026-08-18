import "package:typewriter_panel/typewriter_panel.dart";

final class CachedSearchSource extends DelegatingSearchSource {
  CachedSearchSource({
    required super.source,
    this.capacity = 100,
    this.retainStaleResults = true,
  }) : assert(capacity > 0);

  final int capacity;
  final bool retainStaleResults;

  SearchSourceSnapshot? _cachedReadySnapshot;
  SearchQueryContext? _activeContext;
  final Map<SearchQueryContext, SearchSourceSnapshot> _queryCache = {};
  final Map<String, SearchPreviewRequestResultData> _previewCache = {};

  @override
  void search(SearchQueryContext context) {
    _activeContext = context;
    final cached = _queryCache.remove(context);
    if (cached != null) {
      _queryCache[context] = cached;
      _cachedReadySnapshot = cached;
      emit(cached);
    } else {
      _cachedReadySnapshot = null;
    }
    source.search(context);
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async {
    final cachedResult = _previewCache[request.resultId];
    if (cachedResult != null) return cachedResult;

    final result = await source.preview(request);
    if (result case SearchPreviewRequestResultData()) {
      _previewCache[request.resultId] = result;
    }
    return result;
  }

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) {
    if (snapshot.status == SearchSourceStatus.ready) {
      _cachedReadySnapshot = snapshot;
      _rememberActiveQuery(snapshot);
      emit(snapshot);
      return;
    }

    final cachedSnapshot = _cachedReadySnapshot;
    if (cachedSnapshot == null || !retainStaleResults) {
      emit(snapshot);
      return;
    }

    switch (snapshot.status) {
      case SearchSourceStatus.loading || SearchSourceStatus.error:
        emit(
          snapshot.copyWith(
            nodes: _markNodesStale(cachedSnapshot.nodes),
            actions: cachedSnapshot.actions,
          ),
        );
      case SearchSourceStatus.idle:
        emit(snapshot);
      case SearchSourceStatus.ready:
        throw StateError("Ready snapshot handled before switch");
    }
  }

  void _rememberActiveQuery(SearchSourceSnapshot snapshot) {
    final context = _activeContext;
    if (context == null) return;
    _queryCache.remove(context);
    _queryCache[context] = snapshot;
    if (_queryCache.length <= capacity) return;
    _queryCache.remove(_queryCache.keys.first);
  }

  List<SearchNode> _markNodesStale(List<SearchNode> nodes) {
    return nodes.map(_markNodeStale).toList();
  }

  SearchNode _markNodeStale(SearchNode node) {
    return switch (node) {
      SearchResultNode(:final result) => SearchNode.result(
        result: result.copyWith(isStale: true),
      ),
      SearchSectionNode(
        :final id,
        :final title,
        :final subtitle,
        :final children,
      ) =>
        SearchNode.section(
          id: id,
          title: title,
          subtitle: subtitle,
          children: _markNodesStale(children),
        ),
    };
  }
}

extension CachedSearchSourceX on SearchSource {
  SearchSource cached({int capacity = 100, bool retainStaleResults = true}) {
    return CachedSearchSource(
      source: this,
      capacity: capacity,
      retainStaleResults: retainStaleResults,
    );
  }
}
