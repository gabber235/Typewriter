import "package:typewriter_panel/typewriter_panel.dart";

final class LimitedSearchSource extends DelegatingSearchSource {
  LimitedSearchSource({required super.source, required this.maximum})
    : assert(maximum >= 0);

  final int maximum;

  @override
  void onSnapshot(SearchSourceSnapshot snapshot) {
    emit(snapshot.copyWith(nodes: _limit(snapshot.nodes, maximum)));
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
