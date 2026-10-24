import "package:typewriter_panel/typewriter_panel.dart";

/// Removes duplicate result keys from a snapshot tree.
///
/// The first depth first occurrence wins. Empty sections are removed after
/// their children have been filtered.
final class DistinctSearchSource extends DelegatingSearchSource {
  DistinctSearchSource({required super.source, this.resultKey});

  final Object Function(SearchResult result)? resultKey;

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) {
    emit(snapshot.copyWith(nodes: _distinct(snapshot.nodes, <Object>{})));
  }

  List<SearchNode> _distinct(List<SearchNode> nodes, Set<Object> seen) {
    final distinct = <SearchNode>[];
    for (final node in nodes) {
      switch (node) {
        case SearchResultNode(:final result):
          if (seen.add(resultKey?.call(result) ?? result.id)) {
            distinct.add(node);
          }
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

/// Adds first occurrence filtering to a source.
extension DistinctSearchSourceX on SearchSource {
  SearchSource distinct({Object Function(SearchResult result)? by}) {
    return DistinctSearchSource(source: this, resultKey: by);
  }
}
