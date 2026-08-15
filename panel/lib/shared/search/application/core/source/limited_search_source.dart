import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

final class LimitedSearchSource implements SearchSource {
  LimitedSearchSource({required this.source, required this.maximum})
    : assert(maximum >= 0) {
    _snapshotSubscription = source.snapshots.listen(_onSnapshot);
  }

  final SearchSource source;
  final int maximum;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  StreamSubscription<SearchSourceSnapshot>? _snapshotSubscription;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<List<QuerySelectorDefinition>> get selectors => source.selectors;

  @override
  void initialize() => source.initialize();

  @override
  void search(SearchQueryContext context) => source.search(context);

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
    unawaited(_snapshots.close());
    source.dispose();
  }

  void _onSnapshot(SearchSourceSnapshot snapshot) {
    _snapshots.add(snapshot.copyWith(nodes: _limit(snapshot.nodes, maximum)));
  }

  List<SearchNode> _limit(List<SearchNode> nodes, int available) {
    if (available == 0) return const [];

    final limited = <SearchNode>[];
    var remaining = available;
    for (final node in nodes) {
      if (remaining == 0) break;

      switch (node) {
        case SearchResultNode():
          limited.add(node);
          remaining--;
        case SearchSectionNode():
          final children = _limit(node.children, remaining);
          if (children.isEmpty) continue;
          limited.add(node.copyWith(children: children));
          remaining -= children.walk().whereType<SearchResultNode>().length;
      }
    }
    return limited;
  }
}

extension LimitedSearchSourceX on SearchSource {
  SearchSource limited(int maximum) {
    return LimitedSearchSource(source: this, maximum: maximum);
  }
}
