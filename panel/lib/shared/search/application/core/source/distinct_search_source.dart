import "dart:async";

import "package:typewriter_panel/typewriter_panel.dart";

final class DistinctSearchSource implements SearchSource {
  DistinctSearchSource({required this.source}) {
    _snapshotSubscription = source.snapshots.listen(_onSnapshot);
  }

  final SearchSource source;

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
    _snapshots.add(
      snapshot.copyWith(nodes: _distinct(snapshot.nodes, <String>{})),
    );
  }

  List<SearchNode> _distinct(List<SearchNode> nodes, Set<String> seen) {
    final distinct = <SearchNode>[];
    for (final node in nodes) {
      switch (node) {
        case SearchResultNode(:final result):
          if (seen.add(result.id)) distinct.add(node);
        case SearchSectionNode():
          final children = _distinct(node.children, seen);
          if (children.isNotEmpty) {
            distinct.add(node.copyWith(children: children));
          }
      }
    }
    return distinct;
  }
}

extension DistinctSearchSourceX on SearchSource {
  SearchSource distinct() {
    return DistinctSearchSource(source: this);
  }
}
